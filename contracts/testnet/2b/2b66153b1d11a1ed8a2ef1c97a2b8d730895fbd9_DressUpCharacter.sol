// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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
contract ERC721A is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

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
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
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
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) _revert(BalanceQueryForZeroAddress.selector);
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Returns whether the ownership slot at `index` is initialized.
     * An uninitialized slot does not necessarily mean that the slot has no owner.
     */
    function _ownershipIsInitialized(uint256 index) internal view virtual returns (bool) {
        return _packedOwnerships[index] != 0;
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256 packed) {
        if (_startTokenId() <= tokenId) {
            packed = _packedOwnerships[tokenId];
            // If the data at the starting slot does not exist, start the scan.
            if (packed == 0) {
                if (tokenId >= _currentIndex) _revert(OwnerQueryForNonexistentToken.selector);
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
                        packed = _packedOwnerships[--tokenId];
                    }
                    if (packed == 0) continue;
                    if (packed & _BITMASK_BURNED == 0) return packed;
                    // Otherwise, the token is burned, and we must revert.
                    // This handles the case of batch burned tokens, where only the burned bit
                    // of the starting slot is set, and remaining slots are left uninitialized.
                    _revert(OwnerQueryForNonexistentToken.selector);
                }
            }
            // Otherwise, the data exists and we can skip the scan.
            // This is possible because we have already achieved the target condition.
            // This saves 2143 gas on transfers of initialized tokens.
            // If the token is not burned, return `packed`. Otherwise, revert.
            if (packed & _BITMASK_BURNED == 0) return packed;
        }
        _revert(OwnerQueryForNonexistentToken.selector);
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
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
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
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
     * @dev Gives permission to `to` to transfer `tokenId` token to another account. See {ERC721A-_approve}.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        _approve(to, tokenId, true);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) _revert(ApprovalQueryForNonexistentToken.selector);

        return _tokenApprovals[tokenId].value;
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
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool result) {
        if (_startTokenId() <= tokenId) {
            if (tokenId < _currentIndex) {
                uint256 packed;
                while ((packed = _packedOwnerships[tokenId]) == 0) --tokenId;
                result = packed & _BITMASK_BURNED == 0;
            }
        }
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
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
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
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

        // Mask `from` to the lower 160 bits, in case the upper bits somehow aren't clean.
        from = address(uint160(uint256(uint160(from)) & _BITMASK_ADDRESS));

        if (address(uint160(prevOwnershipPacked)) != from) _revert(TransferFromIncorrectOwner.selector);

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) _revert(TransferCallerNotOwnerNorApproved.selector);

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
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
        uint256 toMasked = uint256(uint160(to)) & _BITMASK_ADDRESS;
        assembly {
            // Emit the `Transfer` event.
            log4(
                0, // Start of data (0, since no data).
                0, // End of data (0, since no data).
                _TRANSFER_EVENT_SIGNATURE, // Signature.
                from, // `from`.
                toMasked, // `to`.
                tokenId // `tokenId`.
            )
        }
        if (toMasked == 0) _revert(TransferToZeroAddress.selector);

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
        safeTransferFrom(from, to, tokenId, '');
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
                _revert(TransferToNonERC721ReceiverImplementer.selector);
            }
    }

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
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                _revert(TransferToNonERC721ReceiverImplementer.selector);
            }
            assembly {
                revert(add(32, reason), mload(reason))
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
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) _revert(MintZeroQuantity.selector);

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
            uint256 toMasked = uint256(uint160(to)) & _BITMASK_ADDRESS;

            if (toMasked == 0) _revert(MintToZeroAddress.selector);

            uint256 end = startTokenId + quantity;
            uint256 tokenId = startTokenId;

            do {
                assembly {
                    // Emit the `Transfer` event.
                    log4(
                        0, // Start of data (0, since no data).
                        0, // End of data (0, since no data).
                        _TRANSFER_EVENT_SIGNATURE, // Signature.
                        0, // `address(0)`.
                        toMasked, // `to`.
                        tokenId // `tokenId`.
                    )
                }
                // The `!=` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
            } while (++tokenId != end);

            _currentIndex = end;
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
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) _revert(MintToZeroAddress.selector);
        if (quantity == 0) _revert(MintZeroQuantity.selector);
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) _revert(MintERC2309QuantityExceedsLimit.selector);

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
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
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        _revert(TransferToNonERC721ReceiverImplementer.selector);
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) _revert(bytes4(0));
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                       APPROVAL OPERATIONS
    // =============================================================

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
        address owner = ownerOf(tokenId);

        if (approvalCheck && _msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                _revert(ApprovalCallerNotOwnerNorApproved.selector);
            }

        _tokenApprovals[tokenId].value = to;
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

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) _revert(TransferCallerNotOwnerNorApproved.selector);
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

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
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) _revert(OwnershipNotInitializedForExtraData.selector);
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
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
    ) private view returns (uint256) {
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
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
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

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
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
    //                            STRUCTS
    // =============================================================

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
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library to encode strings in Base64.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Base64.sol)
/// @author Modified from (https://github.com/Brechtpd/base64/blob/main/base64.sol) by Brecht Devos - <[email protected]>.
library Base64 {
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    function encode(bytes memory data, bool fileSafe, bool noPadding)
        internal
        pure
        returns (string memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                // Multiply by 4/3 rounded up.
                // The `shl(2, ...)` is equivalent to multiplying by 4.
                let encodedLength := shl(2, div(add(dataLength, 2), 3))

                // Set `result` to point to the start of the free memory.
                result := mload(0x40)

                // Store the table into the scratch space.
                // Offsetted by -1 byte so that the `mload` will load the character.
                // We will rewrite the free memory pointer at `0x40` later with
                // the allocated size.
                // The magic constant 0x0230 will translate "-_" + "+/".
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, sub("ghijklmnopqrstuvwxyz0123456789-_", mul(iszero(fileSafe), 0x0230)))

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, encodedLength)

                // Run over the input, 3 bytes at a time.
                for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(0, mload(and(shr(18, input), 0x3F)))
                    mstore8(1, mload(and(shr(12, input), 0x3F)))
                    mstore8(2, mload(and(shr(6, input), 0x3F)))
                    mstore8(3, mload(and(input, 0x3F)))
                    mstore(ptr, mload(0x00))

                    ptr := add(ptr, 4) // Advance 4 bytes.

                    if iszero(lt(ptr, end)) { break }
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))

                // Equivalent to `o = [0, 2, 1][dataLength % 3]`.
                let o := div(2, mod(dataLength, 3))

                // Offset `ptr` and pad with '='. We can simply write over the end.
                mstore(sub(ptr, o), shl(240, 0x3d3d))
                // Set `o` to zero if there is padding.
                o := mul(iszero(iszero(noPadding)), o)
                // Zeroize the slot after the string.
                mstore(sub(ptr, o), 0)
                // Write the length of the string.
                mstore(result, sub(encodedLength, o))
            }
        }
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, false, false)`.
    function encode(bytes memory data) internal pure returns (string memory result) {
        result = encode(data, false, false);
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, fileSafe, false)`.
    function encode(bytes memory data, bool fileSafe)
        internal
        pure
        returns (string memory result)
    {
        result = encode(data, fileSafe, false);
    }

    /// @dev Decodes base64 encoded `data`.
    ///
    /// Supports:
    /// - RFC 4648 (both standard and file-safe mode).
    /// - RFC 3501 (63: ',').
    ///
    /// Does not support:
    /// - Line breaks.
    ///
    /// Note: For performance reasons,
    /// this function will NOT revert on invalid `data` inputs.
    /// Outputs for invalid inputs will simply be undefined behaviour.
    /// It is the user's responsibility to ensure that the `data`
    /// is a valid base64 encoded string.
    function decode(string memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                let decodedLength := mul(shr(2, dataLength), 3)

                for {} 1 {} {
                    // If padded.
                    if iszero(and(dataLength, 3)) {
                        let t := xor(mload(add(data, dataLength)), 0x3d3d)
                        // forgefmt: disable-next-item
                        decodedLength := sub(
                            decodedLength,
                            add(iszero(byte(30, t)), iszero(byte(31, t)))
                        )
                        break
                    }
                    // If non-padded.
                    decodedLength := add(decodedLength, sub(and(dataLength, 3), 1))
                    break
                }
                result := mload(0x40)

                // Write the length of the bytes.
                mstore(result, decodedLength)

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, decodedLength)

                // Load the table into the scratch space.
                // Constants are optimized for smaller bytecode with zero gas overhead.
                // `m` also doubles as the mask of the upper 6 bits.
                let m := 0xfc000000fc00686c7074787c8084888c9094989ca0a4a8acb0b4b8bcc0c4c8cc
                mstore(0x5b, m)
                mstore(0x3b, 0x04080c1014181c2024282c3034383c4044484c5054585c6064)
                mstore(0x1a, 0xf8fcf800fcd0d4d8dce0e4e8ecf0f4)

                for {} 1 {} {
                    // Read 4 bytes.
                    data := add(data, 4)
                    let input := mload(data)

                    // Write 3 bytes.
                    // forgefmt: disable-next-item
                    mstore(ptr, or(
                        and(m, mload(byte(28, input))),
                        shr(6, or(
                            and(m, mload(byte(29, input))),
                            shr(6, or(
                                and(m, mload(byte(30, input))),
                                shr(6, mload(byte(31, input)))
                            ))
                        ))
                    ))

                    ptr := add(ptr, 3)

                    if iszero(lt(ptr, end)) { break }
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))
                // Zeroize the slot after the bytes.
                mstore(end, 0)
                // Restore the zero slot.
                mstore(0x60, 0)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solady (https://github.com/vectorized/solmady/blob/main/src/utils/SSTORE2.sol)
/// @author Saw-mon-and-Natalie (https://github.com/Saw-mon-and-Natalie)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev We skip the first byte as it's a STOP opcode,
    /// which ensures the contract can't be called.
    uint256 internal constant DATA_OFFSET = 1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to deploy the storage contract.
    error DeploymentFailed();

    /// @dev The storage contract address is invalid.
    error InvalidPointer();

    /// @dev Attempt to read outside of the storage contract's bytecode bounds.
    error ReadOutOfBounds();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         WRITE LOGIC                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Writes `data` into the bytecode of a storage contract and returns its address.
    function write(bytes memory data) internal returns (address pointer) {
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)

            // Add 1 to data size since we are prefixing it with a STOP opcode.
            let dataSize := add(originalDataLength, DATA_OFFSET)

            /**
             * ------------------------------------------------------------------------------+
             * Opcode      | Mnemonic        | Stack                   | Memory              |
             * ------------------------------------------------------------------------------|
             * 61 codeSize | PUSH2 codeSize  | codeSize                |                     |
             * 80          | DUP1            | codeSize codeSize       |                     |
             * 60 0xa      | PUSH1 0xa       | 0xa codeSize codeSize   |                     |
             * 3D          | RETURNDATASIZE  | 0 0xa codeSize codeSize |                     |
             * 39          | CODECOPY        | codeSize                | [0..codeSize): code |
             * 3D          | RETURNDATASIZE  | 0 codeSize              | [0..codeSize): code |
             * F3          | RETURN          |                         | [0..codeSize): code |
             * 00          | STOP            |                         |                     |
             * ------------------------------------------------------------------------------+
             * @dev Prefix the bytecode with a STOP opcode to ensure it cannot be called.
             * Also PUSH2 is used since max contract size cap is 24,576 bytes which is less than 2 ** 16.
             */
            mstore(
                data,
                or(
                    0x61000080600a3d393df300,
                    // Left shift `dataSize` by 64 so that it lines up with the 0000 after PUSH2.
                    shl(0x40, dataSize)
                )
            )

            // Deploy a new contract with the generated creation code.
            pointer := create(0, add(data, 0x15), add(dataSize, 0xa))

            // If `pointer` is zero, revert.
            if iszero(pointer) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /// @dev Writes `data` into the bytecode of a storage contract with `salt`
    /// and returns its deterministic address.
    function writeDeterministic(bytes memory data, bytes32 salt)
        internal
        returns (address pointer)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)
            let dataSize := add(originalDataLength, DATA_OFFSET)

            mstore(data, or(0x61000080600a3d393df300, shl(0x40, dataSize)))

            // Deploy a new contract with the generated creation code.
            pointer := create2(0, add(data, 0x15), add(dataSize, 0xa), salt)

            // If `pointer` is zero, revert.
            if iszero(pointer) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /// @dev Returns the initialization code hash of the storage contract for `data`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash(bytes memory data) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)
            let dataSize := add(originalDataLength, DATA_OFFSET)

            mstore(data, or(0x61000080600a3d393df300, shl(0x40, dataSize)))

            hash := keccak256(add(data, 0x15), add(dataSize, 0xa))

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /// @dev Returns the address of the storage contract for `data`
    /// deployed with `salt` by `deployer`.
    function predictDeterministicAddress(bytes memory data, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        bytes32 hash = initCodeHash(data);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         READ LOGIC                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns all the `data` from the bytecode of the storage contract at `pointer`.
    function read(address pointer) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Offset all indices by 1 to skip the STOP opcode.
            let size := sub(pointerCodesize, DATA_OFFSET)

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), DATA_OFFSET, size)
        }
    }

    /// @dev Returns the `data` from the bytecode of the storage contract at `pointer`,
    /// from the byte at `start`, to the end of the data stored.
    function read(address pointer, uint256 start) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If `!(pointer.code.size > start)`, reverts.
            // This also handles the case where `start + DATA_OFFSET` overflows.
            if iszero(gt(pointerCodesize, start)) {
                // Store the function selector of `ReadOutOfBounds()`.
                mstore(0x00, 0x84eb0dd1)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            let size := sub(pointerCodesize, add(start, DATA_OFFSET))

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), add(start, DATA_OFFSET), size)
        }
    }

    /// @dev Returns the `data` from the bytecode of the storage contract at `pointer`,
    /// from the byte at `start`, to the byte at `end` (exclusive) of the data stored.
    function read(address pointer, uint256 start, uint256 end)
        internal
        view
        returns (bytes memory data)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If `!(pointer.code.size > end) || (start > end)`, revert.
            // This also handles the cases where
            // `end + DATA_OFFSET` or `start + DATA_OFFSET` overflows.
            if iszero(
                and(
                    gt(pointerCodesize, end), // Within bounds.
                    iszero(gt(start, end)) // Valid range.
                )
            ) {
                // Store the function selector of `ReadOutOfBounds()`.
                mstore(0x00, 0x84eb0dd1)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            let size := sub(end, start)

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), add(start, DATA_OFFSET), size)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ImageDataHandler} from "./lib/ImageDataHandler.sol";
import {PersonalityHandler} from "./lib/PersonalityHandler.sol";

