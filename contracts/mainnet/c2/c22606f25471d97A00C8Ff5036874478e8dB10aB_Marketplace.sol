pragma solidity ^0.8.24;

import "../Interfaces/IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../Interfaces/IERC173.sol";
import "../Utils/Context.sol";

abstract contract ERC173 is Context {
    error NotAnOwner();
    error NotAnBroker();

    address private _owner;
    address private _broker;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address ownerOnDeploy, address broker) {
        _owner = ownerOnDeploy;
        _broker = broker;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (_msgSender() != owner()) revert NotAnOwner();
        _;
    }

    modifier onlyBroker() {
        if (_msgSender() != _broker) revert NotAnBroker();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        address oldOwner = _owner;

        _owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function setBroker(address newBroker) external virtual onlyOwner {
        _broker = newBroker;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return interfaceId == type(IERC173).interfaceId;
    }
}

pragma solidity ^0.8.24;

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

pragma solidity ^0.8.24;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Get the address of the owner
    /// @return The address of the owner.
    function owner() external view returns (address);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);
}

pragma solidity ^0.8.24;

import "./IERC165.sol";


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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Utils/Heap/MinHeap.sol";
import "./ERC/ERC173.sol";
import "./ERC/ERC165.sol";
import "./Interfaces/IERC173.sol";
import "./Interfaces/IERC20.sol";
import "./Interfaces/IERC721.sol";

