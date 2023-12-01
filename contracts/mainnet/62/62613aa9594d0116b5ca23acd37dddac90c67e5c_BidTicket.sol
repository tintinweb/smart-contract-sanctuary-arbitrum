// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//                            _.-^-._    .--.
//                         .-'   _   '-. |__|
//                        /     |_|     \|  |
//                       /               \  |
//                      /|     _____     |\ |
//                       |    |==|==|    |  |
//   |---|---|---|---|---|    |--|--|    |  |
//   |---|---|---|---|---|    |==|==|    |  |
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//  ______  Harvest.art v3 (BidTicket) _______

import "ERC1155P/contracts/ERC1155P.sol";
import "solady/src/auth/Ownable.sol";
import "./IBidTicket.sol";

contract BidTicket is ERC1155P, Ownable, IBidTicket {
    address public harvestContract;
    address public auctionsContract;
    mapping(uint256 => string) private _tokenURIs;

    error NotAuthorized();

    modifier onlyMinters() {
        if (msg.sender != harvestContract) {
            if (msg.sender != owner()) {
                revert NotAuthorized();
            }
        }
        _;
    }

    modifier onlyBurners() {
        if (msg.sender != auctionsContract) {
            if (msg.sender != owner()) {
                revert NotAuthorized();
            }
        }
        _;
    }

    constructor() {
        _initializeOwner(msg.sender);
    }

    function name() public view virtual override returns (string memory) {
        return "BidTicket";
    }

    function symbol() public view virtual override returns (string memory) {
        return "TCKT";
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return _tokenURIs[id];
    }

    function mint(address to, uint256 id, uint256 amount) external virtual onlyMinters {
        _mint(to, id, amount, "");
    }

    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts) public onlyMinters {
        _mintBatch(to, ids, amounts, "");
    }

    function burn(address from, uint256 id, uint256 amount) external onlyBurners {
        _burn(from, id, amount);
    }

    function burnBatch(address from, uint256[] calldata ids, uint256[] calldata amounts) external onlyBurners {
        _burnBatch(from, ids, amounts);
    }

    function setURI(uint256 tokenId, string calldata tokenURI) external virtual onlyOwner {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(uri(tokenId), tokenId);
    }

    function setHarvestContract(address harvestContract_) external onlyOwner {
        harvestContract = harvestContract_;
    }

    function setAuctionsContract(address auctionsContract_) external onlyOwner {
        auctionsContract = auctionsContract_;
    }
}

// SPDX-License-Identifier: MIT
// ERC1155P Contracts v1.1
// Creator: 0xjustadev/0xth0mas

pragma solidity ^0.8.20;

import "./IERC1155P.sol";

/**
 * @dev Interface of ERC1155 token receiver.
 */
interface ERC1155P__IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Interface for IERC1155MetadataURI.
 */

interface ERC1155P__IERC1155MetadataURI {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

 /**
 * @title ERC1155P
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155 including the Metadata extension.
 * Optimized for lower gas for users collecting multiple tokens.
 *
 * Assumptions:
 * - An owner cannot have more than 2**16 - 1 of a single token
 * - The maximum token ID cannot exceed 2**100 - 1
 */
abstract contract ERC1155P is IERC1155P, ERC1155P__IERC1155MetadataURI {

    /**
     * @dev MAX_ACCOUNT_TOKEN_BALANCE is 2^16-1 because token balances are
     *      are being packed into 16 bits within each bucket.
     */
    uint256 private constant MAX_ACCOUNT_TOKEN_BALANCE = 0xFFFF;

    uint256 private constant BALANCE_STORAGE_OFFSET =
        0xE000000000000000000000000000000000000000000000000000000000000000;

    uint256 private constant APPROVAL_STORAGE_OFFSET =
        0xD000000000000000000000000000000000000000000000000000000000000000;

    /**
     * @dev MAX_TOKEN_ID is derived from custom storage pointer location for 
     *      account/token balance data. Wallet address is shifted 92 bits left
     *      and leaves 92 bits for bucket #'s. Each bucket holds 8 token balances
     *      2^92*8-1 = MAX_TOKEN_ID
     */
    uint256 private constant MAX_TOKEN_ID = 0x07FFFFFFFFFFFFFFFFFFFFFFF;

    // The `TransferSingle` event signature is given by:
    // `keccak256(bytes("TransferSingle(address,address,address,uint256,uint256)"))`.
    bytes32 private constant _TRANSFER_SINGLE_EVENT_SIGNATURE =
        0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62;
    // The `TransferBatch` event signature is given by:
    // `keccak256(bytes("TransferBatch(address,address,address,uint256[],uint256[])"))`.
    bytes32 private constant _TRANSFER_BATCH_EVENT_SIGNATURE =
        0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb;
    // The `ApprovalForAll` event signature is given by:
    // `keccak256(bytes("ApprovalForAll(address,address,bool)"))`.
    bytes32 private constant _APPROVAL_FOR_ALL_EVENT_SIGNATURE =
        0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31;

    /// @dev Returns the name of the token.
    function name() public view virtual returns(string memory);

    /// @dev Returns the symbol of the token.
    function symbol() public view virtual returns(string memory);

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
            interfaceId == 0xd9b67a26 || // ERC165 interface ID for ERC1155.
            interfaceId == 0x0e89341c; // ERC165 interface ID for ERC1155MetadataURI.
    }