interface ITokenURI {
    function createCharacterDataURI(uint256 characterData, bytes32 personalityData, uint256 status)
        external
        view
        returns (string memory);
}

contract DressUpCharacter is Ownable, ERC721A, ImageDataHandler, PersonalityHandler {
    using Strings for uint256;

    error NotOwner();
    // error IncorrectValue();

    address public storageContractAddress;
    mapping(uint256 => uint256) public icon;

    constructor() ERC721A("CreatorHeroesCharacter", "CHC") {}

    /// @dev set StructureDatas[tokenId] = characterDatas / partsDatas
    /// structureDatas = uint16 parts / ... / uint16 parts / uint16 length
    /// [attention]Not checked to see if it's something I can set.
    /// @dev set personalityDatas[tokenId] = personalityData / status
    /// personalityData = string[30bytes] / uint8      / [1bytes]
    ///                   name            / character  / string.length
    /// @param imageIds array.length < 16
    /// @param name string / length < 31
    /// @param personality < 16
    /// @param status uint256
    function mint(uint256[] memory imageIds, string memory name, uint256 personality, uint256 status)
        external
        payable
    {
        uint256 tokenId = _nextTokenId();

        // set StructureDatas[tokenId]
        _checkCategolyId(imageIds, 0);
        _setStructureData(tokenId, imageIds, 0);

        // set personalityDatas
        _setPersonalityData(tokenId, name, personality, status);

        _mint(msg.sender, 1);
    }

    function setStorageContractAddress(address newStorageContractAddress) public onlyOwner {
        storageContractAddress = newStorageContractAddress;
    }

    // // ownerOnly
    // function changeIcon(uint256 tokenId) public {
    //     if (ownerOf(tokenId) != msg.sender) revert NotOwner();
    //     icon[tokenId] = ~icon[tokenId] & 1;
    // }

    /* /////////////////////////////////////////////////////////////////////////////
    ERC721A
    ///////////////////////////////////////////////////////////////////////////// */

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        if (tokenId > totalSupply()) revert IncorrectValue();

        // essence
        uint256 characterData = _getStructureData(tokenId, 16, 0);
        (bytes32 personalityData, uint256 status) = _getPersonalityData(tokenId);

        return ITokenURI(storageContractAddress).createCharacterDataURI(characterData, personalityData, status);
    }

    /* /////////////////////////////////////////////////////////////////////////////
    For test
    ///////////////////////////////////////////////////////////////////////////// */

    function getStructureData(uint256 tokenId) public view returns (uint256) {
        return _getStructureData(tokenId, 16, 0);
    }

    function getPersonalityData(uint256 tokenId) public view returns (bytes32 personalityData, uint256 status) {
        return _getPersonalityData(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {SSTORE2} from "solady/utils/SSTORE2.sol";
import {Base64} from "solady/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {LibBase64} from "contracts/lib/LibBase64.sol";

abstract contract ImageDataHandler {
    using SSTORE2 for bytes;
    using SSTORE2 for address;
    using Strings for uint256;
    using Strings for string;

    uint256 private constant _MASK_UINT8 = (1 << 8) - 1;
    uint256 private constant _MASK_UINT16 = (1 << 16) - 1;

    // _IMAGE_DATAS / _CHARACTER_DATAS_SEED / _TRANSFORM_DATAS / _STYLE_DATAS_SEED
    uint256 private constant _CHARACTER_DATAS_SEED = 0xfbbce30ee466491e8e2a671f95d3935e;

    // _IMAGE_DATAS / _PARTS_DATAS_SEED / _TRANSFORM_DATAS / _STYLE_DATAS_SEED
    uint256 private constant _PARTS_DATAS_SEED = 0xfbbce30e05e534fb8e2a671f95d3935e;

    // string _prefixDataURI = "data:image/svg+xml;utf8,";
    // string _prefix = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">';
    // string _suffix = "</svg>";

    // string _prefixStyle = '<style type="text/css">';
    // string _suffixStyle = "</style>";

    // string _prefixIcon =
    //     '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" preserveAspectRatio="xMidYMid slice"><clipPath id="mark"><circle cx="500" cy="500" r="250" fill="#000"></circle></clipPath>';
    // string _suffixGrope = "</symbol>";

    // string _useContentConcat =
    //     '<use href="#3" x="0" y="0"/><use href="#4" x="0" y="0"/><use href="#5" x="0" y="0"/><use href="#6" x="0" y="0"/><use href="#7" x="0" y="0"/><use href="#8" x="0" y="0"/>';

    modifier onlyMultiple3(bytes memory data) {
        LibBase64.checkStringLength(data);
        _;
    }

    /* /////////////////////////////////////////////////////////////////////////////
    Error
    ///////////////////////////////////////////////////////////////////////////// */

    /// @dev
    error IncorrectValue();

    /// @dev Argument types do not match.`0xb4902a13`
    error TypeMismatch();

    /// @dev Array length is incorrect.`0x3be6499c`
    error IncorrectArrayLength();

    /// @dev Not available due to default index.`0x27324a04`
    error NotAvailableDefaultIndex();

    /// @dev String length must be a multiple of 3.`0x9959fc03`
    error StringLengthNotMultiple3();

    /* /////////////////////////////////////////////////////////////////////////////
    IMAGE_DATAS
    ///////////////////////////////////////////////////////////////////////////// */

    /// @dev set imageDatas[imageId] = imageData
    /// imageData = addres  / uint8      / uint16      / uint16  / uint56
    ///             pointer / categoryId / transformId / styleId / blank
    ///             pointer / categoryId / tokenId     / blank   / blank
    /// @param data bytes onlyMultiple3(base64 encoded) => address(SSTORE2)
    /// @param categoryId uint8
    /// @param transformId uint16
    /// @param styleId uint16
    function _setImageData(uint256 imageId, bytes memory data, uint256 categoryId, uint256 transformId, uint256 styleId)
        internal
        onlyMultiple3(data)
    {
        address pointer = data.write();

        assembly {
            // check uint8
            if lt(255, categoryId) {
                mstore(0x00, 0xb4902a13) // `TypeMismatch()`
                revert(0x1c, 0x04)
            }

            // check uint16
            if lt(65535, transformId) {
                mstore(0x00, 0xb4902a13) // `TypeMismatch()`
                revert(0x1c, 0x04)
            }

            // check uint16
            if lt(65535, styleId) {
                mstore(0x00, 0xb4902a13) // `TypeMismatch()`
                revert(0x1c, 0x04)
            }

            categoryId := and(categoryId, _MASK_UINT8)
            transformId := and(transformId, _MASK_UINT16)
            styleId := and(styleId, _MASK_UINT16)

            let imageData := or(or(or(shl(96, pointer), shl(88, categoryId)), shl(72, transformId)), shl(56, styleId))

            // write to storage
            mstore(0x16, _CHARACTER_DATAS_SEED)
            mstore(0x00, imageId)
            sstore(keccak256(0x00, 0x24), imageData)
        }
    }

    /// @dev update imageDatas[imageId] = imageData
    /// imageData = addres  / uint8      / uint16      / uint16  / uint56
    ///             pointer / categoryId / transformId / styleId / blank
    /// @param pointer address(SSTORE2)
    /// @param categoryId uint8
    /// @param transformId uint16
    /// @param styleId uint16
    function _updateImageData(
        uint256 imageId,
        address pointer,
        uint256 categoryId,
        uint256 transformId,
        uint256 styleId
    ) internal {
        assembly {
            // check uint8
            if lt(255, categoryId) {
                mstore(0x00, 0xb4902a13) // `TypeMismatch()`
                revert(0x1c, 0x04)
            }

            // check uint16
            if lt(65535, transformId) {
                mstore(0x00, 0xb4902a13) // `TypeMismatch()`
                revert(0x1c, 0x04)
            }

            // check uint16
            if lt(65535, styleId) {
                mstore(0x00, 0xb4902a13) // `TypeMismatch()`
                revert(0x1c, 0x04)
            }

            categoryId := and(categoryId, _MASK_UINT8)
            transformId := and(transformId, _MASK_UINT16)
            styleId := and(styleId, _MASK_UINT16)

            let imageData := or(or(or(shl(96, pointer), shl(88, categoryId)), shl(72, transformId)), shl(56, styleId))

            // write to storage
            mstore(0x16, _CHARACTER_DATAS_SEED)
            mstore(0x00, imageId)
            sstore(keccak256(0x00, 0x24), imageData)
        }
    }

    /// @dev get imageDatas[imageId]
    /// imageData = addres  / uint8      / uint16      / uint16  / uint56
    ///             pointer / categoryId / transformId / styleId / blank
    /// @param pointer address(SSTORE2)
    /// @param categoryId uint8
    /// @param transformId uint16
    /// @param styleId uint16
    function getImageData(uint256 imageId)
        public
        view
        returns (address pointer, uint256 categoryId, uint256 transformId, uint256 styleId)
    {
        assembly {
            // read to storage
            mstore(0x16, _CHARACTER_DATAS_SEED)
            mstore(0x00, imageId)
            let value := sload(keccak256(0x00, 0x24))

            pointer := shr(96, value)
            categoryId := and(_MASK_UINT8, shr(88, value))
            transformId := and(_MASK_UINT16, shr(72, value))
            styleId := and(_MASK_UINT16, shr(56, value))
        }
    }

    /* /////////////////////////////////////////////////////////////////////////////
    CHARACTER_DATAS [slot = 0] / PARTS_DATAS [slot = 1]
    ///////////////////////////////////////////////////////////////////////////// */

    /// @dev set StructureDatas[tokenId] = characterDatas / partsDatas
    /// structureDatas = uint16 parts / ... / uint16 parts / uint16 length
    /// [attention]Not checked to see if it's something I can set.
    /// @param imageIds array.length < 16
    /// @param slot characterDatas [slot = 0] / partsDatas [slot = 1]
    function _setStructureData(uint256 tokenId, uint256[] memory imageIds, uint256 slot) internal {
        assembly {
            let packed := mload(imageIds)

            // imageIds.length <= 15
            if lt(15, packed) {
                mstore(0x00, 0x3be6499c) // `IncorrectArrayLength()`
                revert(0x1c, 0x04)
            }

            for {
                // loop setting
                let cc := 0
                let ptr := add(imageIds, 0x20)
                let last := packed
            } lt(cc, last) {
                cc := add(cc, 1)
                ptr := add(ptr, 0x20)
            } {
                // packed = imageId / imageId / imageId / ... / imageIds.length
                packed := or(packed, shl(mul(add(cc, 1), 16), and(mload(ptr), _MASK_UINT16)))
            }

            // write to storage
            mstore(0x12, add(_CHARACTER_DATAS_SEED, iszero(iszero(slot))))
            mstore(0x00, tokenId)
            sstore(keccak256(0x00, 0x24), packed)
        }
    }

    /// @dev check imageIds.index === categoryId
    /// @param imageIds 0 < array.length < 16
    /// @param slot special character [slot = 0] / battle character [slot = 1]
    function _checkCategolyId(uint256[] memory imageIds, uint256 slot) internal view {
        assembly {
            let len := mload(imageIds)
            for {
                let offset := mul(10, iszero(iszero(slot)))
                // loop setting
                let cc := offset
                let ptr := add(imageIds, 0x20)
                let last := add(len, offset)
            } lt(cc, last) {
                cc := add(cc, 1)
                ptr := add(ptr, 0x20)
            } {
                let value := mload(ptr)

                if iszero(iszero(value)) {
                    // read to storage
                    mstore(0x16, _CHARACTER_DATAS_SEED)
                    mstore(0x00, value)
                    value := sload(keccak256(0x00, 0x24))

                    let categoryId := and(_MASK_UINT8, shr(88, value))

                    if categoryId {
                        if iszero(eq(categoryId, cc)) {
                            mstore(0x00, 0xd2ade556) // `IncorrectValue()`
                            revert(0x1c, 0x04)
                        }
                    }
                }
            }
        }
    }

    /// @dev get structureDatas[tokenId]
    /// characterData = uint16 parts / ... / uint16 parts / uint16 length
    /// @param index index < 15 --> target imageId / 16 --> characterId
    /// @param slot characterDatas [slot = 0] / partsDatas [slot = 1]
    /// @return value index < 15 --> target imageId / 16 --> characterId
    function _getStructureData(uint256 tokenId, uint256 index, uint256 slot) internal view returns (uint256 value) {
        assembly {
            // read to storage
            mstore(0x12, add(_CHARACTER_DATAS_SEED, iszero(iszero(slot))))
            mstore(0x00, tokenId)
            value := sload(keccak256(0x00, 0x24))

            if iszero(eq(index, 16)) { value := and(_MASK_UINT16, shr(mul(index, 16), value)) }
        }
    }

    /* /////////////////////////////////////////////////////////////////////////////
    _TRANSFORM_DATAS [slot = 0] / _STYLE_DATAS_SEED [slot = 1]
    ///////////////////////////////////////////////////////////////////////////// */

    /// @dev set OptionDatas[optionId] = transformDatas / styleDatas
    /// @param optionId uint16 (Because uint16 transformId / uint16 styleId)
    /// Not available due to default index 0.
    /// 0 < optionId < 65536
    /// @param data bytes onlyMultiple3(base64 encoded) => address(SSTORE2)
    /// @param slot transformDatas [slot = 0] / styleDatas [slot = 1]
    function _setOptionData(uint256 optionId, bytes memory data, uint256 slot) internal onlyMultiple3(data) {
        assembly {
            // check uint16
            if iszero(optionId) {
                mstore(0x00, 0x27324a04) // `NotAvailableDefaultIndex()`
                revert(0x1c, 0x04)
            }

            // check uint16
            if lt(65535, optionId) {
                mstore(0x00, 0xb4902a13) // `TypeMismatch()`
                revert(0x1c, 0x04)
            }

            slot := mul(0x04, add(iszero(slot), 1))
            mstore(slot, _CHARACTER_DATAS_SEED)
            mstore(0x00, optionId)
            slot := keccak256(0x00, 0x24)

            let len := mload(data)

            switch lt(len, 32)
            // length < 32
            case 1 {
                // (value & length) set to slot
                sstore(slot, add(mload(add(data, 0x20)), mul(len, 2)))
            }
            // length >= 32
            default {
                // length info set to slot
                sstore(slot, add(mul(len, 2), 1))

                // key
                mstore(0x0, slot)
                let sc := keccak256(0x00, 0x20)

                // value set
                for {
                    let mc := add(data, 0x20)
                    let end := add(mc, len)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } { sstore(sc, mload(mc)) }
            }
        }
    }

    /// @dev OptionDatas[optionId]
    /// @param optionId uint16 (Because uint16 transformId / uint16 styleId)
    /// @param slot transformDatas [slot = 0] / styleDatas [slot = 1]
    function getOptionData(uint256 optionId, uint256 slot) public view returns (string memory data) {
        assembly {
            // free memory pointer
            data := mload(0x40)

            slot := mul(0x04, add(iszero(slot), 1))
            mstore(slot, _CHARACTER_DATAS_SEED)
            mstore(0x00, optionId)
            slot := keccak256(0x00, 0x24)

            let value := sload(slot)
            let len := div(and(value, sub(mul(0x100, iszero(and(value, 1))), 1)), 2)
            let mc := add(data, 0x20)

            // set length
            mstore(data, len)

            // set value
            switch lt(len, 32)
            // length < 32
            case 1 { mstore(mc, value) }
            // length >= 32
            default {
                // key
                mstore(0x0, slot)
                let sc := keccak256(0x00, 0x20)

                for { let end := add(mc, len) } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } { mstore(mc, sload(sc)) }
            }

            mstore(0x40, and(add(add(mc, len), 31), not(31)))
        }
    }

    /* /////////////////////////////////////////////////////////////////////////////
    SVG render
    ///////////////////////////////////////////////////////////////////////////// */
    /// @dev get svg data
    /// @param slot characterDatas [slot = 0] / partsDatas [slot = 1]
    function _render(uint256 characterData, uint256 slot) internal view returns (string memory result) {
        assembly {
            /// @dev uint to String
            /// @param sp start pointer
            /// @param x uint16
            /// @return	ep end pointer
            function encode64(sp, x) -> ep {
                // use scratch space
                let ss := 0x20
                for {} 1 {} {
                    ss := sub(ss, 1)

                    mstore8(ss, add(48, mod(x, 10)))
                    x := div(x, 10)
                    if iszero(x) { break }
                }

                // padding '//'
                mstore(0x20, "//")
                let input := mload(ss)

                // base64 encode materials
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, "ghijklmnopqrstuvwxyz0123456789+/")

                // base64 encode
                for {} 1 { input := shl(24, input) } {
                    mstore8(0, mload(and(shr(250, input), 0x3F)))
                    mstore8(1, mload(and(shr(244, input), 0x3F)))
                    mstore8(2, mload(and(shr(238, input), 0x3F)))
                    mstore8(3, mload(and(shr(232, input), 0x3F)))
                    mstore(sp, mload(0x00))

                    sp := add(sp, 4)
                    ss := add(ss, 0x03)

                    if iszero(lt(ss, 0x20)) { break }
                }
                ep := sp
            }

            /// @dev get string in storage
            /// @param sp start pointer
            /// @param i index
            /// @param n 8 or 4 => _TRANSFORM_DATAS / _STYLE_DATAS_SEED
            /// @return	ep end pointer
            function getStr(sp, i, n) -> ep {
                mstore(n, _CHARACTER_DATAS_SEED)
                mstore(0x00, i)
                i := keccak256(0x00, 0x24)
                let v := sload(i)

                let len := div(and(v, sub(mul(0x100, iszero(and(v, 1))), 1)), 2)

                // set value
                switch lt(len, 32)
                // length < 32
                case 1 { mstore(sp, v) }
                // length >= 32
                default {
                    // key
                    mstore(0x00, i)
                    let sc := keccak256(0x00, 0x20)

                    for { let end := add(sp, len) } lt(sp, end) {
                        sc := add(sc, 1)
                        sp := add(sp, 0x20)
                    } { mstore(sp, sload(sc)) }
                }

                ep := add(sp, len)
            }

            // Set `ImageData` to point to the start of the free memory.
            let imageDataPtr := mload(0x40)

            // // getCharacterDatas(uint256 characterId, uint256 index, uint256 slot) --> (uint256 imageId)
            // mstore(0x12, add(_CHARACTER_DATAS_SEED, iszero(iszero(slot))))
            // mstore(0x00, tokenId)
            // let temp := sload(keccak256(0x00, 0x24))

            let temp := characterData

            // len
            let imageDataLen := and(_MASK_UINT16, temp)
            let index

            // memory counter
            let mc := imageDataPtr

            for { let i := 1 } 1 {
                mc := add(mc, 0x20)
                i := add(i, 1)
            } {
                // imageId
                index := and(_MASK_UINT16, shr(mul(i, 16), temp))

                mstore(0x16, _CHARACTER_DATAS_SEED)
                mstore(0x00, index)
                index := sload(keccak256(0x00, 0x24))

                mstore(mc, index)

                if iszero(lt(i, imageDataLen)) { break }
            }

            // free memory pointer
            mstore(0x40, add(mc, 0x20))

            // return data
            result := mload(0x40)

            // Skip the first slot, which stores the length.
            mc := add(result, 0x20)

            // // mstore(mc, 'data:image/svg+xml;base64,')
            // mstore(mc, "data%3Aimage%2Fsvg%2Bxml%3Bbase6")
            // mc := add(mc, 32)

            // mstore(mc, "4%2C")
            // mc := add(mc, 4)

            mstore(mc, "data:image/svg+xml;base64,")
            mc := add(mc, 26)

            // <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">
            mstore(mc, "PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53")
            mc := add(mc, 32)

            mstore(mc, "My5vcmcvMjAwMC9zdmciICAgdmlld0Jv")
            mc := add(mc, 32)

            mstore(mc, "eD0iMCAwIDEwMDAgMTAwMCI+")
            mc := add(mc, 24)

            // symbol
            for {
                let i := 0
                let cc
            } 1 { i := add(i, 1) } {
                // getTransformDatas(transformId)
                temp := mload(add(imageDataPtr, cc))

                if temp {
                    // <symbol id="
                    mstore(mc, "PHN5bWJvbCBpZD0i")
                    mc := add(mc, 16)

                    // transformId
                    index := and(_MASK_UINT8, shr(88, temp))
                    // i.toString
                    mc := encode64(mc, index)

                    // ">
                    mstore(mc, "IiA+")
                    mc := add(mc, 4)

                    // SSTORE2 pointer_.read()
                    temp := mload(add(imageDataPtr, cc))

                    // pointer
                    index := shr(96, temp)

                    let pointerCodesize := extcodesize(index)
                    if iszero(pointerCodesize) { pointerCodesize := 1 }

                    // Offset all indices by 1 to skip the STOP opcode.
                    let size := sub(pointerCodesize, 1)

                    extcodecopy(index, mc, 1, size)
                    mc := add(mc, size)

                    // </symbol>
                    mstore(mc, "PC9zeW1ib2w+")
                    mc := add(mc, 12)
                }
                cc := add(cc, 0x20)

                if iszero(lt(i, imageDataLen)) { break }
            }

            // style
            // <style type="text/css">
            mstore(mc, "PHN0eWxlIHR5cGU9InRleHQvY3NzIiA+")
            mc := add(mc, 32)

            for {
                let i := 0
                let cc
            } 1 {
                i := add(i, 1)
                cc := add(cc, 0x20)
            } {
                // _createStyle(styleId_)
                temp := mload(add(imageDataPtr, cc))
                // styleId
                index := and(_MASK_UINT16, shr(56, temp))

                // _getStyleDatas
                mc := getStr(mc, index, 0x04)

                if iszero(lt(i, imageDataLen)) { break }
            }

            // </style>
            mstore(mc, "IDwvc3R5bGU+")
            mc := add(mc, 12)

            // useContent
            for {
                let i := 0
                let cc
            } 1 { i := add(i, 1) } {
                temp := mload(add(imageDataPtr, cc))

                if temp {
                    // <use href="#
                    mstore(mc, "PHVzZSBocmVmPSIj")
                    mc := add(mc, 16)

                    // transformId
                    index := and(_MASK_UINT8, shr(88, temp))

                    // i.toString
                    mc := encode64(mc, index)

                    // " x="0" y="0" transform="
                    mstore(mc, "IiB4PSIwIiB5PSIwIiAgIHRyYW5zZm9y")
                    mc := add(mc, 32)

                    mstore(mc, "bT0i")
                    mc := add(mc, 4)

                    // getTransformDatas(transformId)
                    temp := mload(add(imageDataPtr, cc))

                    // transformId
                    index := and(_MASK_UINT16, shr(72, temp))

                    // _TRANSFORM_DATAS
                    mc := getStr(mc, index, 0x08)

                    // " />
                    mstore(mc, "IiAgIC8+")
                    mc := add(mc, 8)
                }

                cc := add(cc, 0x20)

                if iszero(lt(i, imageDataLen)) { break }
            }

            // </svg>
            mstore(mc, "PC9zdmc+")
            mc := add(mc, 8)

            // Allocate the memory for the string.
            mstore(0x40, and(add(mc, 31), not(31)))

            // Write the length of the string.
            mstore(result, sub(sub(mc, 0x20), result))
        }
    }

    /* /////////////////////////////////////////////////////////////////////////////
    SVG render
    ///////////////////////////////////////////////////////////////////////////// */
    /// @dev get svg data for concat
    function _firstRender(uint256 characterData) internal view returns (string memory result) {
        assembly {
            /// @dev uint to String
            /// @param sp start pointer
            /// @param x uint16
            /// @return	ep end pointer
            function encode64(sp, x) -> ep {
                // use scratch space
                let ss := 0x20
                for {} 1 {} {
                    ss := sub(ss, 1)

                    mstore8(ss, add(48, mod(x, 10)))
                    x := div(x, 10)
                    if iszero(x) { break }
                }

                // padding '//'
                mstore(0x20, "//")
                let input := mload(ss)

                // base64 encode materials
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, "ghijklmnopqrstuvwxyz0123456789+/")

                // base64 encode
                for {} 1 { input := shl(24, input) } {
                    mstore8(0, mload(and(shr(250, input), 0x3F)))
                    mstore8(1, mload(and(shr(244, input), 0x3F)))
                    mstore8(2, mload(and(shr(238, input), 0x3F)))
                    mstore8(3, mload(and(shr(232, input), 0x3F)))
                    mstore(sp, mload(0x00))

                    sp := add(sp, 4)
                    ss := add(ss, 0x03)

                    if iszero(lt(ss, 0x20)) { break }
                }
                ep := sp
            }

            /// @dev get string in storage
            /// @param sp start pointer
            /// @param i index
            /// @param n 8 or 4 => _TRANSFORM_DATAS / _STYLE_DATAS_SEED
            /// @return	ep end pointer
            function getStr(sp, i, n) -> ep {
                mstore(n, _CHARACTER_DATAS_SEED)
                mstore(0x00, i)
                i := keccak256(0x00, 0x24)
                let v := sload(i)

                let len := div(and(v, sub(mul(0x100, iszero(and(v, 1))), 1)), 2)

                // set value
                switch lt(len, 32)
                // length < 32
                case 1 { mstore(sp, v) }
                // length >= 32
                default {
                    // key
                    mstore(0x00, i)
                    let sc := keccak256(0x00, 0x20)

                    for { let end := add(sp, len) } lt(sp, end) {
                        sc := add(sc, 1)
                        sp := add(sp, 0x20)
                    } { mstore(sp, sload(sc)) }
                }

                ep := add(sp, len)
            }

            // Set `ImageData` to point to the start of the free memory.
            let imageDataPtr := mload(0x40)

            // // getCharacterDatas(uint256 characterId, uint256 index, uint256 slot) --> (uint256 imageId)
            // mstore(0x12, add(_CHARACTER_DATAS_SEED, iszero(iszero(slot))))
            // mstore(0x00, tokenId)
            // let temp := sload(keccak256(0x00, 0x24))

            let temp := characterData

            // len
            let imageDataLen := and(_MASK_UINT16, temp)
            let index

            // memory counter
            let mc := imageDataPtr

            for { let i := 1 } 1 {
                mc := add(mc, 0x20)
                i := add(i, 1)
            } {
                // imageId
                index := and(_MASK_UINT16, shr(mul(i, 16), temp))

                mstore(0x16, _CHARACTER_DATAS_SEED)
                mstore(0x00, index)
                index := sload(keccak256(0x00, 0x24))

                mstore(mc, index)

                if iszero(lt(i, imageDataLen)) { break }
            }

            // free memory pointer
            mstore(0x40, add(mc, 0x20))

            // return data
            result := mload(0x40)

            // Skip the first slot, which stores the length.
            mc := add(result, 0x20)

            // // mstore(mc, 'data:image/svg+xml;base64,')
            // mstore(mc, "data%3Aimage%2Fsvg%2Bxml%3Bbase6")
            // mc := add(mc, 32)

            // mstore(mc, "4%2C")
            // mc := add(mc, 4)

            mstore(mc, "data:image/svg+xml;base64,")
            mc := add(mc, 26)

            // <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">
            mstore(mc, "PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53")
            mc := add(mc, 32)

            mstore(mc, "My5vcmcvMjAwMC9zdmciICAgdmlld0Jv")
            mc := add(mc, 32)

            mstore(mc, "eD0iMCAwIDEwMDAgMTAwMCI+")
            mc := add(mc, 24)

            // symbol
            for {
                let i := 0
                let cc
            } 1 { i := add(i, 1) } {
                // getTransformDatas(transformId)
                temp := mload(add(imageDataPtr, cc))

                if temp {
                    // <symbol id="
                    mstore(mc, "PHN5bWJvbCBpZD0i")
                    mc := add(mc, 16)

                    // transformId
                    index := and(_MASK_UINT8, shr(88, temp))
                    // i.toString
                    mc := encode64(mc, index)

                    // ">
                    mstore(mc, "IiA+")
                    mc := add(mc, 4)

                    // SSTORE2 pointer_.read()
                    temp := mload(add(imageDataPtr, cc))

                    // pointer
                    index := shr(96, temp)

                    let pointerCodesize := extcodesize(index)
                    if iszero(pointerCodesize) { pointerCodesize := 1 }

                    // Offset all indices by 1 to skip the STOP opcode.
                    let size := sub(pointerCodesize, 1)

                    extcodecopy(index, mc, 1, size)
                    mc := add(mc, size)

                    // </symbol>
                    mstore(mc, "PC9zeW1ib2w+")
                    mc := add(mc, 12)
                }
                cc := add(cc, 0x20)

                if iszero(lt(i, imageDataLen)) { break }
            }

            // Allocate the memory for the string.
            mstore(0x40, and(add(mc, 31), not(31)))

            // Write the length of the string.
            mstore(result, sub(sub(mc, 0x20), result))
        }
    }

    /// @dev get svg data for concat
    function _secondRender(uint256 characterData) internal view returns (string memory result) {
        assembly {
            /// @dev uint to String
            /// @param sp start pointer
            /// @param x uint16
            /// @return	ep end pointer
            function encode64(sp, x) -> ep {
                // use scratch space
                let ss := 0x20
                for {} 1 {} {
                    ss := sub(ss, 1)

                    mstore8(ss, add(48, mod(x, 10)))
                    x := div(x, 10)
                    if iszero(x) { break }
                }

                // padding '//'
                mstore(0x20, "//")
                let input := mload(ss)

                // base64 encode materials
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, "ghijklmnopqrstuvwxyz0123456789+/")

                // base64 encode
                for {} 1 { input := shl(24, input) } {
                    mstore8(0, mload(and(shr(250, input), 0x3F)))
                    mstore8(1, mload(and(shr(244, input), 0x3F)))
                    mstore8(2, mload(and(shr(238, input), 0x3F)))
                    mstore8(3, mload(and(shr(232, input), 0x3F)))
                    mstore(sp, mload(0x00))

                    sp := add(sp, 4)
                    ss := add(ss, 0x03)

                    if iszero(lt(ss, 0x20)) { break }
                }
                ep := sp
            }

            /// @dev get string in storage
            /// @param sp start pointer
            /// @param i index
            /// @param n 8 or 4 => _TRANSFORM_DATAS / _STYLE_DATAS_SEED
            /// @return	ep end pointer
            function getStr(sp, i, n) -> ep {
                mstore(n, _CHARACTER_DATAS_SEED)
                mstore(0x00, i)
                i := keccak256(0x00, 0x24)
                let v := sload(i)

                let len := div(and(v, sub(mul(0x100, iszero(and(v, 1))), 1)), 2)

                // set value
                switch lt(len, 32)
                // length < 32
                case 1 { mstore(sp, v) }
                // length >= 32
                default {
                    // key
                    mstore(0x00, i)
                    let sc := keccak256(0x00, 0x20)

                    for { let end := add(sp, len) } lt(sp, end) {
                        sc := add(sc, 1)
                        sp := add(sp, 0x20)
                    } { mstore(sp, sload(sc)) }
                }

                ep := add(sp, len)
            }

            // Set `ImageData` to point to the start of the free memory.
            let imageDataPtr := mload(0x40)

            // // getCharacterDatas(uint256 characterId, uint256 index, uint256 slot) --> (uint256 imageId)
            // mstore(0x12, add(_CHARACTER_DATAS_SEED, iszero(iszero(slot))))
            // mstore(0x00, tokenId)
            // let temp := sload(keccak256(0x00, 0x24))

            let temp := characterData

            // len
            let imageDataLen := and(_MASK_UINT16, temp)
            let index

            // memory counter
            let mc := imageDataPtr

            for { let i := 1 } 1 {
                mc := add(mc, 0x20)
                i := add(i, 1)
            } {
                // imageId
                index := and(_MASK_UINT16, shr(mul(i, 16), temp))

                mstore(0x16, _CHARACTER_DATAS_SEED)
                mstore(0x00, index)
                index := sload(keccak256(0x00, 0x24))

                mstore(mc, index)

                if iszero(lt(i, imageDataLen)) { break }
            }

            // free memory pointer
            mstore(0x40, add(mc, 0x20))

            // return data
            result := mload(0x40)

            // Skip the first slot, which stores the length.
            mc := add(result, 0x20)

            // symbol
            for {
                let i := 0
                let cc
            } 1 { i := add(i, 1) } {
                // getTransformDatas(transformId)
                temp := mload(add(imageDataPtr, cc))

                if temp {
                    // <symbol id="
                    mstore(mc, "PHN5bWJvbCBpZD0i")
                    mc := add(mc, 16)

                    // transformId
                    index := and(_MASK_UINT8, shr(88, temp))
                    // i.toString
                    mc := encode64(mc, index)

                    // ">
                    mstore(mc, "IiA+")
                    mc := add(mc, 4)

                    // SSTORE2 pointer_.read()
                    temp := mload(add(imageDataPtr, cc))

                    // pointer
                    index := shr(96, temp)

                    let pointerCodesize := extcodesize(index)
                    if iszero(pointerCodesize) { pointerCodesize := 1 }

                    // Offset all indices by 1 to skip the STOP opcode.
                    let size := sub(pointerCodesize, 1)

                    extcodecopy(index, mc, 1, size)
                    mc := add(mc, size)

                    // </symbol>
                    mstore(mc, "PC9zeW1ib2w+")
                    mc := add(mc, 12)
                }
                cc := add(cc, 0x20)

                if iszero(lt(i, imageDataLen)) { break }
            }

            // style
            // <style type="text/css">
            mstore(mc, "PHN0eWxlIHR5cGU9InRleHQvY3NzIiA+")
            mc := add(mc, 32)

            for {
                let i := 0
                let cc
            } 1 {
                i := add(i, 1)
                cc := add(cc, 0x20)
            } {
                // _createStyle(styleId_)
                temp := mload(add(imageDataPtr, cc))
                // styleId
                index := and(_MASK_UINT16, shr(56, temp))

                // _getStyleDatas
                mc := getStr(mc, index, 0x04)

                if iszero(lt(i, imageDataLen)) { break }
            }

            // </style>
            mstore(mc, "IDwvc3R5bGU+")
            mc := add(mc, 12)

            // useContent
            for {
                let i := 0
                let cc
            } 1 { i := add(i, 1) } {
                temp := mload(add(imageDataPtr, cc))

                if temp {
                    // <use href="#
                    mstore(mc, "PHVzZSBocmVmPSIj")
                    mc := add(mc, 16)

                    // transformId
                    index := and(_MASK_UINT8, shr(88, temp))

                    // i.toString
                    mc := encode64(mc, index)

                    // " x="0" y="0" transform="
                    mstore(mc, "IiB4PSIwIiB5PSIwIiAgIHRyYW5zZm9y")
                    mc := add(mc, 32)

                    mstore(mc, "bT0i")
                    mc := add(mc, 4)

                    // getTransformDatas(transformId)
                    temp := mload(add(imageDataPtr, cc))

                    // transformId
                    index := and(_MASK_UINT16, shr(72, temp))

                    // _TRANSFORM_DATAS
                    mc := getStr(mc, index, 0x08)

                    // " />
                    mstore(mc, "IiAgIC8+")
                    mc := add(mc, 8)
                }

                cc := add(cc, 0x20)

                if iszero(lt(i, imageDataLen)) { break }
            }

            // </svg>
            mstore(mc, "PC9zdmc+")
            mc := add(mc, 8)

            // Allocate the memory for the string.
            mstore(0x40, and(add(mc, 31), not(31)))

            // Write the length of the string.
            mstore(result, sub(sub(mc, 0x20), result))
        }
    }
    // /// @dev get svg data
    // /// @param slot characterDatas [slot = 0] / partsDatas [slot = 1]
    // function _render(uint256 tokenId, uint256 slot) internal view returns (string memory result) {
    //     assembly {
    //         /// @dev uint to String
    //         /// @param sp start pointer
    //         /// @param x uint16
    //         /// @return	ep end pointer
    //         function encode64(sp, x) -> ep {
    //             // use scratch space
    //             let ss := 0x20
    //             for {} 1 {} {
    //                 ss := sub(ss, 1)

    //                 mstore8(ss, add(48, mod(x, 10)))
    //                 x := div(x, 10)
    //                 if iszero(x) { break }
    //             }

    //             // padding '//'
    //             mstore(0x20, "//")
    //             let input := mload(ss)

    //             // base64 encode materials
    //             mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
    //             mstore(0x3f, "ghijklmnopqrstuvwxyz0123456789+/")

    //             // base64 encode
    //             for {} 1 { input := shl(24, input) } {
    //                 mstore8(0, mload(and(shr(250, input), 0x3F)))
    //                 mstore8(1, mload(and(shr(244, input), 0x3F)))
    //                 mstore8(2, mload(and(shr(238, input), 0x3F)))
    //                 mstore8(3, mload(and(shr(232, input), 0x3F)))
    //                 mstore(sp, mload(0x00))

    //                 sp := add(sp, 4)
    //                 ss := add(ss, 0x03)

    //                 if iszero(lt(ss, 0x20)) { break }
    //             }
    //             ep := sp
    //         }

    //         /// @dev get string in storage
    //         /// @param sp start pointer
    //         /// @param i index
    //         /// @param n 8 or 4 => _TRANSFORM_DATAS / _STYLE_DATAS_SEED
    //         /// @return	ep end pointer
    //         function getStr(sp, i, n) -> ep {
    //             mstore(n, _CHARACTER_DATAS_SEED)
    //             mstore(0x00, i)
    //             i := keccak256(0x00, 0x24)
    //             let v := sload(i)

    //             let len := div(and(v, sub(mul(0x100, iszero(and(v, 1))), 1)), 2)

    //             // set value
    //             switch lt(len, 32)
    //             // length < 32
    //             case 1 { mstore(sp, v) }
    //             // length >= 32
    //             default {
    //                 // key
    //                 mstore(0x00, i)
    //                 let sc := keccak256(0x00, 0x20)

    //                 for { let end := add(sp, len) } lt(sp, end) {
    //                     sc := add(sc, 1)
    //                     sp := add(sp, 0x20)
    //                 } { mstore(sp, sload(sc)) }
    //             }

    //             ep := add(sp, len)
    //         }

    //         // Set `ImageData` to point to the start of the free memory.
    //         let imageDataPtr := mload(0x40)

    //         // getCharacterDatas(uint256 characterId, uint256 index, uint256 slot) --> (uint256 imageId)
    //         mstore(0x12, add(_CHARACTER_DATAS_SEED, iszero(iszero(slot))))
    //         mstore(0x00, tokenId)
    //         let temp := sload(keccak256(0x00, 0x24))

    //         // len
    //         let imageDataLen := and(_MASK_UINT16, temp)
    //         let index

    //         // memory counter
    //         let mc := imageDataPtr

    //         for { let i := 1 } 1 {
    //             mc := add(mc, 0x20)
    //             i := add(i, 1)
    //         } {
    //             // imageId
    //             index := and(_MASK_UINT16, shr(mul(i, 16), temp))

    //             mstore(0x16, _CHARACTER_DATAS_SEED)
    //             mstore(0x00, index)
    //             index := sload(keccak256(0x00, 0x24))

    //             mstore(mc, index)

    //             if iszero(lt(i, imageDataLen)) { break }
    //         }

    //         // free memory pointer
    //         mstore(0x40, add(mc, 0x20))

    //         // return data
    //         result := mload(0x40)

    //         // Skip the first slot, which stores the length.
    //         mc := add(result, 0x20)

    //         // // mstore(mc, 'data:image/svg+xml;base64,')
    //         // mstore(mc, "data%3Aimage%2Fsvg%2Bxml%3Bbase6")
    //         // mc := add(mc, 32)

    //         // mstore(mc, "4%2C")
    //         // mc := add(mc, 4)

    //         mstore(mc, "data:image/svg+xml;base64,")
    //         mc := add(mc, 26)

    //         // <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">
    //         mstore(mc, "PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53")
    //         mc := add(mc, 32)

    //         mstore(mc, "My5vcmcvMjAwMC9zdmciICAgdmlld0Jv")
    //         mc := add(mc, 32)

    //         mstore(mc, "eD0iMCAwIDEwMDAgMTAwMCI+")
    //         mc := add(mc, 24)

    //         // symbol
    //         for {
    //             let i := 0
    //             let cc
    //         } 1 { i := add(i, 1) } {
    //             // getTransformDatas(transformId)
    //             temp := mload(add(imageDataPtr, cc))

    //             if temp {
    //                 // <symbol id="
    //                 mstore(mc, "PHN5bWJvbCBpZD0i")
    //                 mc := add(mc, 16)

    //                 // transformId
    //                 index := and(_MASK_UINT8, shr(88, temp))
    //                 // i.toString
    //                 mc := encode64(mc, index)

    //                 // ">
    //                 mstore(mc, "IiA+")
    //                 mc := add(mc, 4)

    //                 // SSTORE2 pointer_.read()
    //                 temp := mload(add(imageDataPtr, cc))

    //                 // pointer
    //                 index := shr(96, temp)

    //                 let pointerCodesize := extcodesize(index)
    //                 if iszero(pointerCodesize) { pointerCodesize := 1 }

    //                 // Offset all indices by 1 to skip the STOP opcode.
    //                 let size := sub(pointerCodesize, 1)

    //                 extcodecopy(index, mc, 1, size)
    //                 mc := add(mc, size)

    //                 // </symbol>
    //                 mstore(mc, "PC9zeW1ib2w+")
    //                 mc := add(mc, 12)
    //             }
    //             cc := add(cc, 0x20)

    //             if iszero(lt(i, imageDataLen)) { break }
    //         }

    //         // style
    //         // <style type="text/css">
    //         mstore(mc, "PHN0eWxlIHR5cGU9InRleHQvY3NzIiA+")
    //         mc := add(mc, 32)

    //         for {
    //             let i := 0
    //             let cc
    //         } 1 {
    //             i := add(i, 1)
    //             cc := add(cc, 0x20)
    //         } {
    //             // _createStyle(styleId_)
    //             temp := mload(add(imageDataPtr, cc))
    //             // styleId
    //             index := and(_MASK_UINT16, shr(56, temp))

    //             // _getStyleDatas
    //             mc := getStr(mc, index, 0x04)

    //             if iszero(lt(i, imageDataLen)) { break }
    //         }

    //         // </style>
    //         mstore(mc, "IDwvc3R5bGU+")
    //         mc := add(mc, 12)

    //         // useContent
    //         for {
    //             let i := 0
    //             let cc
    //         } 1 { i := add(i, 1) } {
    //             temp := mload(add(imageDataPtr, cc))

    //             if temp {
    //                 // <use href="#
    //                 mstore(mc, "PHVzZSBocmVmPSIj")
    //                 mc := add(mc, 16)

    //                 // transformId
    //                 index := and(_MASK_UINT8, shr(88, temp))

    //                 // i.toString
    //                 mc := encode64(mc, index)

    //                 // " x="0" y="0" transform="
    //                 mstore(mc, "IiB4PSIwIiB5PSIwIiAgIHRyYW5zZm9y")
    //                 mc := add(mc, 32)

    //                 mstore(mc, "bT0i")
    //                 mc := add(mc, 4)

    //                 // getTransformDatas(transformId)
    //                 temp := mload(add(imageDataPtr, cc))

    //                 // transformId
    //                 index := and(_MASK_UINT16, shr(72, temp))

    //                 // _TRANSFORM_DATAS
    //                 mc := getStr(mc, index, 0x08)

    //                 // " />
    //                 mstore(mc, "IiAgIC8+")
    //                 mc := add(mc, 8)
    //             }

    //             cc := add(cc, 0x20)

    //             if iszero(lt(i, imageDataLen)) { break }
    //         }

    //         // </svg>
    //         mstore(mc, "PC9zdmc+")
    //         mc := add(mc, 8)

    //         // Allocate the memory for the string.
    //         mstore(0x40, and(add(mc, 31), not(31)))

    //         // Write the length of the string.
    //         mstore(result, sub(sub(mc, 0x20), result))
    //     }
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Base64} from "solady/utils/Base64.sol";

