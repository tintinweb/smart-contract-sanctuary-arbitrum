// SPDX-License-Identifier: none
pragma solidity 0.8.19;

import "Ownable.sol";


/**
 * Contract RoeRouter holds a list of whitelisted ROE lending pools and important parameters
 */
contract RoeRouter is Ownable {
  /// EVENTS
  event AddedPool(uint poolId, address lendingPoolAddressProvider);
  event SetDeprecated(uint poolId, bool status);
  event UpdatedTreasury(address treasury);
  event SetVaultAddress(address token0, address token1, address vault);

  /// ROE treasury
  address public treasury;

  /// List of pools
  RoePool[] public pools;
  
  /// List of GeVaults
  mapping(bytes32 => address) private _vaults;

  /// Lending pool structure
  struct RoePool {
    address lendingPoolAddressProvider;
    address token0;
    address token1;
    address ammRouter;
    bool isDeprecated;
  }
  
  
  /// @notice constructor
  constructor (address treasury_) {
    require(treasury_ != address(0x0), "Invalid address");
    treasury = treasury_;
  }
  
  
  /// @notice Return pool list length
  function getPoolsLength() public view returns (uint poolLength) {
    poolLength = pools.length;
  }
  
  
  /// @notice Deprecate a pool
  /// @param poolId pool ID
  /// @dev isDeprecated is a statement about the pool record, and does not imply anything about the pool itself
  function setDeprecated(uint poolId, bool status) public onlyOwner {
    pools[poolId].isDeprecated = status;
    emit SetDeprecated(poolId, status);
  }
  
  
  /// @notice Add a new pool parameters
  /// @param lendingPoolAddressProvider address of a ROE Aave-compatible lending pool address provider
  /// @param token0 address of the one token of the pair 
  /// @param token1 address of the second token of the pair
  /// @param ammRouter address of the AMMv2 such that the LP pair ammRouter.factory.getPair(token0, token1) is supported by the lending pool
  function addPool(
    address lendingPoolAddressProvider, 
    address token0, 
    address token1, 
    address ammRouter
  ) 
    public onlyOwner 
    returns (uint poolId)
  {
    require (
      lendingPoolAddressProvider != address(0x0) 
      && token0 != address(0x0) 
      && token1 != address(0x0) 
      && ammRouter != address(0x0), 
      "Invalid Address"
    );
    require(token0 < token1, "Invalid Order");
    pools.push(RoePool(lendingPoolAddressProvider, token0, token1, ammRouter, false));
    poolId = pools.length - 1;
    emit AddedPool(poolId, lendingPoolAddressProvider);
  }
  
  /// @notice Modify treaury address
  /// @param newTreasury New treasury address
  function setTreasury(address newTreasury) public onlyOwner {
    require(newTreasury != address(0x0), "Invalid address");
    treasury = newTreasury;
    emit UpdatedTreasury(newTreasury);
  }
  
  /// @notice Sets the vault address for a token pair
  /// @param token0 address of the one token of the pair 
  /// @param token1 address of the second token of the pair
  /// @param vault address of the vote
  /// @dev Each pair can only have one geVault at a time. 0x0 is a valid vault address, used to remove
  function setVault(address token0, address token1, address vault) public onlyOwner {
    require(token0 < token1, "Invalid Order");
    bytes32 addrHash = sha256(abi.encode(token0, token1));
    if (vault == address(0x0)) delete _vaults[addrHash];
    else _vaults[addrHash] = vault;
    emit SetVaultAddress(token0, token1, vault);
  }
  
  /// @notice Get the vault address for a token pair
  function getVault(address token0, address token1) public view returns (address vault) {
    bytes32 addrHash = sha256(abi.encode(token0, token1));
    vault = _vaults[addrHash]; 
  }
  
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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