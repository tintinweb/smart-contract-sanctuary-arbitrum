// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces

// libraries

// contracts
import {ERC721A} from "contracts/src/diamond/facets/token/ERC721A/ERC721A.sol";

contract MockERC721A is ERC721A {
  constructor() {
    __ERC721A_init_unchained("TownsTest", "TNFT");
  }

  function mintTo(address to) external returns (uint256 tokenId) {
    tokenId = _nextTokenId();
    _mint(to, 1);
  }

  function mint(address to, uint256 amount) external {
    _mint(to, amount);
  }

  function burn(uint256 token) external {
    _burn(token);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC721A} from "./IERC721A.sol";
import {ERC721AStorage} from "./ERC721AStorage.sol";
import {ERC721ABase} from "./ERC721ABase.sol";
import {Facet} from "contracts/src/diamond/facets/Facet.sol";

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A, ERC721ABase, Facet {
  using ERC721AStorage for ERC721AStorage.Layout;

  function __ERC721A_init(
    string memory name_,
    string memory symbol_
  ) external onlyInitializing {
    __ERC721A_init_unchained(name_, symbol_);
  }

  function __ERC721A_init_unchained(
    string memory name_,
    string memory symbol_
  ) internal {
    _addInterface(0x80ac58cd); // ERC165 Interface ID for ERC721
    _addInterface(0x5b5e139f); // ERC165 Interface ID for ERC721Metadata
    __ERC721ABase_init(name_, symbol_);
  }

  /**
   * @dev Returns the total number of tokens in existence.
   * Burned tokens will reduce the count.
   * To get the total number of tokens minted, please see {_totalMinted}.
   */
  function totalSupply() public view virtual returns (uint256) {
    return _totalSupply();
  }

  /**
   * @dev Returns the number of tokens in `owner`'s account.
   */
  function balanceOf(address owner) public view virtual returns (uint256) {
    return _balanceOf(owner);
  }

  // =============================================================
  //                        IERC721Metadata
  // =============================================================

  /**
   * @dev Returns the token collection name.
   */
  function name() public view virtual override returns (string memory) {
    return ERC721AStorage.layout()._name;
  }

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() public view virtual override returns (string memory) {
    return ERC721AStorage.layout()._symbol;
  }

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(
    uint256 tokenId
  ) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length != 0
        ? string(abi.encodePacked(baseURI, _toString(tokenId)))
        : "";
  }

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(
    uint256 tokenId
  ) public view virtual override returns (address) {
    return address(uint160(_packedOwnershipOf(tokenId)));
  }

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account. See {ERC721A-_approve}.
   *
   * Requirements:
   *
   * - The caller must own the token or be an approved operator.
   */
  function approve(
    address to,
    uint256 tokenId
  ) public payable virtual override {
    _approve(to, tokenId, true);
  }

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(
    uint256 tokenId
  ) public view virtual override returns (address) {
    return _getApproved(tokenId);
  }

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom}
   * for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   *
   * Emits an {ApprovalForAll} event.
   */
  function setApprovalForAll(
    address operator,
    bool approved
  ) public virtual override {
    ERC721AStorage.layout()._operatorApprovals[_msgSenderERC721A()][
      operator
    ] = approved;
    emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
  }

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}.
   */
  function isApprovedForAll(
    address owner,
    address operator
  ) public view virtual override returns (bool) {
    return _isApprovedForAll(owner, operator);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token
   * by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable virtual override {
    uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

    if (address(uint160(prevOwnershipPacked)) != from)
      revert TransferFromIncorrectOwner();

    (
      uint256 approvedAddressSlot,
      address approvedAddress
    ) = _getApprovedSlotAndAddress(tokenId);

    // The nested ifs save around 20+ gas over a compound boolean condition.
    if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
      if (!isApprovedForAll(from, _msgSenderERC721A()))
        revert TransferCallerNotOwnerNorApproved();

    if (to == address(0)) revert TransferToZeroAddress();

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner.
    assembly {
      if approvedAddress {
        // This is equivalent to `delete _tokenApprovals[tokenId]`.
        sstore(approvedAddressSlot, 0)
      }
    }

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
    unchecked {
      // We can directly increment and decrement the balances.
      --ERC721AStorage.layout()._packedAddressData[from]; // Updates: `balance -= 1`.
      ++ERC721AStorage.layout()._packedAddressData[to]; // Updates: `balance += 1`.

      // Updates:
      // - `address` to the next owner.
      // - `startTimestamp` to the timestamp of transfering.
      // - `burned` to `false`.
      // - `nextInitialized` to `true`.
      ERC721AStorage.layout()._packedOwnerships[tokenId] = _packOwnershipData(
        to,
        _BITMASK_NEXT_INITIALIZED |
          _nextExtraData(from, to, prevOwnershipPacked)
      );

      // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
      if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
        uint256 nextTokenId = tokenId + 1;
        // If the next slot's address is zero and not burned (i.e. packed value is zero).
        if (ERC721AStorage.layout()._packedOwnerships[nextTokenId] == 0) {
          // If the next slot is within bounds.
          if (nextTokenId != ERC721AStorage.layout()._currentIndex) {
            // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
            ERC721AStorage.layout()._packedOwnerships[
              nextTokenId
            ] = prevOwnershipPacked;
          }
        }
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token
   * by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement
   * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public payable virtual override {
    transferFrom(from, to, tokenId);
    if (to.code.length != 0)
      if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
        revert TransferToNonERC721ReceiverImplementer();
      }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721ReceiverUpgradeable {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

interface IERC721ABase {
  // =============================================================
  //                            STRUCTS
  // =============================================================
  struct TokenApprovalRef {
    address value;
  }

  struct TokenOwnership {
    // The address of the owner.
    address addr;
    // Stores the start time of ownership with minimal overhead for tokenomics.
    uint64 startTimestamp;
    // Whether the token has been burned.
    bool burned;
    // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
    uint24 extraData;
  }

  // =============================================================
  //                           ERRORS
  // =============================================================

  /**
   * The caller must own the token or be an approved operator.
   */
  error ApprovalCallerNotOwnerNorApproved();

  /**
   * The token does not exist.
   */
  error ApprovalQueryForNonexistentToken();

  /**
   * Cannot query the balance for the zero address.
   */
  error BalanceQueryForZeroAddress();

  /**
   * Cannot mint to the zero address.
   */
  error MintToZeroAddress();

  /**
   * The quantity of tokens minted must be more than zero.
   */
  error MintZeroQuantity();

  /**
   * The token does not exist.
   */
  error OwnerQueryForNonexistentToken();

  /**
   * The caller must own the token or be an approved operator.
   */
  error TransferCallerNotOwnerNorApproved();

  /**
   * The token must be owned by `from`.
   */
  error TransferFromIncorrectOwner();

  /**
   * Cannot safely transfer to a contract that does not implement the
   * ERC721Receiver interface.
   */
  error TransferToNonERC721ReceiverImplementer();

  /**
   * Cannot transfer to the zero address.
   */
  error TransferToZeroAddress();

  /**
   * The token does not exist.
   */
  error URIQueryForNonexistentToken();

  /**
   * The `quantity` minted with ERC2309 exceeds the safety limit.
   */
  error MintERC2309QuantityExceedsLimit();

  /**
   * The `extraData` cannot be set on an unintialized ownership slot.
   */
  error OwnershipNotInitializedForExtraData();

  // =============================================================
  //                            IERC721
  // =============================================================

  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );

  /**
   * @dev Emitted when `owner` enables or disables
   * (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  // =============================================================
  //                           IERC2309
  // =============================================================

  /**
   * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
   * (inclusive) is transferred from `from` to `to`, as defined in the
   * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
   *
   * See {_mintERC2309} for more details.
   */
  event ConsecutiveTransfer(
    uint256 indexed fromTokenId,
    uint256 toTokenId,
    address indexed from,
    address indexed to
  );
}

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A is IERC721ABase {
  // =============================================================
  //                         TOKEN COUNTERS
  // =============================================================

  /**
   * @dev Returns the total number of tokens in existence.
   * Burned tokens will reduce the count.
   * To get the total number of tokens minted, please see {_totalMinted}.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the number of tokens in `owner`'s account.
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
   * @dev Safely transfers `tokenId` token from `from` to `to`,
   * checking first that contract recipients are aware of the ERC721 protocol
   * to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move
   * this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement
   * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external payable;

  /**
   * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external payable;

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
   * whenever possible.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token
   * by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external payable;

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the
   * zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the token or be an approved operator.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approve(address to, uint256 tokenId) external payable;

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom}
   * for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   *
   * Emits an {ApprovalForAll} event.
   */
  function setApprovalForAll(address operator, bool _approved) external;

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(
    uint256 tokenId
  ) external view returns (address operator);

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}.
   */
  function isApprovedForAll(
    address owner,
    address operator
  ) external view returns (bool);

  // =============================================================
  //                        IERC721Metadata
  // =============================================================

  /**
   * @dev Returns the token collection name.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC721ABase} from "./IERC721A.sol";

library ERC721AStorage {
  // keccak256(abi.encode(uint256(keccak256("diamond.facets.token.ERC721A.storage")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 internal constant STORAGE_SLOT =
    0x6569bde4a160c636ea8b8d11acb83a60d7fec0b8f2e09389306cba0e1340df00;

  struct Layout {
    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 _currentIndex;
    // The number of tokens burned.
    uint256 _burnCounter;
    // Token name
    string _name;
    // Token symbol
    string _symbol;
    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) _packedOwnerships;
    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) _packedAddressData;
    // Mapping from token ID to approved address.
    mapping(uint256 => IERC721ABase.TokenApprovalRef) _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;
  }

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces
import {IERC721ABase, ERC721A__IERC721ReceiverUpgradeable} from "./IERC721A.sol";

// libraries
import {ERC721AStorage} from "./ERC721AStorage.sol";

// contracts

abstract contract ERC721ABase is IERC721ABase {
  // =============================================================
  //                           CONSTANTS
  // =============================================================

  // Mask of an entry in packed address data.
  uint256 internal constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

  // The bit position of `numberMinted` in packed address data.
  uint256 internal constant _BITPOS_NUMBER_MINTED = 64;

  // The bit position of `numberBurned` in packed address data.
  uint256 internal constant _BITPOS_NUMBER_BURNED = 128;

  // The bit position of `aux` in packed address data.
  uint256 internal constant _BITPOS_AUX = 192;

  // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
  uint256 internal constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

  // The bit position of `startTimestamp` in packed ownership.
  uint256 internal constant _BITPOS_START_TIMESTAMP = 160;

  // The bit mask of the `burned` bit in packed ownership.
  uint256 internal constant _BITMASK_BURNED = 1 << 224;

  // The bit position of the `nextInitialized` bit in packed ownership.
  uint256 internal constant _BITPOS_NEXT_INITIALIZED = 225;

  // The bit mask of the `nextInitialized` bit in packed ownership.
  uint256 internal constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

  // The bit position of `extraData` in packed ownership.
  uint256 internal constant _BITPOS_EXTRA_DATA = 232;

  // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
  uint256 internal constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

  // The mask of the lower 160 bits for addresses.
  uint256 internal constant _BITMASK_ADDRESS = (1 << 160) - 1;

  // The maximum `quantity` that can be minted with {_mintERC2309}.
  // This limit is to prevent overflows on the address data entries.
  // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
  // is required to cause an overflow, which is unrealistic.
  uint256 internal constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

  // The `Transfer` event signature is given by:
  // `keccak256(bytes("Transfer(address,address,uint256)"))`.
  bytes32 internal constant _TRANSFER_EVENT_SIGNATURE =
    0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

  function __ERC721ABase_init(
    string memory name,
    string memory symbol
  ) internal {
    ERC721AStorage.Layout storage ds = ERC721AStorage.layout();

    ds._name = name;
    ds._symbol = symbol;
    ds._currentIndex = _startTokenId();
  }

  // =============================================================
  //                           EXTERNAL
  // =============================================================
  function _totalSupply() internal view returns (uint256) {
    // Counter underflow is impossible as _burnCounter cannot be incremented
    // more than `_currentIndex - _startTokenId()` times.
    unchecked {
      return
        ERC721AStorage.layout()._currentIndex -
        ERC721AStorage.layout()._burnCounter -
        _startTokenId();
    }
  }

  function _balanceOf(address owner) internal view returns (uint256) {
    if (owner == address(0)) revert BalanceQueryForZeroAddress();
    return
      ERC721AStorage.layout()._packedAddressData[owner] &
      _BITMASK_ADDRESS_DATA_ENTRY;
  }

  // =============================================================
  //                   TOKEN COUNTING OPERATIONS
  // =============================================================

  /**
   * @dev Returns the starting token ID.
   * To change the starting token ID, please override this function.
   */
  function _startTokenId() internal view virtual returns (uint256) {
    return 0;
  }

  /**
   * @dev Returns the next token ID to be minted.
   */
  function _nextTokenId() internal view virtual returns (uint256) {
    return ERC721AStorage.layout()._currentIndex;
  }

  /**
   * @dev Returns the total amount of tokens minted in the contract.
   */
  function _totalMinted() internal view virtual returns (uint256) {
    // Counter underflow is impossible as `_currentIndex` does not decrement,
    // and it is initialized to `_startTokenId()`.
    unchecked {
      return ERC721AStorage.layout()._currentIndex - _startTokenId();
    }
  }

  /**
   * @dev Returns the total number of tokens burned.
   */
  function _totalBurned() internal view virtual returns (uint256) {
    return ERC721AStorage.layout()._burnCounter;
  }

  // =============================================================
  //                    ADDRESS DATA OPERATIONS
  // =============================================================

  /**
   * Returns the number of tokens minted by `owner`.
   */
  function _numberMinted(address owner) internal view returns (uint256) {
    return
      (ERC721AStorage.layout()._packedAddressData[owner] >>
        _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
  }

  /**
   * Returns the number of tokens burned by or on behalf of `owner`.
   */
  function _numberBurned(address owner) internal view returns (uint256) {
    return
      (ERC721AStorage.layout()._packedAddressData[owner] >>
        _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
  }

  /**
   * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
   */
  function _getAux(address owner) internal view returns (uint64) {
    return
      uint64(ERC721AStorage.layout()._packedAddressData[owner] >> _BITPOS_AUX);
  }

  /**
   * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
   * If there are multiple variables, please pack them into a uint64.
   */
  function _setAux(address owner, uint64 aux) internal virtual {
    uint256 packed = ERC721AStorage.layout()._packedAddressData[owner];
    uint256 auxCasted;
    // Cast `aux` with assembly to avoid redundant masking.
    assembly {
      auxCasted := aux
    }
    packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
    ERC721AStorage.layout()._packedAddressData[owner] = packed;
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, it can be overridden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  // =============================================================
  //                     OWNERSHIPS OPERATIONS
  // =============================================================

  /**
   * @dev Gas spent here starts off proportional to the maximum mint batch size.
   * It gradually moves to O(1) as tokens get transferred around over time.
   */
  function _ownershipOf(
    uint256 tokenId
  ) internal view virtual returns (TokenOwnership memory) {
    return _unpackedOwnership(_packedOwnershipOf(tokenId));
  }

  /**
   * @dev Returns the unpacked `TokenOwnership` struct at `index`.
   */
  function _ownershipAt(
    uint256 index
  ) internal view virtual returns (TokenOwnership memory) {
    return _unpackedOwnership(ERC721AStorage.layout()._packedOwnerships[index]);
  }

  /**
   * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
   */
  function _initializeOwnershipAt(uint256 index) internal virtual {
    if (ERC721AStorage.layout()._packedOwnerships[index] == 0) {
      ERC721AStorage.layout()._packedOwnerships[index] = _packedOwnershipOf(
        index
      );
    }
  }

  /**
   * Returns the packed ownership data of `tokenId`.
   */
  function _packedOwnershipOf(
    uint256 tokenId
  ) internal view returns (uint256 packed) {
    if (_startTokenId() <= tokenId) {
      ERC721AStorage.Layout storage ds = ERC721AStorage.layout();

      packed = ds._packedOwnerships[tokenId];
      // If not burned.
      if (packed & _BITMASK_BURNED == 0) {
        // If the data at the starting slot does not exist, start the scan.
        if (packed == 0) {
          if (tokenId >= ds._currentIndex)
            revert OwnerQueryForNonexistentToken();
          // Invariant:
          // There will always be an initialized ownership slot
          // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
          // before an unintialized ownership slot
          // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
          // Hence, `tokenId` will not underflow.
          //
          // We can directly compare the packed value.
          // If the address is zero, packed will be zero.
          for (;;) {
            unchecked {
              packed = ds._packedOwnerships[--tokenId];
            }
            if (packed == 0) continue;
            return packed;
          }
        }
        // Otherwise, the data exists and is not burned. We can skip the scan.
        // This is possible because we have already achieved the target condition.
        // This saves 2143 gas on transfers of initialized tokens.
        return packed;
      }
    }
    revert OwnerQueryForNonexistentToken();
  }

  /**
   * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
   */
  function _unpackedOwnership(
    uint256 packed
  ) internal pure returns (TokenOwnership memory ownership) {
    ownership.addr = address(uint160(packed));
    ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
    ownership.burned = packed & _BITMASK_BURNED != 0;
    ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
  }

  /**
   * @dev Packs ownership data into a single uint256.
   */
  function _packOwnershipData(
    address owner,
    uint256 flags
  ) internal view returns (uint256 result) {
    assembly {
      // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
      owner := and(owner, _BITMASK_ADDRESS)
      // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
      result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
    }
  }

  /**
   * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
   */
  function _nextInitializedFlag(
    uint256 quantity
  ) internal pure returns (uint256 result) {
    // For branchless setting of the `nextInitialized` flag.
    assembly {
      // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
      result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
    }
  }

  // =============================================================
  //                      APPROVAL OPERATIONS
  // =============================================================

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted. See {_mint}.
   */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return
      _startTokenId() <= tokenId &&
      tokenId < ERC721AStorage.layout()._currentIndex && // If within bounds,
      ERC721AStorage.layout()._packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
  }

  /**
   * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
   */
  function _isSenderApprovedOrOwner(
    address approvedAddress,
    address owner,
    address msgSender
  ) internal pure returns (bool result) {
    assembly {
      // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
      owner := and(owner, _BITMASK_ADDRESS)
      // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
      msgSender := and(msgSender, _BITMASK_ADDRESS)
      // `msgSender == owner || msgSender == approvedAddress`.
      result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
    }
  }

  /**
   * @dev Returns the storage slot and value for the approved address of `tokenId`.
   */
  function _getApprovedSlotAndAddress(
    uint256 tokenId
  )
    internal
    view
    returns (uint256 approvedAddressSlot, address approvedAddress)
  {
    TokenApprovalRef storage tokenApproval = ERC721AStorage
      .layout()
      ._tokenApprovals[tokenId];

    // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
    assembly {
      approvedAddressSlot := tokenApproval.slot
      approvedAddress := sload(approvedAddressSlot)
    }
  }

  // =============================================================
  //                      TRANSFER OPERATIONS
  // =============================================================

  /**
   * @dev Hook that is called before a set of serially-ordered token IDs
   * are about to be transferred. This includes minting.
   * And also called before burning one token.
   *
   * `startTokenId` - the first token ID to be transferred.
   * `quantity` - the amount to be transferred.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, `tokenId` will be burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token IDs
   * have been transferred. This includes minting.
   * And also called after one token has been burned.
   *
   * `startTokenId` - the first token ID to be transferred.
   * `quantity` - the amount to be transferred.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
   * transferred to `to`.
   * - When `from` is zero, `tokenId` has been minted for `to`.
   * - When `to` is zero, `tokenId` has been burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
   *
   * `from` - Previous owner of the given token ID.
   * `to` - Target address that will receive the token.
   * `tokenId` - Token ID to be transferred.
   * `_data` - Optional data to send along with the call.
   *
   * Returns whether the call correctly returned the expected magic value.
   */
  function _checkContractOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal returns (bool) {
    try
      ERC721A__IERC721ReceiverUpgradeable(to).onERC721Received(
        _msgSenderERC721A(),
        from,
        tokenId,
        _data
      )
    returns (bytes4 retval) {
      return
        retval ==
        ERC721A__IERC721ReceiverUpgradeable(to).onERC721Received.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        revert TransferToNonERC721ReceiverImplementer();
      } else {
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }
  }

  // =============================================================
  //                        MINT OPERATIONS
  // =============================================================

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `quantity` must be greater than 0.
   *
   * Emits a {Transfer} event for each mint.
   */
  function _mint(address to, uint256 quantity) internal virtual {
    uint256 startTokenId = ERC721AStorage.layout()._currentIndex;
    if (quantity == 0) revert MintZeroQuantity();

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    // Overflows are incredibly unrealistic.
    // `balance` and `numberMinted` have a maximum limit of 2**64.
    // `tokenId` has a maximum limit of 2**256.
    unchecked {
      // Updates:
      // - `balance += quantity`.
      // - `numberMinted += quantity`.
      //
      // We can directly add to the `balance` and `numberMinted`.
      ERC721AStorage.layout()._packedAddressData[to] +=
        quantity *
        ((1 << _BITPOS_NUMBER_MINTED) | 1);

      // Updates:
      // - `address` to the owner.
      // - `startTimestamp` to the timestamp of minting.
      // - `burned` to `false`.
      // - `nextInitialized` to `quantity == 1`.
      ERC721AStorage.layout()._packedOwnerships[
        startTokenId
      ] = _packOwnershipData(
        to,
        _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
      );

      uint256 toMasked;
      uint256 end = startTokenId + quantity;

      // Use assembly to loop and emit the `Transfer` event for gas savings.
      // The duplicated `log4` removes an extra check and reduces stack juggling.
      // The assembly, together with the surrounding Solidity code, have been
      // delicately arranged to nudge the compiler into producing optimized opcodes.
      assembly {
        // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
        toMasked := and(to, _BITMASK_ADDRESS)
        // Emit the `Transfer` event.
        log4(
          0, // Start of data (0, since no data).
          0, // End of data (0, since no data).
          _TRANSFER_EVENT_SIGNATURE, // Signature.
          0, // `address(0)`.
          toMasked, // `to`.
          startTokenId // `tokenId`.
        )

        // The `iszero(eq(,))` check ensures that large values of `quantity`
        // that overflows uint256 will make the loop run out of gas.
        // The compiler will optimize the `iszero` away for performance.
        for {
          let tokenId := add(startTokenId, 1)
        } iszero(eq(tokenId, end)) {
          tokenId := add(tokenId, 1)
        } {
          // Emit the `Transfer` event. Similar to above.
          log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
        }
      }
      if (toMasked == 0) revert MintToZeroAddress();

      ERC721AStorage.layout()._currentIndex = end;
    }
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * This function is intended for efficient minting only during contract creation.
   *
   * It emits only one {ConsecutiveTransfer} as defined in
   * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
   * instead of a sequence of {Transfer} event(s).
   *
   * Calling this function outside of contract creation WILL make your contract
   * non-compliant with the ERC721 standard.
   * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
   * {ConsecutiveTransfer} event is only permissible during contract creation.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `quantity` must be greater than 0.
   *
   * Emits a {ConsecutiveTransfer} event.
   */
  function _mintERC2309(address to, uint256 quantity) internal virtual {
    uint256 startTokenId = ERC721AStorage.layout()._currentIndex;
    if (to == address(0)) revert MintToZeroAddress();
    if (quantity == 0) revert MintZeroQuantity();
    if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT)
      revert MintERC2309QuantityExceedsLimit();

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
    unchecked {
      // Updates:
      // - `balance += quantity`.
      // - `numberMinted += quantity`.
      //
      // We can directly add to the `balance` and `numberMinted`.
      ERC721AStorage.layout()._packedAddressData[to] +=
        quantity *
        ((1 << _BITPOS_NUMBER_MINTED) | 1);

      // Updates:
      // - `address` to the owner.
      // - `startTimestamp` to the timestamp of minting.
      // - `burned` to `false`.
      // - `nextInitialized` to `quantity == 1`.
      ERC721AStorage.layout()._packedOwnerships[
        startTokenId
      ] = _packOwnershipData(
        to,
        _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
      );

      emit ConsecutiveTransfer(
        startTokenId,
        startTokenId + quantity - 1,
        address(0),
        to
      );

      ERC721AStorage.layout()._currentIndex = startTokenId + quantity;
    }
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Safely mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - If `to` refers to a smart contract, it must implement
   * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
   * - `quantity` must be greater than 0.
   *
   * See {_mint}.
   *
   * Emits a {Transfer} event for each mint.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal virtual {
    _mint(to, quantity);

    unchecked {
      if (to.code.length != 0) {
        uint256 end = ERC721AStorage.layout()._currentIndex;
        uint256 index = end - quantity;
        do {
          if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
          }
        } while (index < end);
        // Reentrancy protection.
        if (ERC721AStorage.layout()._currentIndex != end) revert();
      }
    }
  }

  /**
   * @dev Equivalent to `_safeMint(to, quantity, '')`.
   */
  function _safeMint(address to, uint256 quantity) internal virtual {
    _safeMint(to, quantity, "");
  }

  // =============================================================
  //                       APPROVAL OPERATIONS
  // =============================================================
  function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
    return address(uint160(_packedOwnershipOf(tokenId)));
  }

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}.
   */
  function _isApprovedForAll(
    address owner,
    address operator
  ) internal view virtual returns (bool) {
    return ERC721AStorage.layout()._operatorApprovals[owner][operator];
  }

  function _getApproved(
    uint256 tokenId
  ) internal view virtual returns (address) {
    if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

    return ERC721AStorage.layout()._tokenApprovals[tokenId].value;
  }

  /**
   * @dev Equivalent to `_approve(to, tokenId, false)`.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _approve(to, tokenId, false);
  }

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the
   * zero address clears previous approvals.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    bool approvalCheck
  ) internal virtual {
    address owner = _ownerOf(tokenId);

    if (approvalCheck)
      if (_msgSenderERC721A() != owner)
        if (!_isApprovedForAll(owner, _msgSenderERC721A())) {
          revert ApprovalCallerNotOwnerNorApproved();
        }

    ERC721AStorage.layout()._tokenApprovals[tokenId].value = to;
    emit Approval(owner, to, tokenId);
  }

  // =============================================================
  //                        BURN OPERATIONS
  // =============================================================

  /**
   * @dev Equivalent to `_burn(tokenId, false)`.
   */
  function _burn(uint256 tokenId) internal virtual {
    _burn(tokenId, false);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
    uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

    address from = address(uint160(prevOwnershipPacked));

    (
      uint256 approvedAddressSlot,
      address approvedAddress
    ) = _getApprovedSlotAndAddress(tokenId);

    if (approvalCheck) {
      // The nested ifs save around 20+ gas over a compound boolean condition.
      if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
        if (!_isApprovedForAll(from, _msgSenderERC721A()))
          revert TransferCallerNotOwnerNorApproved();
    }

    _beforeTokenTransfers(from, address(0), tokenId, 1);

    // Clear approvals from the previous owner.
    assembly {
      if approvedAddress {
        // This is equivalent to `delete _tokenApprovals[tokenId]`.
        sstore(approvedAddressSlot, 0)
      }
    }

    ERC721AStorage.Layout storage ds = ERC721AStorage.layout();

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
    unchecked {
      // Updates:
      // - `balance -= 1`.
      // - `numberBurned += 1`.
      //
      // We can directly decrement the balance, and increment the number burned.
      // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
      ds._packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

      // Updates:
      // - `address` to the last owner.
      // - `startTimestamp` to the timestamp of burning.
      // - `burned` to `true`.
      // - `nextInitialized` to `true`.
      ds._packedOwnerships[tokenId] = _packOwnershipData(
        from,
        (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) |
          _nextExtraData(from, address(0), prevOwnershipPacked)
      );

      // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
      if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
        uint256 nextTokenId = tokenId + 1;
        // If the next slot's address is zero and not burned (i.e. packed value is zero).
        if (ds._packedOwnerships[nextTokenId] == 0) {
          // If the next slot is within bounds.
          if (nextTokenId != ds._currentIndex) {
            // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
            ds._packedOwnerships[nextTokenId] = prevOwnershipPacked;
          }
        }
      }
    }

    emit Transfer(from, address(0), tokenId);
    _afterTokenTransfers(from, address(0), tokenId, 1);

    // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
    unchecked {
      ds._burnCounter++;
    }
  }

  // =============================================================
  //                     EXTRA DATA OPERATIONS
  // =============================================================

  /**
   * @dev Directly sets the extra data for the ownership data `index`.
   */
  function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
    uint256 packed = ERC721AStorage.layout()._packedOwnerships[index];
    if (packed == 0) revert OwnershipNotInitializedForExtraData();
    uint256 extraDataCasted;
    // Cast `extraData` with assembly to avoid redundant masking.
    assembly {
      extraDataCasted := extraData
    }
    packed =
      (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) |
      (extraDataCasted << _BITPOS_EXTRA_DATA);
    ERC721AStorage.layout()._packedOwnerships[index] = packed;
  }

  /**
   * @dev Called during each token transfer to set the 24bit `extraData` field.
   * Intended to be overridden by the cosumer contract.
   *
   * `previousExtraData` - the value of `extraData` before transfer.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, `tokenId` will be burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _extraData(
    address from,
    address to,
    uint24 previousExtraData
  ) internal view virtual returns (uint24) {}

  /**
   * @dev Returns the next extra data for the packed ownership data.
   * The returned result is shifted into position.
   */
  function _nextExtraData(
    address from,
    address to,
    uint256 prevOwnershipPacked
  ) internal view returns (uint256) {
    uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
    return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
  }

  // =============================================================
  //                       OTHER OPERATIONS
  // =============================================================

  /**
   * @dev Returns the message sender (defaults to `msg.sender`).
   *
   * If you are writing GSN compatible contracts, you need to override this function.
   */
  function _msgSenderERC721A() internal view virtual returns (address) {
    return msg.sender;
  }

  /**
   * @dev Converts a uint256 to its ASCII string decimal representation.
   */
  function _toString(
    uint256 value
  ) internal pure virtual returns (string memory str) {
    assembly {
      // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
      // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
      // We will need 1 word for the trailing zeros padding, 1 word for the length,
      // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
      let m := add(mload(0x40), 0xa0)
      // Update the free memory pointer to allocate.
      mstore(0x40, m)
      // Assign the `str` to the end.
      str := sub(m, 0x20)
      // Zeroize the slot after the string.
      mstore(str, 0)

      // Cache the end of the memory to calculate the length later.
      let end := str

      // We write the string from rightmost digit to leftmost digit.
      // The following is essentially a do-while loop that also handles the zero case.
      // prettier-ignore
      for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

      let length := sub(end, str)
      // Move the pointer 32 bytes leftwards to make room for the length.
      str := sub(str, 0x20)
      // Store the length.
      mstore(str, length)
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces

// libraries

// contracts

import {Initializable} from "contracts/src/diamond/facets/initializable/Initializable.sol";
import {IntrospectionBase} from "contracts/src/diamond/facets/introspection/IntrospectionBase.sol";

abstract contract Facet is Initializable, IntrospectionBase {
  constructor() {
    _disableInitializers();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.23;

import {InitializableStorage} from "./InitializableStorage.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

error Initializable_AlreadyInitialized(uint32 version);
error Initializable_NotInInitializingState();
error Initializable_InInitializingState();

abstract contract Initializable {
  event Initialized(uint32 version);

  modifier initializer() {
    InitializableStorage.Layout storage s = InitializableStorage.layout();

    bool isTopLevelCall = !s.initializing;
    if (isTopLevelCall ? s.version >= 1 : _isNotConstructor()) {
      revert Initializable_AlreadyInitialized(s.version);
    }
    s.version = 1;
    if (isTopLevelCall) {
      s.initializing = true;
    }
    _;
    if (isTopLevelCall) {
      s.initializing = false;
      emit Initialized(1);
    }
  }

  modifier reinitializer(uint32 version) {
    InitializableStorage.Layout storage s = InitializableStorage.layout();

    if (s.initializing || s.version >= version) {
      revert Initializable_AlreadyInitialized(s.version);
    }
    s.version = version;
    s.initializing = true;
    _;
    s.initializing = false;
    emit Initialized(version);
  }

  modifier onlyInitializing() {
    if (!InitializableStorage.layout().initializing)
      revert Initializable_NotInInitializingState();
    _;
  }

  function _getInitializedVersion()
    internal
    view
    virtual
    returns (uint32 version)
  {
    version = InitializableStorage.layout().version;
  }

  function _nextVersion() internal view returns (uint32) {
    return InitializableStorage.layout().version + 1;
  }

  function _disableInitializers() internal {
    InitializableStorage.Layout storage s = InitializableStorage.layout();
    if (s.initializing) revert Initializable_InInitializingState();

    if (s.version < type(uint32).max) {
      s.version = type(uint32).max;
      emit Initialized(type(uint32).max);
    }
  }

  function _isNotConstructor() private view returns (bool) {
    return address(this).code.length != 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces
import {IIntrospectionBase} from "./IERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// libraries
import {IntrospectionStorage} from "./IntrospectionStorage.sol";

abstract contract IntrospectionBase is IIntrospectionBase {
  function __IntrospectionBase_init() internal {
    _addInterface(type(IERC165).interfaceId);
  }

  function _addInterface(bytes4 interfaceId) internal {
    if (!_supportsInterface(interfaceId)) {
      IntrospectionStorage.layout().supportedInterfaces[interfaceId] = true;
    } else {
      revert Introspection_AlreadySupported();
    }
    emit InterfaceAdded(interfaceId);
  }

  function _removeInterface(bytes4 interfaceId) internal {
    if (_supportsInterface(interfaceId)) {
      IntrospectionStorage.layout().supportedInterfaces[interfaceId] = false;
    } else {
      revert Introspection_NotSupported();
    }
    emit InterfaceRemoved(interfaceId);
  }

  function _supportsInterface(bytes4 interfaceId) internal view returns (bool) {
    return
      IntrospectionStorage.layout().supportedInterfaces[interfaceId] == true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces

// libraries

// contracts

library InitializableStorage {
  // keccak256(abi.encode(uint256(keccak256("diamond.facets.initializable.storage")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 internal constant STORAGE_SLOT =
    0x59b501c3653afc186af7d48dda36cf6732bd21629a6295693664240a6ef52000;

  struct Layout {
    uint32 version;
    bool initializing;
  }

  function layout() internal pure returns (Layout storage s) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      s.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces

// libraries

// contracts

interface IIntrospectionBase {
  error Introspection_AlreadySupported();
  error Introspection_NotSupported();

  /**
   * @notice Emitted when an interface is added to the contract via `_addInterface`.
   */
  event InterfaceAdded(bytes4 indexed interfaceId);

  /**
   * @notice Emitted when an interface is removed from the contract via `_removeInterface`.
   */
  event InterfaceRemoved(bytes4 indexed interfaceId);
}

/**
 * @title IERC165
 * @notice Interface of the ERC165 standard. See [EIP-165](https://eips.ethereum.org/EIPS/eip-165).
 */
interface IERC165 is IIntrospectionBase {
  /**
   * @notice Returns true if this contract implements the interface
   * @param interfaceId The 4 bytes interface identifier, as specified in ERC-165
   * @dev Has to be manually set by a facet at initialization.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces

// libraries

// contracts

library IntrospectionStorage {
  // keccak256(abi.encode(uint256(keccak256("diamond.facets.introspection.storage")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 internal constant STORAGE_SLOT =
    0x81088bbc801e045ea3e7620779ab349988f58afbdfba10dff983df3f33522b00;

  struct Layout {
    mapping(bytes4 => bool) supportedInterfaces;
  }

  function layout() internal pure returns (Layout storage ds) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      ds.slot := slot
    }
  }
}