/// @notice Library to encode strings in Base64.
library LibBase64 {
    /// @dev Check if the length of the string is a multiple of 3.
    function checkStringLength(bytes memory data) internal pure {
        assembly {
            // str.length
            let length := mload(data)

            // Get 32bytes containing the last character
            let check := mload(add(data, length))

            // If the last character is `=` or `==`, an error occurs
            if eq(and(check, 0xff), 0x3d) {
                mstore(0x00, 0x9959fc03) // `StringLengthNotMultiple3()`
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Base64 encoding of values padding with spaces to multiples of 3.
    function paddingStringBase64Encode(string memory str) internal pure returns (string memory) {
        assembly {
            // str.length
            let length := mload(str)

            // memory counter
            let mc := add(str, 0x20)

            // p = [0, 2, 1][len % 3]
            let p := div(2, mod(length, 3))

            // padding ' '(space)
            mstore(add(mc, length), shl(240, 0x2020))

            // Allocate the memory for the string.
            // Add 31 and mask with `not(31)` to round the
            // free memory pointer up the next multiple of 32.
            mstore(0x40, and(add(add(mc, add(length, p)), 31), not(31)))

            // Write the length of the string.
            mstore(str, add(length, p))
        }
        return Base64.encode(bytes(str));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

abstract contract PersonalityHandler {
    using Strings for uint256;

    // _STATUS / _PERSONALITY /
    uint256 private constant _PERSONALITY_DATAS_SEED = 0xca5edf5127e16afc;
    uint256 private constant _MASK_UINT8 = (1 << 8) - 1;

    // personality length < 32
    string[] _personalities = [
        "personality0",
        "personality1",
        "personality2",
        "personality3",
        "personality4",
        "personality5",
        "personality6",
        "personality7",
        "personality8",
        "personality9",
        "personality10",
        "personality11",
        "personality12",
        "personality13",
        "personality14",
        "personality15"
    ];

    /* /////////////////////////////////////////////////////////////////////////////
    Error
    ///////////////////////////////////////////////////////////////////////////// */

    /// @dev Name must be less than 30 characters. `0x680b6caf`
    error NameTooLong();

    /* /////////////////////////////////////////////////////////////////////////////
    PERSONALITY_DATAS
    ///////////////////////////////////////////////////////////////////////////// */

    /// @dev set personalityDatas[tokenId] = personalityData / status
    /// personalityData = string[30bytes] / uint8      / [1bytes]
    ///                   name            / personality  / string.length
    /// @param tokenId uint96
    /// @param name string / length < 31
    /// @param personality < 16
    /// @param status uint256
    function _setPersonalityData(uint256 tokenId, string memory name, uint256 personality, uint256 status) internal {
        assembly {
            // name write to storage
            mstore(0x04, _PERSONALITY_DATAS_SEED)
            mstore(0x00, tokenId)
            let slot := keccak256(0x00, 0x24)

            // name.length
            let len := mload(name)

            // string.length < 31
            if lt(30, len) {
                mstore(0x00, 0x680b6caf) // NameTooLong()
                revert(0x1c, 0x04)
            }

            // set characer
            mstore8(add(name, 0x3e), personality)
            // mstore8(add(name, 0x38), and(personality, 0x08))

            // (value & length) set to slot
            sstore(slot, add(mload(add(name, 0x20)), mul(len, 2)))

            // status write to storage
            mstore(0x08, _PERSONALITY_DATAS_SEED)
            mstore(0x00, tokenId)
            slot := keccak256(0x00, 0x24)
            sstore(slot, status)
        }
    }

    /// @dev name / status = personalityDatas[tokenId]
    /// @param tokenId uint96
    /// @return personalityData name / personality
    /// @return status uint256
    function _getPersonalityData(uint256 tokenId) internal view returns (bytes32 personalityData, uint256 status) {
        assembly {
            // free memory pointer
            personalityData := mload(0x40)

            // personalityData read to storage
            mstore(0x04, _PERSONALITY_DATAS_SEED)
            mstore(0x00, tokenId)
            let slot := keccak256(0x00, 0x24)
            personalityData := sload(slot)

            // status read to storage
            mstore(0x08, _PERSONALITY_DATAS_SEED)
            mstore(0x00, tokenId)
            slot := keccak256(0x00, 0x24)
            status := sload(slot)
        }
    }

    /// @dev name / status = personalityDatas[tokenId]
    /// @param tokenId uint96
    /// @return name string / length < 31
    function getName(uint256 tokenId) public view returns (string memory name) {
        (bytes32 personalityData,) = _getPersonalityData(tokenId);

        assembly {
            // free memory pointer
            name := mload(0x40)
            let value := personalityData

            // value.length because length < 32
            let len := div(and(value, 0xff), 2)
            let mc := add(name, 0x20)

            // because length < 32
            mstore(mc, value)

            // Allocate the memory for the string.
            mstore(0x40, and(add(add(mc, len), 31), not(31)))

            // Write the length of the string.
            mstore(name, len)
        }
    }

    /// @dev name / status = personalityDatas[tokenId]
    /// @param tokenId uint96
    /// @return personality string
    function getPersonality(uint256 tokenId) public view returns (string memory personality) {
        (bytes32 personalityData,) = _getPersonalityData(tokenId);

        assembly {
            // free memory pointer
            personality := mload(0x40)

            // memory counter
            let mc := add(personality, 0x20)

            // personality Id
            let cc := and(shr(8, personalityData), _MASK_UINT8)

            // slot
            mstore(0x00, _personalities.slot)
            let slot := keccak256(0x00, 0x20)

            // personality value
            let value := sload(add(slot, cc))
            mstore(mc, value)
            mc := add(mc, div(and(value, _MASK_UINT8), 2))

            // Allocate the memory for the string.
            mstore(0x40, and(add(mc, 31), not(31)))

            // Write the length of the string.
            mstore(personality, sub(sub(mc, 0x20), personality))
        }
    }

    /// @dev name / status = personalityDatas[tokenId]
    /// @param tokenId uint96
    /// @return status uint256
    function getStatus(uint256 tokenId) public view returns (uint256) {
        (, uint256 _status) = _getPersonalityData(tokenId);

        return _status;
    }
}