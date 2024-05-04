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

import "./ERC/ERC173.sol";
import "./ERC/ERC165.sol";
import "./Interfaces/IERC173.sol";
import "./Interfaces/IERC20.sol";
import "./Interfaces/IERC721.sol";

contract Marketplace is ERC173 {
    error InvalidArrayLength();
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

    // index > nftId
    mapping(address => uint256[]) public wrapped;
    // collection > count
    mapping(address => mapping(uint256 => uint256)) public wrappedIndex;
    // collection => price
    mapping(address => uint256) public collectionPrice;
    // collection => nftId => wallet
    mapping(address => mapping(uint256 => address)) public reservationOwner;
    // collection => nftId => date
    mapping(address => mapping(uint256 => uint256)) public reservationEndPeriod;
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

        uint256 index = 0;
        uint256 nftIdsLength = nftIds.length;
        do {
            uint256 tokenId = nftIds[index];
            nft.transferFrom(msg.sender, address(this), tokenId);
            insertToWrapped(collection, tokenId);

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

    function unwrap(address collection, uint256[] calldata nftIds) external {
        uint256 price = collectionPrice[collection];

        if (price == 0) {
            revert UnsupportedCollection();
        }

        uint256 nftIdsLength = nftIds.length;

        if (nftIdsLength == 0) {
            revert InvalidArrayLength();
        }

        if (nftIdsLength > wrapped[collection].length) {
            revert InsufficientNftAmount();
        }

        IERC721 nft = IERC721(collection);
        paymentToken.transferFrom(
            msg.sender,
            tokenSupplier,
            price * nftIdsLength
        );

        uint256 index = 0;
        do {
            uint256 tokenId = nftIds[index];
            nft.transferFrom(address(this), msg.sender, tokenId);
            removeFromWrapped(collection, tokenId);
            emit Unwrapped(collection, tokenId);
            unchecked {
                ++index;
            }
        } while (index < nftIdsLength);
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

        do {
            uint256 tokenId = nftIds[index];

            if (reservationEndPeriod[collection][tokenId] > block.timestamp)
                revert ReservationTimeNotExceed();

            address _owner = reservationOwner[collection][tokenId];

            removeReservationFromStorage(collection, _owner, tokenId);
            insertToWrapped(collection, tokenId);

            emit MovedToMarket(collection, tokenId);

            unchecked {
                ++index;
            }
        } while (index < nftIdsLength);
    }

    function insertToWrapped(address collection, uint256 tokenId) internal {
        wrappedIndex[collection][tokenId] = wrapped[collection].length;
        wrapped[collection].push(tokenId);
    }

    function removeFromWrapped(address collection, uint256 tokenId) internal {
        uint256 tokenIndex = wrappedIndex[collection][tokenId];
        uint256 lastTokenIndex = wrapped[collection].length - 1;

        uint256 lastTokenId = wrapped[collection][lastTokenIndex];

        wrapped[collection][tokenIndex] = lastTokenId;
        wrappedIndex[collection][lastTokenId] = tokenIndex;

        delete wrappedIndex[collection][tokenId];
        wrapped[collection].pop();
    }

    function wrappedCount(address collection) external view returns (uint256) {
        if (collectionPrice[collection] == 0) {
            revert UnsupportedCollection();
        }

        return wrapped[collection].length;
    }

    function wrappedNfts(
        address collection,
        uint256 fromIndex,
        uint256 count
    ) external view returns (uint256[] memory) {
        uint256 _totalCount = wrapped[collection].length;

        if (_totalCount == 0) {
            return new uint256[](0);
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

        uint256[] memory _nftIds = new uint256[](count);
        uint256 index = 0;
        do {
            uint256 tokenId = wrapped[collection][fromIndex];

            unchecked {
                _nftIds[index] = tokenId;

                ++fromIndex;
                ++index;
            }
        } while (index < count);

        return _nftIds;
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