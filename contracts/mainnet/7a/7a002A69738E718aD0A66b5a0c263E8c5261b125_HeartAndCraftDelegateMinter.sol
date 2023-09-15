/**
 *Submitted for verification at Arbiscan.io on 2023-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

/**
 * @dev Minimal interface to grab the MinterFilter from the core contract
 */
interface GenArtCoreV3 {
    function minterContract() external view returns (address);
}

/**
 * @dev Minimal interface to grab the Minter from the minter filter
 */
interface MinterFilter {
    function getMinterForProject(uint256 _projectId) external view returns (address);
}

/**
 * @dev Minimal interface to call artistMint on the minter
 */
interface Minter {
    function artistMint(address _to, uint256 _projectId) external payable returns (uint256 tokenId);
}

/**
 * @dev Contract module that allows a specific address to mint Heart+Craft tokens
 * for free as if it were the artist themself.
 */
contract HeartAndCraftDelegateMinter is Ownable {
    // The core contract is used to get the minter filter contract address
    GenArtCoreV3 public genArtCoreV3;
    // The minter filter contract is used to get the minter contract address
    MinterFilter public minterFilterContract;
    // The contract that actually holds the artistMint function
    Minter public minterContract;

    // The ProjectID for Heart+Craft
    uint256 public immutable projectId = 100;

    // The allowed number of mints
    uint256 public allowance = 100;
    // The address that's allowed to call the `artistMint` function
    address public allowedMinter;
    // The addresses that are allowed to update the allowance
    mapping(address => bool) public allowedAllowanceUpdaters;

    /**
     * @dev Contract constructor
     * @param _genArtCoreV3Address The address of the core contract
     * @param _mintingAddress The address that's allowed to call the `artistMint` function
     */
    constructor(address _genArtCoreV3Address, address _mintingAddress) Ownable() {
        _setContracts(_genArtCoreV3Address);
        allowedMinter = _mintingAddress;
    }

    /**
     * @dev Throws if called by any account other than the allowed minter.
     */
    function _onlyAllowedMinter(address _msgSender) internal view {
        require(_msgSender == allowedMinter, "HeartAndCraftDelegateMinter: Address not allowed to mint");
    }

    function _onlyAllowanceUpdater(address _msgSender) internal view {
        require(
            _msgSender == owner() || allowedAllowanceUpdaters[_msgSender],
            "HeartAndCraftDelegateMinter: Address not allowed to update allowance"
        );
    }

    /**
     * @dev Sets the core contract, which then derives the other contracts
     */
    function _setContracts(address _genArtCoreV3Address) internal {
        genArtCoreV3 = GenArtCoreV3(_genArtCoreV3Address);
        minterFilterContract = MinterFilter(genArtCoreV3.minterContract());
        minterContract = Minter(minterFilterContract.getMinterForProject(100));
    }

    /**
     * @dev Refreshes the minter contract address in the event the project has been upgraded
     * @notice This function can be called by anyone, as it is on approved contracts that are
     * already set by the owner
     */
    function refreshMinterContract() external {
        _setContracts(address(genArtCoreV3));
    }

    /**
     * @dev Updates the core contract address
     * @notice This function can only be called by the owner
     */
    function updateCoreContract(address _genArtCoreV3Address) external onlyOwner {
        _setContracts(_genArtCoreV3Address);
    }

    /**
     * @dev Updates the allowed minter address
     * @notice This function can only be called by the owner
     */
    function updateAllowedMinter(address _allowedMinter) external onlyOwner {
        allowedMinter = _allowedMinter;
    }

    /**
     * @dev Updates the allowed minter address
     * @notice This function can only be called by the owner
     */
    function toggleAllowanceUpdater(address _address) external onlyOwner {
        allowedAllowanceUpdaters[_address] = !allowedAllowanceUpdaters[_address];
    }

    /**
     * @dev Updates the allowance
     * @notice This function can only be called by the allowed allowance updaters
     */
    function updateAllowance(uint256 _newAllowance) external {
        _onlyAllowanceUpdater(msg.sender);
        allowance = _newAllowance;
    }

    /**
     * @dev Calls the artistMint function on the minter contract
     * @notice This function can only be called by the allowed minter
     */
    function artistMint(address _to) external {
        _onlyAllowedMinter(msg.sender);
        require(allowance > 0, "HeartAndCraftDelegateMinter: No more mints allowed");
        minterContract.artistMint{value: 0}(_to, projectId);
        allowance--;
    }
}