    /// @dev Returns the URI for token `id`.
    ///
    /// You can either return the same templated URI for all token IDs,
    /// (e.g. "https://example.com/api/{id}.json"),
    /// or return a unique URI for each `id`.
    ///
    /// See: https://eips.ethereum.org/EIPS/eip-1155#metadata
    function uri(uint256 id) public view virtual returns (string memory);

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        if(account == address(0)) { _revert(BalanceQueryForZeroAddress.selector); }
        return getBalance(account, id);
    }

    /**
     * @dev Gets the amount of tokens minted by an account for a given token id
     */
    function _numberMinted(address account, uint256 id) internal view returns (uint256) {
        if(account == address(0)) { _revert(BalanceQueryForZeroAddress.selector); }
        return getMinted(account, id);
    }

    /**
     * @dev Gets the balance of an account's token id from packed token data
     *
     */
    function getBalance(address account, uint256 id) private view returns (uint256 _balance) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(BALANCE_STORAGE_OFFSET, or(shr(4, shl(96, account)), shr(3, id))))
            _balance := shr(shl(5, and(id, 0x07)), and(sload(keccak256(0x00, 0x20)), shl(shl(5, and(id, 0x07)), 0x0000FFFF)))
        }
    }

    /**
     * @dev Sets the balance of an account's token id in packed token data
     *
     */
    function setBalance(address account, uint256 id, uint256 amount) private {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(BALANCE_STORAGE_OFFSET, or(shr(4, shl(96, account)), shr(3, id))))
            mstore(0x00, keccak256(0x00, 0x20))
            sstore(mload(0x00), or(and(not(shl(shl(5, and(id, 0x07)), 0x0000FFFF)), sload(mload(0x00))), shl(shl(5, and(id, 0x07)), amount)))
        }
    }

    /**
     * @dev Gets the number minted of an account's token id from packed token data
     *
     */
    function getMinted(address account, uint256 id) private view returns (uint256 _minted) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(BALANCE_STORAGE_OFFSET, or(shr(4, shl(96, account)), shr(3, id))))
            _minted := shr(16, shr(shl(5, and(id, 0x07)), and(sload(keccak256(0x00, 0x20)), shl(shl(5, and(id, 0x07)), 0xFFFF0000))))
        }
    }

    /**
     * @dev Sets the number minted of an account's token id in packed token data
     *
     */
    function setMinted(address account, uint256 id, uint256 amount) private {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(BALANCE_STORAGE_OFFSET, or(shr(4, shl(96, account)), shr(3, id))))
            mstore(0x00, keccak256(0x00, 0x20))
            sstore(mload(0x00), or(and(not(shl(shl(5, and(id, 0x07)), 0xFFFF0000)), sload(mload(0x00))), shl(shl(5, and(id, 0x07)), shl(16, amount))))
        }
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) public view virtual override returns (uint256[] memory) {
        if(accounts.length != ids.length) { _revert(ArrayLengthMismatch.selector); }

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for(uint256 i = 0; i < accounts.length;) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
            unchecked {
                ++i;
            }
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool _approved) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, shr(96, shl(96, account)))
            mstore(0x20, or(APPROVAL_STORAGE_OFFSET, shr(96, shl(96, operator))))
            mstore(0x00, keccak256(0x00, 0x40))
            _approved := sload(mload(0x00))
        }
        return _approved; 
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) public virtual override {
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if(id > MAX_TOKEN_ID) { _revert(ExceedsMaximumTokenId.selector); }
        if(to == address(0)) { _revert(TransferToZeroAddress.selector); }
        
        if(from != _msgSenderERC1155P())
            if (!isApprovedForAll(from, _msgSenderERC1155P())) _revert(TransferCallerNotOwnerNorApproved.selector);

        address operator = _msgSenderERC1155P();

        _beforeTokenTransfer(operator, from, to, id, amount, data);

        uint256 fromBalance = getBalance(from, id);
        if(amount > fromBalance) { _revert(TransferExceedsBalance.selector); }

        if(from != to) {
            uint256 toBalance = getBalance(to, id);
            unchecked {
                fromBalance -= amount;
                toBalance += amount;
            }
            if(toBalance > MAX_ACCOUNT_TOKEN_BALANCE) { _revert(ExceedsMaximumBalance.selector); }
            setBalance(from, id, fromBalance);
            setBalance(to, id, toBalance);   
        }

        /// @solidity memory-safe-assembly
        assembly {
            // Emit the `TransferSingle` event.
            let memOffset := mload(0x40)
            mstore(memOffset, id)
            mstore(add(memOffset, 0x20), amount)
            log4(
                memOffset, // Start of data .
                0x40, // Length of data.
                _TRANSFER_SINGLE_EVENT_SIGNATURE, // Signature.
                operator, // `operator`.
                from, // `from`.
                to // `to`.
            )
        }

        _afterTokenTransfer(operator, from, to, id, amount, data);

        if(to.code.length != 0)
            if(!_checkContractOnERC1155Received(from, to, id, amount, data))  {
                _revert(TransferToNonERC1155ReceiverImplementer.selector);
            }
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal virtual {
        if(to == address(0)) { _revert(TransferToZeroAddress.selector); }
        if(ids.length != amounts.length) { _revert(ArrayLengthMismatch.selector); }

        if(from != _msgSenderERC1155P())
            if (!isApprovedForAll(from, _msgSenderERC1155P())) _revert(TransferCallerNotOwnerNorApproved.selector);

        address operator = _msgSenderERC1155P();

        _beforeBatchTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length;) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            if(id > MAX_TOKEN_ID) { _revert(ExceedsMaximumTokenId.selector); }

            uint256 fromBalance = getBalance(from, id);
            if(amount > fromBalance) { _revert(TransferExceedsBalance.selector); }

            if(from != to) {
                uint256 toBalance = getBalance(to, id);
                unchecked {
                    fromBalance -= amount;
                    toBalance += amount;
                }
                if(toBalance > MAX_ACCOUNT_TOKEN_BALANCE) { _revert(ExceedsMaximumBalance.selector); }
                setBalance(from, id, fromBalance);
                setBalance(to, id, toBalance);
            }

            unchecked {
                ++i;
            }
        }

        /// @solidity memory-safe-assembly
        assembly {
            let memOffset := mload(0x40)
            mstore(memOffset, 0x40)
            mstore(add(memOffset,0x20), add(0x60, mul(0x20,ids.length)))
            mstore(add(memOffset,0x40), ids.length)
            calldatacopy(add(memOffset,0x60), ids.offset, mul(0x20,ids.length))
            mstore(add(add(memOffset,0x60),mul(0x20,ids.length)), amounts.length)
            calldatacopy(add(add(memOffset,0x80),mul(0x20,ids.length)), amounts.offset, mul(0x20,amounts.length))
            log4(
                memOffset, 
                add(0x80,mul(0x40,amounts.length)),
                _TRANSFER_BATCH_EVENT_SIGNATURE, // Signature.
                operator, // `operator`.
                from, // `from`.
                to // `to`.
            )
        }

        _afterBatchTokenTransfer(operator, from, to, ids, amounts, data);


        if(to.code.length != 0)
            if(!_checkContractOnERC1155BatchReceived(from, to, ids, amounts, data))  {
                _revert(TransferToNonERC1155ReceiverImplementer.selector);
            }
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        if(id > MAX_TOKEN_ID) { _revert(ExceedsMaximumTokenId.selector); }
        if(to == address(0)) { _revert(MintToZeroAddress.selector); }
        if(amount == 0) { _revert(MintZeroQuantity.selector); }

        address operator = _msgSenderERC1155P();

        _beforeTokenTransfer(operator, address(0), to, id, amount, data);

        uint256 toBalanceBefore = getBalance(to, id);
        uint256 toBalanceAfter;
        unchecked {
            toBalanceAfter = toBalanceBefore + amount;
        }
        if(toBalanceAfter > MAX_ACCOUNT_TOKEN_BALANCE) { _revert(ExceedsMaximumBalance.selector); }
        if(toBalanceAfter < toBalanceBefore) { _revert(ExceedsMaximumBalance.selector); } // catches overflow
        setBalance(to, id, toBalanceAfter);

        uint256 toMintedBefore = getMinted(to, id);
        uint256 toMintedAfter;
        unchecked {
            toMintedAfter = toMintedBefore + amount;
        }
        if(toMintedAfter > MAX_ACCOUNT_TOKEN_BALANCE) { _revert(ExceedsMaximumBalance.selector); }
        if(toMintedAfter < toMintedBefore) { _revert(ExceedsMaximumBalance.selector); } // catches overflow
        setMinted(to, id, toMintedAfter);

        /// @solidity memory-safe-assembly
        assembly {
            // Emit the `TransferSingle` event.
            let memOffset := mload(0x40)
            mstore(memOffset, id)
            mstore(add(memOffset, 0x20), amount)
            log4(
                memOffset, // Start of data .
                0x40, // Length of data.
                _TRANSFER_SINGLE_EVENT_SIGNATURE, // Signature.
                operator, // `operator`.
                0, // `from`.
                to // `to`.
            )
        }

        _afterTokenTransfer(operator, address(0), to, id, amount, data);

        if(to.code.length != 0)
            if(!_checkContractOnERC1155Received(address(0), to, id, amount, data))  {
                _revert(TransferToNonERC1155ReceiverImplementer.selector);
            }
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal virtual {
        if(to == address(0)) { _revert(MintToZeroAddress.selector); }
        if(ids.length != amounts.length) { _revert(ArrayLengthMismatch.selector); }

        address operator = _msgSenderERC1155P();

        _beforeBatchTokenTransfer(operator, address(0), to, ids, amounts, data);

        uint256 id;
        uint256 amount;
        for (uint256 i = 0; i < ids.length;) {
            id = ids[i];
            amount = amounts[i];
            if(id > MAX_TOKEN_ID) { _revert(ExceedsMaximumTokenId.selector); }
            if(amount == 0) { _revert(MintZeroQuantity.selector); }

            uint256 toBalanceBefore = getBalance(to, id);
            uint256 toBalanceAfter;
            unchecked {
                toBalanceAfter = toBalanceBefore + amount;
            }
            if(toBalanceAfter > MAX_ACCOUNT_TOKEN_BALANCE) { _revert(ExceedsMaximumBalance.selector); }
            if(toBalanceAfter < toBalanceBefore) { _revert(ExceedsMaximumBalance.selector); } // catches overflow
            setBalance(to, id, toBalanceAfter);

            uint256 toMintedBefore = getMinted(to, id);
            uint256 toMintedAfter;
            unchecked {
                toMintedAfter = toMintedBefore + amount;
            }
            if(toMintedAfter > MAX_ACCOUNT_TOKEN_BALANCE) { _revert(ExceedsMaximumBalance.selector); }
            if(toMintedAfter < toMintedBefore) { _revert(ExceedsMaximumBalance.selector); } // catches overflow
            setMinted(to, id, toMintedAfter);

            unchecked {
                ++i;
            }
        }

        /// @solidity memory-safe-assembly
        assembly {
            let memOffset := mload(0x40)
            mstore(memOffset, 0x40)
            mstore(add(memOffset,0x20), add(0x60, mul(0x20,ids.length)))
            mstore(add(memOffset,0x40), ids.length)
            calldatacopy(add(memOffset,0x60), ids.offset, mul(0x20,ids.length))
            mstore(add(add(memOffset,0x60),mul(0x20,ids.length)), amounts.length)
            calldatacopy(add(add(memOffset,0x80),mul(0x20,ids.length)), amounts.offset, mul(0x20,amounts.length))
            log4(
                memOffset, 
                add(0x80,mul(0x40,amounts.length)),
                _TRANSFER_BATCH_EVENT_SIGNATURE, // Signature.
                operator, // `operator`.
                0, // `from`.
                to // `to`.
            )
        }

        _afterBatchTokenTransfer(operator, address(0), to, ids, amounts, data);

        if(to.code.length != 0)
            if(!_checkContractOnERC1155BatchReceived(address(0), to, ids, amounts, data))  {
                _revert(TransferToNonERC1155ReceiverImplementer.selector);
            }
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        if(id > MAX_TOKEN_ID) { _revert(ExceedsMaximumTokenId.selector); }
        if(from == address(0)) { _revert(BurnFromZeroAddress.selector); }

        address operator = _msgSenderERC1155P();

        _beforeTokenTransfer(operator, from, address(0), id, amount, "");

        uint256 fromBalance = getBalance(from, id);
        if(amount > fromBalance) { _revert(BurnExceedsBalance.selector); }
        unchecked {
            fromBalance -= amount;
        }
        setBalance(from, id, fromBalance);

        /// @solidity memory-safe-assembly
        assembly {
            // Emit the `TransferSingle` event.
            let memOffset := mload(0x40)
            mstore(memOffset, id)
            mstore(add(memOffset, 0x20), amount)
            log4(
                memOffset, // Start of data.
                0x40, // Length of data.
                _TRANSFER_SINGLE_EVENT_SIGNATURE, // Signature.
                operator, // `operator`.
                from, // `from`.
                0 // `to`.
            )
        }

        _afterTokenTransfer(operator, from, address(0), id, amount, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address from, uint256[] calldata ids, uint256[] calldata amounts) internal virtual {
        if(from == address(0)) { _revert(BurnFromZeroAddress.selector); }
        if(ids.length != amounts.length) { _revert(ArrayLengthMismatch.selector); }

        address operator = _msgSenderERC1155P();

        _beforeBatchTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length;) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            if(id > MAX_TOKEN_ID) { _revert(ExceedsMaximumTokenId.selector); }

            uint256 fromBalance = getBalance(from, id);
            if(amount > fromBalance) { _revert(BurnExceedsBalance.selector); }
            unchecked {
                fromBalance -= amount;
            }
            setBalance(from, id, fromBalance);
            unchecked {
                ++i;
            }
        }

        /// @solidity memory-safe-assembly
        assembly {
            let memOffset := mload(0x40)
            mstore(memOffset, 0x40)
            mstore(add(memOffset,0x20), add(0x60, mul(0x20,ids.length)))
            mstore(add(memOffset,0x40), ids.length)
            calldatacopy(add(memOffset,0x60), ids.offset, mul(0x20,ids.length))
            mstore(add(add(memOffset,0x60),mul(0x20,ids.length)), amounts.length)
            calldatacopy(add(add(memOffset,0x80),mul(0x20,ids.length)), amounts.offset, mul(0x20,amounts.length))
            log4(
                memOffset, 
                add(0x80,mul(0x40,amounts.length)),
                _TRANSFER_BATCH_EVENT_SIGNATURE, // Signature.
                operator, // `operator`.
                from, // `from`.
                0 // `to`.
            )
        }

        _afterBatchTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, caller())
            mstore(0x20, or(APPROVAL_STORAGE_OFFSET, shr(96, shl(96, operator))))
            mstore(0x00, keccak256(0x00, 0x40))
            mstore(0x20, approved)
            sstore(mload(0x00), mload(0x20))
            log3(
                0x20,
                0x20,
                _APPROVAL_FOR_ALL_EVENT_SIGNATURE,
                caller(),
                shr(96, shl(96, operator))
            )
        }
    }

    /**
     * @dev Hook that is called before any single token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    

    /**
     * @dev Hook that is called before any batch token transfer. This includes minting
     * and burning.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    
    function _beforeBatchTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any single token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any batch token transfer. This includes minting
     * and burning.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    
    function _afterBatchTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC1155Receiver-onERC155Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `id` - Token ID to be transferred.
     * `amount` - Balance of token to be transferred
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC1155Received(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory _data
    ) private returns (bool) {
        try ERC1155P__IERC1155Receiver(to).onERC1155Received(_msgSenderERC1155P(), from, id, amount, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC1155P__IERC1155Receiver(to).onERC1155Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                _revert(TransferToNonERC1155ReceiverImplementer.selector);
            }
            /// @solidity memory-safe-assembly
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    /**
     * @dev Private function to invoke {IERC1155Receiver-onERC155Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `id` - Token ID to be transferred.
     * `amount` - Balance of token to be transferred
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC1155BatchReceived(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory _data
    ) private returns (bool) {
        try ERC1155P__IERC1155Receiver(to).onERC1155BatchReceived(_msgSenderERC1155P(), from, ids, amounts, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC1155P__IERC1155Receiver(to).onERC1155BatchReceived.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                _revert(TransferToNonERC1155ReceiverImplementer.selector);
            }
            /// @solidity memory-safe-assembly
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }
    
    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC1155P() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/Ownable.sol)
///
/// @dev Note:
/// This implementation does NOT auto-initialize the owner to `msg.sender`.
/// You MUST call the `_initializeOwner` in the constructor / initializer.
///
/// While the ownable portion follows
/// [EIP-173](https://eips.ethereum.org/EIPS/eip-173) for compatibility,
/// the nomenclature for the 2-step ownership handover may be unique to this codebase.
abstract contract Ownable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The `newOwner` cannot be the zero address.
    error NewOwnerIsZeroAddress();

    /// @dev The `pendingOwner` does not have a valid handover request.
    error NoHandoverRequest();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ownership is transferred from `oldOwner` to `newOwner`.
    /// This event is intentionally kept the same as OpenZeppelin's Ownable to be
    /// compatible with indexers and [EIP-173](https://eips.ethereum.org/EIPS/eip-173),
    /// despite it not being as lightweight as a single argument event.
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /// @dev An ownership handover to `pendingOwner` has been requested.
    event OwnershipHandoverRequested(address indexed pendingOwner);

    /// @dev The ownership handover to `pendingOwner` has been canceled.
    event OwnershipHandoverCanceled(address indexed pendingOwner);

    /// @dev `keccak256(bytes("OwnershipTransferred(address,address)"))`.
    uint256 private constant _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE =
        0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

    /// @dev `keccak256(bytes("OwnershipHandoverRequested(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE =
        0xdbf36a107da19e49527a7176a1babf963b4b0ff8cde35ee35d6cd8f1f9ac7e1d;

    /// @dev `keccak256(bytes("OwnershipHandoverCanceled(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE =
        0xfa7b8eab7da67f412cc9575ed43464468f9bfbae89d1675917346ca6d8fe3c92;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The owner slot is given by: `not(_OWNER_SLOT_NOT)`.
    /// It is intentionally chosen to be a high value
    /// to avoid collision with lower slots.
    /// The choice of manual storage layout is to enable compatibility
    /// with both regular and upgradeable contracts.
    uint256 private constant _OWNER_SLOT_NOT = 0x8b78c6d8;

    /// The ownership handover slot of `newOwner` is given by:
    /// ```
    ///     mstore(0x00, or(shl(96, user), _HANDOVER_SLOT_SEED))
    ///     let handoverSlot := keccak256(0x00, 0x20)
    /// ```
    /// It stores the expiry timestamp of the two-step ownership handover.
    uint256 private constant _HANDOVER_SLOT_SEED = 0x389a75e1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Initializes the owner directly without authorization guard.
    /// This function must be called upon initialization,
    /// regardless of whether the contract is upgradeable or not.
    /// This is to enable generalization to both regular and upgradeable contracts,
    /// and to save gas in case the initial owner is not the caller.
    /// For performance reasons, this function will not check if there
    /// is an existing owner.
    function _initializeOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Store the new value.
            sstore(not(_OWNER_SLOT_NOT), newOwner)
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
        }
    }

    /// @dev Sets the owner directly without authorization guard.
    function _setOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let ownerSlot := not(_OWNER_SLOT_NOT)
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
            // Store the new value.
            sstore(ownerSlot, newOwner)
        }
    }

    /// @dev Throws if the sender is not the owner.
    function _checkOwner() internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the stored owner, revert.
            if iszero(eq(caller(), sload(not(_OWNER_SLOT_NOT)))) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns how long a two-step ownership handover is valid for in seconds.
    /// Override to return a different value if needed.
    /// Made internal to conserve bytecode. Wrap it in a public function if needed.
    function _ownershipHandoverValidFor() internal view virtual returns (uint64) {
        return 48 * 3600;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows the owner to transfer the ownership to `newOwner`.
    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(shl(96, newOwner)) {
                mstore(0x00, 0x7448fbae) // `NewOwnerIsZeroAddress()`.
                revert(0x1c, 0x04)
            }
        }
        _setOwner(newOwner);
    }

    /// @dev Allows the owner to renounce their ownership.
    function renounceOwnership() public payable virtual onlyOwner {
        _setOwner(address(0));
    }

    /// @dev Request a two-step ownership handover to the caller.
    /// The request will automatically expire in 48 hours (172800 seconds) by default.
    function requestOwnershipHandover() public payable virtual {
        unchecked {
            uint256 expires = block.timestamp + _ownershipHandoverValidFor();
            /// @solidity memory-safe-assembly
            assembly {
                // Compute and set the handover slot to `expires`.
                mstore(0x0c, _HANDOVER_SLOT_SEED)
                mstore(0x00, caller())
                sstore(keccak256(0x0c, 0x20), expires)
                // Emit the {OwnershipHandoverRequested} event.
                log2(0, 0, _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE, caller())
            }
        }
    }

    /// @dev Cancels the two-step ownership handover to the caller, if any.
    function cancelOwnershipHandover() public payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x20), 0)
            // Emit the {OwnershipHandoverCanceled} event.
            log2(0, 0, _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE, caller())
        }
    }

    /// @dev Allows the owner to complete the two-step ownership handover to `pendingOwner`.
    /// Reverts if there is no existing ownership handover requested by `pendingOwner`.
    function completeOwnershipHandover(address pendingOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            let handoverSlot := keccak256(0x0c, 0x20)
            // If the handover does not exist, or has expired.
            if gt(timestamp(), sload(handoverSlot)) {
                mstore(0x00, 0x6f5e8818) // `NoHandoverRequest()`.
                revert(0x1c, 0x04)
            }
            // Set the handover slot to 0.
            sstore(handoverSlot, 0)
        }
        _setOwner(pendingOwner);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the owner of the contract.
    function owner() public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(not(_OWNER_SLOT_NOT))
        }
    }

    /// @dev Returns the expiry timestamp for the two-step ownership handover to `pendingOwner`.
    function ownershipHandoverExpiresAt(address pendingOwner)
        public
        view
        virtual
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the handover slot.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            // Load the handover slot.
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by the owner.
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "ERC1155P/contracts/IERC1155P.sol";

interface IBidTicket is IERC1155P {
    function setURI(uint256 tokenId, string calldata tokenURI) external;

    function mint(address to, uint256 id, uint256 amount) external;
    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts) external;

    function burn(address from, uint256 id, uint256 amount) external;
    function burnBatch(address from, uint256[] calldata ids, uint256[] calldata amounts) external;

    function setHarvestContract(address harvestContract_) external;
    function setAuctionsContract(address auctionsContract_) external;
}

// SPDX-License-Identifier: MIT
// ERC721P Contracts v1.1

pragma solidity ^0.8.20;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155P {

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Arrays cannot be different lengths.
     */
    error ArrayLengthMismatch();

    /**
     * Cannot burn from the zero address.
     */
    error BurnFromZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The quantity of tokens being burned is greater than account balance.
     */
    error BurnExceedsBalance();

    /**
     * The quantity of tokens being transferred is greater than account balance.
     */
    error TransferExceedsBalance();

    /**
     * The resulting token balance exceeds the maximum storable by ERC1155P
     */
    error ExceedsMaximumBalance();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC1155Receiver interface.
     */
    error TransferToNonERC1155ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * Exceeds max token ID
     */
    error ExceedsMaximumTokenId();
    
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

    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}