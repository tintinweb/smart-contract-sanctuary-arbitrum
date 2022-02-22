/**
 *Submitted for verification at arbiscan.io on 2022-02-22
*/

// File: MetaStore_flat.sol


// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: contracts/MetaStore.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



/**

        ████████
      ██░░░░░░░░██
      ██░░░░░░░░██
    ██░░░\/░░\/░░░██    ░
    ██░░░/\░░/\░░░██    ░
    ██░░░░░░░░░░░░██   ░
      ██░░░  █████████░
        ████████

     eggstock & more
  @author goldendilemma
  
 */

struct PermissionMeta {
  bool checkIn;
}

struct ContractMeta {
  address addr;
  bool active;
  PermissionMeta permissions;
}

struct InventoryMeta {
  uint count;
  uint max;
  bool disabled;
}

struct CheckpointMeta {
  bool active;
  bytes32 passwordHash;
  uint checkInCount;
  bool isDependent;
  uint dependency;
}

struct CheckInMeta {
  uint8 choiceId;
  uint createdAt;
}

struct UserToken {
  uint contractId;
  uint tokenId;
}

contract MetaStore is Ownable {
  
  CheckpointMeta[] public checkpoints;
  ContractMeta[] public contracts;

  mapping (uint => mapping (uint => InventoryMeta)) public tokenInventory; // contractId => checkpointId => InventoryMeta
  mapping (uint => mapping (uint => mapping (uint => CheckInMeta))) public checkIns; // contractId => tokenId => checkpointId => TokenCheckIn
  mapping (uint => mapping (uint => uint[])) public checkInList; // contractId => tokenId => checkpointId[]
  mapping (uint => UserToken[]) public checkpointTokens; // checkpointId => UserToken[]

  event ContractAdd (uint contractId, ContractMeta contractMeta, uint timestamp);
  event ContractUpdate (uint contractId, ContractMeta contractMeta, uint timestamp);

  event CheckpointAdd (uint checkpointId, CheckpointMeta checkpoint, uint timestamp);
  event CheckpointUpdate (uint checkpointId, CheckpointMeta checkpoint, uint timestamp);
  event InventoryUpdate (uint checkpointId, uint contractId, uint max, bool disabled, uint timestamp);
  event BatchInventoryUpdate (uint checkpointId, uint[] contractIds, uint max, bool disabled, uint timestamp);

  event TokenCheckIn (uint checkpointId, UserToken token, uint choiceId, uint timestamp);

  modifier validToken (UserToken memory token) {
    require(_getContractMeta(token).active, 'UNAVAILABLE_CONTRACT');
    _;
  }

  modifier validCheckpoint (uint checkpointId) {
    require(_getCheckpointMeta(checkpointId).active, 'UNAVAILABLE_CHECKPOINT');
    _;
  }

  modifier validPassword (uint checkpointId, string memory password) {
    if (_passwordProtected(_getCheckpointMeta(checkpointId))) {
      bytes32 passwordHash = createHash(password);
      require(_getCheckpointMeta(checkpointId).passwordHash == passwordHash, 'INVALID_PASSWORD');
    }
    _;
  }

  modifier onlyTokenOwner (UserToken memory token) {
    require(_getContractAsERC721(token.contractId).ownerOf(token.tokenId) == _msgSender(), 'FORBIDDEN_OWNER');
    _;
  }

  modifier canCheckIn (UserToken memory token, uint checkpointId) {
    InventoryMeta memory inventory = _getCheckpointTokenInventory(token.contractId, checkpointId);
    require(!inventory.disabled, 'FORBIDDEN_TOKEN');
    if (inventory.max != 0 && !inventory.disabled) {
      require(inventory.count < inventory.max, 'OUT_OF_INVENTORY');
    }
    CheckpointMeta memory cm = _getCheckpointMeta(checkpointId);
    if (cm.isDependent) {
      require(_getCheckInMeta(token, cm.dependency).createdAt != 0, 'DEPENDENCY_FAILED');
    }
    _;
  }

  /** PUBLIC GETTERS */

  function getCheckInList (UserToken memory token) public view returns (uint[] memory) {
    return _getCheckInList(token);
  }

  function getCheckpointMeta (uint checkpointId) public view returns (CheckpointMeta memory) {
    return _getCheckpointMeta(checkpointId);
  }

  function getCheckpointTokenInventory (uint contractId, uint checkpointId) public view returns (InventoryMeta memory) {
    return _getCheckpointTokenInventory(contractId, checkpointId);
  }

  function getCheckInMeta (UserToken memory token, uint checkpointId) public view returns (CheckInMeta memory) {
    return _getCheckInMeta(token, checkpointId);
  }

  function createHash (string memory data) public pure returns (bytes32) {
    return keccak256(abi.encode(data));
  }

  function getContractCount () public view returns (uint) { return contracts.length; }
  function getCheckpointCount () public view returns (uint) { return checkpoints.length; }

  /** INTERNALS */

  function _getContractAsERC721 (uint contractId) internal view returns (IERC721) {
    return IERC721(contracts[contractId].addr);
  }

  function _getCheckpointTokenInventory (uint contractId, uint checkpointId) internal view returns (InventoryMeta storage) {
    return tokenInventory[contractId][checkpointId];
  }

  function _getCheckInMeta(UserToken memory token, uint checkpointId) internal view returns (CheckInMeta storage) {
    return checkIns[token.contractId][token.tokenId][checkpointId];
  }

  function _getCheckInList (UserToken memory token) internal view returns (uint[] storage) {
    return checkInList[token.contractId][token.tokenId];
  }

  function _getContractMeta (UserToken memory token) internal view returns (ContractMeta storage) {
    return contracts[token.contractId];
  }

  function _getCheckpointMeta (uint checkpointId) internal view returns (CheckpointMeta storage) {
    return checkpoints[checkpointId];
  }

  function _passwordProtected (CheckpointMeta memory checkpointMeta) internal pure returns (bool){
    return checkpointMeta.passwordHash != bytes32(0);
  }

  function _updateStats (UserToken memory token, uint checkpointId) internal {
    _getCheckInList(token).push(checkpointId);
    _getCheckpointMeta(checkpointId).checkInCount += 1;
    _getCheckpointTokenInventory(token.contractId, checkpointId).count += 1;
    checkpointTokens[checkpointId].push(token);
  }

  function _setInventory (uint checkpointId, uint contractId, uint max, bool disabled) internal {
    InventoryMeta storage tm = tokenInventory[contractId][checkpointId];
    tm.max = max;
    tm.disabled = disabled;
  }

  /** PUBLIC */

  function checkIn (UserToken memory token, uint checkpointId, uint8 choiceId, string memory password) 
    public 
    validToken(token)
    validCheckpoint(checkpointId)
    onlyTokenOwner(token)
    validPassword(checkpointId, password)
    canCheckIn(token, checkpointId)
  {
    require(_getContractMeta(token).permissions.checkIn, 'FORBIDDEN_PERMISSION');
    CheckInMeta storage ci = _getCheckInMeta(token, checkpointId);
    require(ci.createdAt == 0, 'CHECKIN_EXISTS');
    ci.createdAt = block.timestamp;
    ci.choiceId = choiceId;
    _updateStats(token, checkpointId);
    emit TokenCheckIn(checkpointId, token, choiceId, block.timestamp);
  }

  /** OWNER */

  function checkInForce (UserToken memory token, uint checkpointId, uint8 choiceId) public onlyOwner {
    CheckInMeta storage ci = _getCheckInMeta(token, checkpointId);
    require(ci.createdAt == 0, 'CHECKIN_EXISTS');
    ci.createdAt = block.timestamp;
    ci.choiceId = choiceId;
    _updateStats(token, checkpointId);
    emit TokenCheckIn(checkpointId, token, choiceId, block.timestamp);
  }

  function addCheckpoint (bool active) public onlyOwner returns (uint) {
    CheckpointMeta memory checkpoint = CheckpointMeta({
      active: active,
      checkInCount: 0,
      passwordHash: bytes32(0),
      dependency: 0,
      isDependent: false
    });
    checkpoints.push(checkpoint);
    uint newId = checkpoints.length - 1;
    emit CheckpointAdd(newId, checkpoint, block.timestamp);
    return newId;
  }

  function updateCheckpoint (uint checkpointId, bool active) public onlyOwner {
    CheckpointMeta storage checkpoint = checkpoints[checkpointId];
    checkpoint.active = active;
    emit CheckpointUpdate(checkpointId, checkpoint, block.timestamp);
  }

  function setPasswordCheckpoint (uint checkpointId, bytes32 passwordHash) public onlyOwner {
    CheckpointMeta storage checkpoint = _getCheckpointMeta(checkpointId);
    checkpoint.passwordHash = passwordHash;
  }

  function setDependencyCheckpoint (uint checkpointId, uint dependentCheckpointId) public onlyOwner {
    CheckpointMeta storage checkpoint = _getCheckpointMeta(checkpointId);
    checkpoint.isDependent = true;
    checkpoint.dependency = dependentCheckpointId;
  }

  function setInventory (uint checkpointId, uint contractId, uint max, bool disabled) public onlyOwner {
    _setInventory(checkpointId, contractId, max, disabled);
    emit InventoryUpdate(checkpointId, contractId, max, disabled, block.timestamp);
  }

  function batchSetInventory (uint checkpointId, uint[] memory contractIds, uint max, bool disabled) public onlyOwner {
    for (uint i = 0; i < contractIds.length; i++) {
      _setInventory(checkpointId, contractIds[i], max, disabled);
    }
    emit BatchInventoryUpdate(checkpointId, contractIds, max, disabled, block.timestamp);
  }

  function addContract (address addr, bool active, PermissionMeta memory permissions) public onlyOwner returns (uint) {
    ContractMeta memory contractMeta = ContractMeta({
      addr: addr,
      active: active,
      permissions: permissions
    });
    contracts.push(contractMeta);
    uint newId = contracts.length - 1;
    emit ContractAdd(newId, contractMeta, block.timestamp);
    return newId;
  }

  function updateContract (uint contractId, bool active, PermissionMeta memory permissions) public onlyOwner {
    ContractMeta storage contractMeta = contracts[contractId];
    contractMeta.active = active;
    contractMeta.permissions = permissions;
    emit ContractUpdate(contractId, contractMeta, block.timestamp);
  }

}