contract Marketplace is ERC173 {
    MinHeapArray.Heap private heap;
    using MinHeapArray for MinHeapArray.Heap;

    error InvalidArrayLength();
    error InavlidAmount();
    error InvalidIndex();

    error UnsupportedCollection();
    error InsufficientNftAmount();

    error NftNotReserved();
    error ReservationsNotFound();

    error ReservationTimeExceed();
    error ReservationTimeNotExceed();

    event Wrapped(address indexed collection, uint256 indexed nftId);
    event Unwrapped(address indexed collection, uint256 indexed nftId);

    event Reserved(address indexed collection, uint256 indexed nftId);
    event ReservationCanceled(
        address indexed collection,
        uint256 indexed nftId
    );

    event MovedToMarket(address indexed collection, uint256 indexed nftId);

    struct Reservation {
        uint256 nftId;
        uint256 endDate;
    }

    IERC20 paymentToken;
    address public tokenSupplier;
    uint256 public reservationPeriod = 864000; // seconds

    // collection => nftId => wallet
    mapping(address => mapping(uint256 => address)) public reservationOwner;
    // collection => nftId => date
    mapping(address => mapping(uint256 => uint256)) public reservationEndPeriod;
    // collection => heap
    mapping(address => MinHeapArray.Heap) heaps;
    // collection => price
    mapping(address => uint256) public collectionPrice;
    // collection => wallet => index => nftId
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        public walletReservedTokens;
    // collection => tokenId => index
    mapping(address => mapping(uint256 => uint256))
        public walletReservedtokensIndex;
    // collection => wallet address => count
    mapping(address => mapping(address => uint256)) public walletReservedCount;
    // index > nftId
    mapping(address => uint256[]) public allReservedTokens;
    // collection => nftId => index
    mapping(address => mapping(uint256 => uint256))
        public allReservedTokensIndex;

    constructor(
        address _broker,
        address _erc20Token,
        address _nftCollection,
        uint256 _collectionPrice
    ) ERC173(msg.sender, _broker) {
        paymentToken = IERC20(_erc20Token);
        tokenSupplier = msg.sender;
        setCollectionPrice(_nftCollection, _collectionPrice);
    }

    function wrap(address collection, uint256[] calldata nftIds) external {
        uint256 price = collectionPrice[collection];
        if (price == 0) {
            revert UnsupportedCollection();
        }

        if (nftIds.length == 0) {
            revert InvalidArrayLength();
        }

        IERC721 nft = IERC721(collection);
        MinHeapArray.Heap storage _heap = heaps[collection];

        uint256 index = 0;
        uint256 nftIdsLength = nftIds.length;

        do {
            uint256 tokenId = nftIds[index];
            nft.transferFrom(msg.sender, address(this), tokenId);
            _heap.insert(tokenId);
            emit Wrapped(collection, tokenId);
            unchecked {
                ++index;
            }
        } while (index < nftIdsLength);

        paymentToken.transferFrom(
            tokenSupplier,
            msg.sender,
            price * nftIdsLength
        );
    }

    function unwrap(address collection, uint256 amount) external {
        uint256 price = collectionPrice[collection];

        if (price == 0) {
            revert UnsupportedCollection();
        }

        if (amount == 0) {
            revert InavlidAmount();
        }

        MinHeapArray.Heap storage _heap = heaps[collection];

        if (amount > _heap.size()) {
            revert InsufficientNftAmount();
        }

        IERC721 nft = IERC721(collection);
        paymentToken.transferFrom(msg.sender, tokenSupplier, price * amount);

        do {
            uint256 nftId = _heap.pop();
            nft.transferFrom(address(this), msg.sender, nftId);
            emit Unwrapped(collection, nftId);
            unchecked {
                --amount;
            }
        } while (amount != 0);
    }

    function makeReservation(
        address collection,
        uint256[] calldata nftIds
    ) external {
        uint256 price = collectionPrice[collection];
        if (price == 0) {
            revert UnsupportedCollection();
        }

        uint256 nftIdsLength = nftIds.length;
        if (nftIdsLength == 0) {
            revert InvalidArrayLength();
        }

        IERC721 nft = IERC721(collection);
        uint256 count = walletReservedCount[collection][msg.sender];

        uint256 index = 0;
        uint256 resEndPeriod = block.timestamp + reservationPeriod;
        do {
            uint256 tokenId = nftIds[index];
            nft.transferFrom(msg.sender, address(this), tokenId);
            unchecked {
                reservationEndPeriod[collection][tokenId] = resEndPeriod;
                reservationOwner[collection][tokenId] = msg.sender;

                allReservedTokensIndex[collection][tokenId] = allReservedTokens[
                    collection
                ].length;

                allReservedTokens[collection].push(tokenId);

                walletReservedTokens[collection][msg.sender][
                    count + 1
                ] = tokenId;
                walletReservedtokensIndex[collection][tokenId] = count + 1;
                walletReservedCount[collection][msg.sender]++;

                reservationOwner[collection][tokenId] = msg.sender;

                ++count;
                ++index;
            }
            emit Reserved(collection, tokenId);
        } while (index < nftIdsLength);

        paymentToken.transferFrom(
            tokenSupplier,
            msg.sender,
            price * nftIdsLength
        );
    }

    function removeReservation(
        address collection,
        uint256[] calldata nftIds
    ) external {
        uint256 price = collectionPrice[collection];
        if (price == 0) {
            revert UnsupportedCollection();
        }

        uint256 count = walletReservedCount[collection][msg.sender];
        if (count == 0) revert ReservationsNotFound();

        uint256 nftIdsLength = nftIds.length;
        if (nftIdsLength > count) revert InvalidArrayLength();

        paymentToken.transferFrom(
            msg.sender,
            tokenSupplier,
            price * nftIdsLength
        );

        IERC721 nft = IERC721(collection);
        uint256 index = 0;
        do {
            uint256 tokenId = nftIds[index];

            if (block.timestamp > reservationEndPeriod[collection][tokenId])
                revert ReservationTimeExceed();

            removeReservationFromStorage(collection, msg.sender, tokenId);
            nft.transferFrom(address(this), msg.sender, tokenId);

            emit ReservationCanceled(collection, tokenId);
            unchecked {
                ++index;
            }
        } while (index < nftIdsLength);
    }

    function removeReservationFromStorage(
        address collection,
        address wallet,
        uint256 tokenId
    ) private {
        uint256 tokenIndex = walletReservedtokensIndex[collection][tokenId];
        if (tokenIndex == 0) revert NftNotReserved();

        uint256 nftIdFromIndex = walletReservedTokens[collection][wallet][
            tokenIndex
        ];

        if (nftIdFromIndex != tokenId) revert NftNotReserved();

        uint256 lastTokenIndex = walletReservedCount[collection][wallet];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = walletReservedTokens[collection][wallet][
                lastTokenIndex
            ];

            walletReservedTokens[collection][wallet][tokenIndex] = lastTokenId;

            walletReservedtokensIndex[collection][lastTokenId] = tokenIndex;
        }

        uint256 allReservedLastIndex = allReservedTokens[collection].length - 1;
        uint256 tokenIndexInAllReserved = allReservedTokensIndex[collection][
            tokenId
        ];

        uint256 lastTokenIdInAllReserved = allReservedTokens[collection][
            allReservedLastIndex
        ];

        allReservedTokens[collection][
            tokenIndexInAllReserved
        ] = lastTokenIdInAllReserved;

        allReservedTokensIndex[collection][
            lastTokenIdInAllReserved
        ] = tokenIndexInAllReserved;

        walletReservedCount[collection][wallet]--;

        delete reservationOwner[collection][tokenId];

        delete allReservedTokensIndex[collection][tokenId];
        allReservedTokens[collection].pop();

        delete walletReservedtokensIndex[collection][tokenId];
        delete walletReservedTokens[collection][wallet][lastTokenIndex];
        delete reservationEndPeriod[collection][tokenId];
    }

    function moveToMarket(
        address collection,
        uint256[] calldata nftIds
    ) external onlyBroker {
        if (collectionPrice[collection] == 0) {
            revert UnsupportedCollection();
        }

        uint256 nftIdsLength = nftIds.length;

        if (nftIdsLength == 0) {
            revert InvalidArrayLength();
        }

        uint256 index = 0;
        MinHeapArray.Heap storage _heap = heaps[collection];

        do {
            uint256 tokenId = nftIds[index];

            if (reservationEndPeriod[collection][tokenId] > block.timestamp)
                revert ReservationTimeNotExceed();

            address _owner = reservationOwner[collection][tokenId];

            removeReservationFromStorage(collection, _owner, tokenId);

            _heap.insert(tokenId);
            emit MovedToMarket(collection, tokenId);

            unchecked {
                ++index;
            }
        } while (index < nftIdsLength);
    }

    function setCollectionPrice(
        address collection,
        uint256 price
    ) public onlyOwner {
        collectionPrice[collection] = price;
    }

    function setReservationPeriod(uint256 period) external onlyOwner {
        reservationPeriod = period;
    }

    function setTokenSupplier(address newSupplier) external onlyBroker {
        tokenSupplier = newSupplier;
    }

    function walletReservations(
        address collection,
        address wallet,
        uint256 fromIndex,
        uint256 count
    ) external view returns (Reservation[] memory) {
        uint256 _totalCount = walletReservedCount[collection][wallet];

        if (_totalCount == 0) {
            return new Reservation[](0);
        }

        if (fromIndex > _totalCount) {
            revert InvalidIndex();
        }

        uint256 toIndex = fromIndex + count;
        if (toIndex > _totalCount) {
            unchecked {
                toIndex = _totalCount;
                count = toIndex - fromIndex + 1;
            }
        }

        Reservation[] memory _reservations = new Reservation[](count);
        uint256 index = 0;

        do {
            unchecked {
                uint256 tokenId = walletReservedTokens[collection][wallet][
                    fromIndex
                ];
                uint256 endDate = reservationEndPeriod[collection][tokenId];
                _reservations[index] = Reservation(tokenId, endDate);
                ++index;
                ++fromIndex;
            }
        } while (index < count);

        return _reservations;
    }

    function allReservations(
        address collection,
        uint256 fromIndex,
        uint256 count
    ) external view returns (Reservation[] memory) {
        uint256 _totalCount = allReservedTokens[collection].length;

        if (_totalCount == 0) {
            return new Reservation[](0);
        }

        if (fromIndex > _totalCount) {
            revert InvalidIndex();
        }

        uint256 toIndex = fromIndex + count;
        if (toIndex > _totalCount) {
            unchecked {
                toIndex = _totalCount;
                count = toIndex - fromIndex;
            }
        }

        Reservation[] memory _reservations = new Reservation[](count);
        uint256 index = 0;
        do {
            uint256 tokenId = allReservedTokens[collection][fromIndex];

            _reservations[index] = Reservation(
                tokenId,
                reservationEndPeriod[collection][tokenId]
            );

            ++fromIndex;
            ++index;
        } while (index < count);

        return _reservations;
    }

    function reservationsCount(
        address collection
    ) external view returns (uint256) {
        return allReservedTokens[collection].length;
    }

    function nextNftForSale(
        address collection
    ) external view returns (uint256) {
        if (collectionPrice[collection] == 0) {
            revert UnsupportedCollection();
        }

        return heaps[collection].peek();
    }

    function wrappedCount(address collection) external view returns (uint256) {
        if (collectionPrice[collection] == 0) {
            revert UnsupportedCollection();
        }

        return heaps[collection].size();
    }

    function wrappedNfts(
        address collection,
        uint256 fromIndex,
        uint256 toIndex
    ) external view returns (uint256[] memory) {
        if (collectionPrice[collection] == 0) {
            revert UnsupportedCollection();
        }

        return heaps[collection]._readMany(fromIndex, toIndex);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library MinHeapArray {
    error MinHeap__Empty();
    error MinHeap__NotEmpty();
    error MinHeap__AlreadyExists();
    error MinHeap__InvalidIndex();

    struct Heap {
        uint256[] nodes;
        mapping(uint256 => bool) values;
    }

    function size(Heap storage heap) internal view returns (uint256) {
        return heap.nodes.length;
    }

    function _push(
        uint256[] storage nodes,
        uint256 node
    ) private returns (uint256 newLength) {
        uint256 nodesSlot;
        assembly {
            nodesSlot := add(1, sload(nodes.slot))
            newLength := add(1, sload(nodes.slot))

            // write new length
            sstore(nodes.slot, newLength)
            // heap nodes are 1-indexed for ease of calculating children
            // eg children of i are 2i and 2i + 1, which only works starting
            // with i = 1
            // this means nodes[0] is never accessed or written to, so adding an
            // extra
            // 1 to offset the length slot is not necessary.
            sstore(add(nodes.slot, newLength), node)
        }

    }

    function _copy(
        uint256[] storage nodes,
        uint256[] memory nodesToPush
    ) private {
        uint256 length = nodesToPush.length;
        assembly {
            sstore(nodes.slot, length)
            for {
                let i
            } lt(i, length) {
                i := add(i, 1)
            } {
                sstore(
                    // write index i to nodes.slot + i + 1
                    add(nodes.slot, add(1, i)),
                    // mload index i from nodesToPush.offset + (i * 0x20)
                    mload(
                        add(
                            nodesToPush,
                            // i * 0x20
                            shl(5, i)
                        )
                    )
                )
            }
        }
    }

    function _read(
        uint256[] storage nodes,
        uint256 index
    ) internal view returns (uint256 node) {
        assembly {
            // heap-nodes are 1-indexed, so no need to add 1 to index
            node := sload(add(nodes.slot, index))
        }
    }

    function _readMany(
        Heap storage heap,
        uint256 fromIndex,
        uint256 toIndex
    ) internal view returns (uint256[] memory) {
        uint256[] storage nodes = heap.nodes;
        uint256 _size = nodes.length;

        if (_size == 0) {
            return new uint[](0);
        }

        if (fromIndex > _size) {
            revert MinHeap__InvalidIndex();
        }
        if (toIndex > _size) {
            unchecked {
                toIndex = _size;
            }
        }


        uint256 count = toIndex - fromIndex + 1;

        uint256[] memory values = new uint[](count);
        uint256 valuesIndex = 0;
        do {
            uint256 value = _read(nodes, fromIndex);

            unchecked {
                values[valuesIndex] = value;
                ++valuesIndex;
                ++fromIndex;
            }
        } while (fromIndex < toIndex + 1);

        return values;
    }

    function _update(
        uint256[] storage nodes,
        uint256 index,
        uint256 node
    ) private {
        assembly {
            sstore(add(nodes.slot, index), node)
        }
    }

    function _pop(
        uint256[] storage nodes
    ) private returns (uint256 minNode, uint256 newLength) {
        assembly {
            // get old length
            let oldLength := sload(nodes.slot)
            // get slot of last node
            let lastNodeSlot := add(nodes.slot, oldLength)
            // get last node
            let lastNode := sload(lastNodeSlot)
            // decrement length
            newLength := sub(oldLength, 1)
            // store new length
            sstore(nodes.slot, newLength)
            // get slot of first node
            let firstNodeSlot := add(nodes.slot, 1)
            // load first node, which we are replacing
            minNode := sload(firstNodeSlot)
            // write last node to first position
            sstore(firstNodeSlot, lastNode)
            // overwrite last node with 0
            // only necessary when length is 0, and to clean up storage
            sstore(lastNodeSlot, 0)
        }
    }

    function insert(Heap storage heap, uint256 node) internal {
        if (heap.values[node] == true) revert MinHeap__AlreadyExists();
        uint256[] storage nodes = heap.nodes;
        _push(nodes, node);
        percUp(nodes, nodes.length);
        heap.values[node] = true;
    }

    function percUp(uint256[] storage nodes, uint256 _size) private {
        uint256 i = _size;
        uint256 parentIndex = i >> 1;
        while (parentIndex > 0) {
            uint256 node = _read(nodes, i);
            uint256 parent = _read(nodes, parentIndex);
            if (node < parent) {
                uint256 tmp = parent;
                _update(nodes, parentIndex, node);
                _update(nodes, i, tmp);
            }
            i = parentIndex;
            parentIndex = i >> 1;
        }
    }

    function percDown(
        uint256[] storage nodes,
        uint256 startIndex,
        uint256 _size
    ) private {
        uint256 i = startIndex;
        uint256 minChildIndex = i << 1;
        while (minChildIndex <= _size) {
            uint256 node = _read(nodes, i);
            uint256 child = _read(nodes, minChildIndex);
            // no realistic chance of overflow
            unchecked {
                if (minChildIndex + 1 <= _size) {
                    uint256 rightChild = _read(nodes, minChildIndex + 1);
                    if (rightChild < child) {
                        child = rightChild;
                        minChildIndex = minChildIndex + 1;
                    }
                }
            }
            if (node > child) {
                uint256 tmp = child;
                _update(nodes, minChildIndex, node);
                _update(nodes, i, tmp);
            }
            i = minChildIndex;
            minChildIndex = i << 1;
        }
    }

    function pop(Heap storage heap) internal returns (uint256) {
        uint256[] storage nodes = heap.nodes;

        uint256 _size = nodes.length;
        if (_size == 0) {
            revert MinHeap__Empty();
        }
        (uint256 val, uint256 newLength) = _pop(nodes);
        percDown({nodes: nodes, startIndex: 1, _size: newLength});
        heap.values[val] = false;
        return val;
    }

    function peek(Heap storage heap) internal view returns (uint256) {
        uint256[] storage nodes = heap.nodes;

        uint256 _size = nodes.length;
        if (_size == 0) {
            revert MinHeap__Empty();
        }
        return _read(nodes, 1);
    }
}