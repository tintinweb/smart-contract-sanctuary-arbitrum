// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC721Storage {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    struct Layout {
        // =============================================================
        //                            STORAGE
        // =============================================================
        mapping(uint256 => uint256) _totalSupply;
        bool _paused;
        // Optional base URI
        string _baseURI;
        // Optional mapping for token URIs
        mapping(uint256 => string) _tokenURIs;
        // The next token ID to be minted.
        uint256 _currentIndex;
        // The number of tokens burned.
        uint256 _burnCounter;
        // Token name
        string _name;
        // Token symbol
        string _symbol;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) _operatorApprovals;
        // Mapping from token ID to owner address
        mapping(uint256 => address) _owners;
        // Mapping owner address to token count
        mapping(address => uint256) _balances;
        // Mapping from token ID to approved address
        mapping(uint256 => address) _tokenApprovals;
        string _class0maleImage;
        string _class0femaleImage;
        string _class1maleImage;
        string _class1femaleImage;
        string _class2maleImage;
        string _class2femaleImage;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("ERC721A.contracts.storage.ERC721A");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";
import {ERC721Storage} from "../ERC721Storage.sol";
import {ERC721FacetInternal} from "./ERC721FacetInternal.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/IERC721Metadata.sol";
import "../interfaces/IERC721Receiver.sol";
import "../utils/Context.sol";
import "../utils/ERC165.sol";
import "../utils/Address.sol";
import "../utils/Strings.sol";
import "../ERC721Storage.sol";
import "../utils/Base64.sol";

library PlayerStorageLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("player.test.storage.a");

    using PlayerSlotLib for PlayerSlotLib.Player;

    /// @dev Struct defining player storage
    struct PlayerStorage {
        uint256 totalSupply;
        uint256 playerCount;
        mapping(uint256 => address) owners;
        mapping(uint256 => PlayerSlotLib.Player) players;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        mapping(string => bool) usedNames;
        mapping(address => uint256[]) addressToPlayers;
        mapping(uint256 => PlayerSlotLib.Slot) slots;
    }

    /// @dev Function to retrieve diamond storage slot for player data. Returns a reference.
    function diamondStorage() internal pure returns (PlayerStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function _getPlayer(uint256 _id) internal view returns (PlayerSlotLib.Player memory player) {
        PlayerStorage storage s = diamondStorage();
        player = s.players[_id];
    }
}

contract ERC721Facet is ERC721FacetInternal {
    using ERC721Storage for ERC721Storage.Layout;
    using Address for address;
    using Strings for uint256;
    using PlayerSlotLib for PlayerSlotLib.Player;

    /**
     * @dev See {IERC721-balanceOf}.
     */

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return ERC721Storage.layout()._balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return ERC721Storage.layout()._name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return ERC721Storage.layout()._symbol;
    }

    function constructAttributes(PlayerSlotLib.Player memory player) internal pure returns (string memory attributes) {
        attributes = string(
            abi.encodePacked(
                '[{"trait_type":"Level","value":"',
                player.level.toString(),
                '"},',
                '{"trait_type":"XP","value":"',
                player.xp.toString(),
                '"},',
                '{"trait_type":"Status","value":"',
                player.status.toString(),
                '"},',
                '{"trait_type":"Gender","value":"',
                player.male ? "Male" : "Female",
                '"},',
                '{"trait_type":"Class","value":"',
                player.playerClass,
                '"},',
                '{"trait_type":"Strength","value":"',
                player.strength.toString(),
                '"}]'
            )
        );
    }

    //Finds an image for the player based on the player class
    function findImageBasedOnPlayerClass(PlayerSlotLib.Player memory player)
        internal
        view
        returns (string memory image)
    {
        if (player.playerClass == PlayerSlotLib.PlayerClass.Warrior) {
            if(player.male){
                image = ERC721Storage.layout()._class0maleImage;
            } else {
                image = ERC721Storage.layout()._class0femaleImage;
            }
        } else if (player.playerClass == PlayerSlotLib.PlayerClass.Assasin) {
            if(player.male){
                image = ERC721Storage.layout()._class1maleImage;
            } else {
                image = ERC721Storage.layout()._class1femaleImage;
            }
            
        } else if (player.playerClass == PlayerSlotLib.PlayerClass.Mage) {
            if(player.male){
                image = ERC721Storage.layout()._class2maleImage;
            } else {
                image = ERC721Storage.layout()._class2femaleImage;
            }
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireMinted(tokenId);

        PlayerSlotLib.Player memory player = PlayerStorageLib._getPlayer(tokenId);
        string memory attributes = constructAttributes(player);
        string memory base = "data:application/json;base64,";
        string memory image = findImageBasedOnPlayerClass(player);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"', player.name, '", "attributes":', attributes, ', "image":"', image, '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked(base, json));
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        address owner = _ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireMinted(tokenId);

        return ERC721Storage.layout()._tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return ERC721Storage.layout()._operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";
import {ERC721Storage} from "../ERC721Storage.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/IERC721Metadata.sol";
import "../interfaces/IERC721Receiver.sol";
import "../utils/Context.sol";
import "../utils/ERC165.sol";
import "../utils/Address.sol";
import "../utils/Strings.sol";
import "../ERC721Storage.sol";

contract ERC721FacetInternal is Context {
    using ERC721Storage for ERC721Storage.Layout;
    using Address for address;
    using Strings for uint256;

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            ERC721Storage.layout()._balances[to] += 1;
        }

        ERC721Storage.layout()._owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = _ownerOf(tokenId);

        // Clear approvals
        delete ERC721Storage.layout()._tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            ERC721Storage.layout()._balances[owner] -= 1;
        }
        delete ERC721Storage.layout()._owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        ERC721Storage.layout()._tokenApprovals[tokenId] = to;
        emit Approval(_ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return ERC721Storage.layout()._owners[tokenId];
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return ERC721Storage.layout()._baseURI;
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        ERC721Storage.layout()._operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(_ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(_ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete ERC721Storage.layout()._tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            ERC721Storage.layout()._balances[from] -= 1;
            ERC721Storage.layout()._balances[to] += 1;
        }
        ERC721Storage.layout()._owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = _ownerOf(tokenId);
        return (
            spender == owner || ERC721Storage.layout()._operatorApprovals[owner][spender]
                || ERC721Storage.layout()._tokenApprovals[tokenId] == spender
        );
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data)
        private
        returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";
import {ERC721Facet} from "./ERC721Facet.sol";
import {ERC721FacetInternal} from "./ERC721FacetInternal.sol";
import "../utils/Strings.sol";
import "../utils/Base64.sol";
import "../ERC721Storage.sol";
import "../interfaces/IGateway.sol";

/// @title Player Storage Library
/// @dev Library for managing storage of player data
library PlayerStorageLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant TRANSFER_STORAGE_POSITION = keccak256("transfer.test.storage.a");

    using PlayerSlotLib for PlayerSlotLib.Player;
    using PlayerSlotLib for PlayerSlotLib.Slot;
    using PlayerSlotLib for PlayerSlotLib.TokenTypes;

    /// @dev Struct defining player storage
    struct PlayerStorage {
        uint256 totalSupply;
        uint256 playerCount;
        mapping(uint256 => address) owners;
        mapping(uint256 => PlayerSlotLib.Player) players;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        mapping(string => bool) usedNames;
        mapping(address => uint256[]) addressToPlayers;
        mapping(uint256 => PlayerSlotLib.Slot) slots;
    }

    // transfer params struct where we specify which NFTs should be transferred to
    // the destination chain and to which address
    struct TransferParams {
        uint256 nftId;
        uint256 playerId;
        PlayerSlotLib.Player playerData;
        address recipient;
    }

    struct TransferRemote {
        string _destination;
        address _recipientAsAddress;
        string _recipientAsString;
        uint256 _playerId;
    }

    struct TransferStorage {
        mapping(string => string) ourContractOnChains;
        IGateway gatewayContract;
        uint256 test;
    }

    /// @dev Function to retrieve diamond storage slot for player data. Returns a reference.
    function diamondStorage() internal pure returns (PlayerStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function diamondStorageTransfer() internal pure returns (TransferStorage storage ds) {
        bytes32 position = TRANSFER_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function _setContractOnChain(string calldata _chainId, string calldata _contractAddress) internal {
        TransferStorage storage s = diamondStorageTransfer();
        s.ourContractOnChains[_chainId] = _contractAddress;
        s.test++;
    }

    function _setGateway(address _gateway, string calldata _feePayer) internal {
        TransferStorage storage s = diamondStorageTransfer();
        s.gatewayContract = IGateway(_gateway);

        s.gatewayContract.setDappMetadata(_feePayer);
    }

    function _getTransferParams(string calldata _chainId)
        internal
        view
        returns (address gateway, string storage contractOnChain, uint256 test)
    {
        TransferStorage storage s = diamondStorageTransfer();

        gateway = address(s.gatewayContract);
        contractOnChain = s.ourContractOnChains[_chainId];
        test = s.test;
    }

    function _deletePlayer(address _sender, uint256 _playerId) internal {
        PlayerStorage storage s = diamondStorage();
        require(s.owners[_playerId] == _sender);
        require(_playerId <= s.playerCount, "Player does not exist");

        // Reset Player data - TODO
        // PlayerSlotLib.Player storage playerToDelete = s.players[_playerId];
        // playerToDelete = PlayerSlotLib.Player({/*...initialize with default values...*/});

        // Reset owner data
        s.owners[_playerId] = address(0);

        // Reduce the balance of the player's owner
        s.balances[s.owners[_playerId]] = 0;

        // Clear allowances
        s.allowances[s.owners[_playerId]][address(this)] = 0;

        // Decrement playerCount
        s.playerCount--;

        // Remove player from the addressToPlayers mapping
        uint256[] storage playerIds = s.addressToPlayers[s.owners[_playerId]];
        for (uint256 i = 0; i < playerIds.length; i++) {
            if (playerIds[i] == _playerId) {
                playerIds[i] = playerIds[playerIds.length - 1];
                playerIds.pop();
                break;
            }
        }

        // Delete player's slot
        delete s.slots[_playerId];
    }

    function _transferRemote(TransferRemote memory params)
        internal
        returns (address gatewayContractAddress, bytes memory requestPacket)
    {
        TransferStorage storage t = diamondStorageTransfer();
        require(
            keccak256(abi.encodePacked(t.ourContractOnChains[params._destination])) != keccak256(abi.encodePacked("")),
            "contract on dest not set"
        );

        PlayerStorage storage s = diamondStorage();
        PlayerSlotLib.Player memory player = s.players[params._playerId];

        TransferParams memory transferParams = TransferParams({
            nftId: params._playerId,
            playerId: params._playerId,
            playerData: player,
            recipient: params._recipientAsAddress
        });

        // sending the transfer params struct to the destination chain as payload.
        bytes memory packet = abi.encode(transferParams);
        requestPacket = abi.encode(t.ourContractOnChains[params._destination], packet);
        gatewayContractAddress = address(t.gatewayContract);

        _deletePlayer(msg.sender, params._playerId);
        t.test++;
    }

    /// @notice function to handle the cross-chain request received from some other chain.
    /// @param packet the payload sent by the source chain contract when the request was created.
    /// @param srcChainId chain ID of the source chain in string.
    function _iReceive(bytes memory packet, string memory srcChainId)
        internal
        returns (address recipient, uint256 nftId, bytes memory chainId)
    {
        TransferStorage storage t = diamondStorageTransfer();
        require(msg.sender == address(t.gatewayContract), "only gateway");
        // decoding our payload
        TransferParams memory transferParams = abi.decode(packet, (TransferParams));
        recipient = transferParams.recipient;
        nftId = transferParams.nftId;
        _mintCrossChainPlayer(transferParams.playerData, recipient);
        t.test++;
        chainId = abi.encode(srcChainId);
    }

    function _mintCrossChainPlayer(PlayerSlotLib.Player memory _player, address _recipient) internal {
        PlayerStorage storage s = diamondStorage();
        require(!s.usedNames[_player.name], "name is taken");
        require(bytes(_player.name).length <= 10);
        require(bytes(_player.name).length >= 3);
        // require(_playerId > s.playerCount);
        s.playerCount++;
        s.players[s.playerCount] = PlayerSlotLib.Player(
            _player.level,
            _player.xp,
            _player.status,
            _player.strength,
            _player.health,
            _player.currentHealth,
            _player.magic,
            _player.mana,
            _player.maxMana,
            _player.agility,
            _player.luck,
            _player.wisdom,
            _player.haki,
            _player.perception,
            _player.defense,
            _player.name,
            _player.uri,
            _player.male,
            PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0),
            PlayerSlotLib.PlayerClass(_player.playerClass)
        );
        s.slots[s.playerCount] = PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0);
        s.usedNames[_player.name] = true;
        s.owners[s.playerCount] = _recipient;
        s.addressToPlayers[_recipient].push(s.playerCount);
        s.balances[_recipient]++;
    }

    /// @notice Mints a new player
    /// @param _name The name of the player
    /// @param _isMale The gender of the player
    function _mint(string memory _name, bool _isMale, uint256 _class) internal {
        PlayerStorage storage s = diamondStorage();
        require(!s.usedNames[_name], "name is taken");
        require(_class <= 2);
        require(bytes(_name).length <= 10);
        require(bytes(_name).length >= 3);
        s.playerCount++;
        string memory uri;
        if (_class == 0) {
            //warrior
            _isMale
                ? uri = "https://ipfs.io/ipfs/QmV5pSsMGGMLW3Y9yQ8qSLSMDQakdnjhjS4k5he6mJyPeH"
                : uri = "https://ipfs.io/ipfs/QmfBNHpxpwUNgtw6iXBxKXLbVxom8mpdBsgqZZy59pRM5C";
            s.players[s.playerCount] = PlayerSlotLib.Player(
                1,
                0,
                0,
                1,
                10,
                10,
                1,
                1,
                1,
                1,
                1,
                1,
                1,
                1,
                1,
                _name,
                uri,
                _isMale,
                PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0),
                PlayerSlotLib.PlayerClass.Warrior
            );
        } else if (_class == 1) {
            //assasin
            _isMale
                ? uri = "https://ipfs.io/ipfs/QmQXeYe9rxRkkqfEB7DrZRSG2S1yrNgj64V8m6v7KetzQd"
                : uri = "https://ipfs.io/ipfs/QmUqZKRudnang1GXbD2nHHwmJfNNBFQVdmoH8WAneaii5h";
            s.players[s.playerCount] = PlayerSlotLib.Player(
                1,
                0,
                0,
                1,
                10,
                10,
                1,
                1,
                1,
                1,
                1,
                1,
                1,
                1,
                1,
                _name,
                uri,
                _isMale,
                PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0),
                PlayerSlotLib.PlayerClass.Assasin
            );
        } else if (_class == 2) {
            //mage
            _isMale
                ? uri = "https://ipfs.io/ipfs/QmUbWxUd8sX4MZojKERUPmPu9YtAYfYroBS4Te1HJEKucy"
                : uri = "https://ipfs.io/ipfs/QmbVABt9sKpNUa8DgMJde3DBCQyorSCT9V1Dzd6cJ8ZUmP";
            s.players[s.playerCount] = PlayerSlotLib.Player(
                1,
                0,
                0,
                1,
                10,
                10,
                1,
                1,
                1,
                1,
                1,
                1,
                1,
                1,
                1,
                _name,
                uri,
                _isMale,
                PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0),
                PlayerSlotLib.PlayerClass.Mage
            );
        }
        s.slots[s.playerCount] = PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0);
        s.usedNames[_name] = true;
        s.owners[s.playerCount] = msg.sender;
        s.addressToPlayers[msg.sender].push(s.playerCount);
        s.balances[msg.sender]++;
    }

    function _playerCount() internal view returns (uint256) {
        PlayerStorage storage s = diamondStorage();
        return s.playerCount;
    }

    function _nameAvailable(string memory _name) internal view returns (bool) {
        PlayerStorage storage s = diamondStorage();
        return s.usedNames[_name];
    }

    /// @notice Changes the name of a player
    /// @param _id The id of the player
    /// @param _newName The new name of the player
    function _changeName(uint256 _id, string memory _newName) internal {
        PlayerStorage storage s = diamondStorage();
        require(s.owners[_id] == msg.sender);
        require(!s.usedNames[_newName], "name is taken");
        require(bytes(_newName).length > 3, "Cannot pass an empty hash");
        require(bytes(_newName).length < 10, "Cannot be longer than 10 chars");
        string memory existingName = s.players[_id].name;
        if (bytes(existingName).length > 0) {
            delete s.usedNames[existingName];
        }
        s.players[_id].name = _newName;
        s.usedNames[_newName] = true;
    }

    function _getPlayer(uint256 _id) internal view returns (PlayerSlotLib.Player memory player) {
        PlayerStorage storage s = diamondStorage();
        player = s.players[_id];
    }

    function _ownerOf(uint256 _id) internal view returns (address owner) {
        PlayerStorage storage s = diamondStorage();
        owner = s.owners[_id];
    }

    /// @notice Transfer the player to someone else
    /// @param _to Address of the account where the caller wants to transfer the player
    /// @param _id ID of the player to transfer
    function _transfer(address _to, uint256 _id) internal {
        PlayerStorage storage s = diamondStorage();
        require(s.owners[_id] == msg.sender);
        require(_to != address(0), "_to cannot be zero address");
        s.owners[_id] = _to;

        //Note - storing this in a memory variable to save gas
        uint256 balances = s.balances[msg.sender];
        for (uint256 i = 0; i < balances; i++) {
            if (s.addressToPlayers[msg.sender][i] == _id) {
                delete s.addressToPlayers[msg.sender][i];
                break;
            }
        }
        s.balances[msg.sender]--;
        s.balances[_to]++;
    }

    function _getPlayers(address _address) internal view returns (uint256[] memory) {
        PlayerStorage storage s = diamondStorage();
        return s.addressToPlayers[_address];
    }

    function _levelUp(uint256 _playerId, uint256 _stat) internal {
        PlayerStorage storage s = diamondStorage();
        PlayerSlotLib.Player memory player = s.players[_playerId];
        require(player.xp >= player.level * 10); //require the player has enough xp to level up, at least 10 times their level
        if (_stat == 0) {
            //if strength
            s.players[_playerId].strength++;
        } else if (_stat == 1) {
            //if health
            s.players[_playerId].health++;
            s.players[_playerId].currentHealth = s.players[_playerId].health;
        } else if (_stat == 2) {
            //if agility
            s.players[_playerId].agility++;
        } else if (_stat == 3) {
            //if magic
            s.players[_playerId].magic++;
        } else if (_stat == 4) {
            //if defense
            player.defense += player.level;
        } else if (_stat == 5) {
            // if luck
            player.luck += player.level;
        } else {
            // must be haki
            player.haki += player.level;
        }
        s.players[_playerId].xp = player.xp - (player.level * 10); //subtract xp form the player
        s.players[_playerId].level++; //level up the player
    }
}

/// @title Player Facet
/// @dev Contract managing interaction with player data
contract PlayerFacet is ERC721FacetInternal {
    // contract PlayerFacet {
    using Strings for uint256;

    event Mint(uint256 indexed id, address indexed owner, string name, uint256 _class);
    event NameChange(address indexed owner, uint256 indexed id, string indexed newName);

    /**
     * @dev Emitted on `transferRemote` when a transfer message is dispatched.
     * @param destination The identifier of the destination chain.
     * @param recipient The address of the recipient on the destination chain.
     * @param playerId The amount of tokens burnt on the origin chain.
     */
    event SentTransferRemote(string destination, address indexed recipient, uint256 playerId);

    function playerCount() public view returns (uint256) {
        return PlayerStorageLib._playerCount();
    }

    // Through this function, set the address of the corresponding contract on the destination chain
    function setContractOnChain(string calldata _chainId, string calldata _contractAddress) external {
        PlayerStorageLib._setContractOnChain(_chainId, _contractAddress);
    }

    // Set the gateway contract address from https://docs.routerprotocol.com/develop/message-transfer-via-crosstalk/evm-guides/your-first-crosschain-nft-contract/deploying-your-nft-contract
    function setGateway(address gateway, string calldata feePayer) external {
        PlayerStorageLib._setGateway(gateway, feePayer);
    }

    function getTransferParams(string calldata _chainId)
        external
        view
        returns (address gateway, string memory contractOnChain, uint256 test)
    {
        (gateway, contractOnChain, test) = PlayerStorageLib._getTransferParams(_chainId);
    }

    /// @notice function to get the request metadata to be used while initiating cross-chain request
    /// @return requestMetadata abi-encoded metadata according to source and destination chains
    function getRequestMetadata(
        uint64 _destGasLimit,
        uint64 _destGasPrice,
        uint64 _ackGasLimit,
        uint64 _ackGasPrice,
        uint128 _relayerFees,
        uint8 _ackType,
        bool _isReadCall,
        bytes memory _asmAddress
    ) public pure returns (bytes memory) {
        bytes memory requestMetadata = abi.encodePacked(
            _destGasLimit, _destGasPrice, _ackGasLimit, _ackGasPrice, _relayerFees, _ackType, _isReadCall, _asmAddress
        );
        return requestMetadata;
    }

    /**
     * @dev Transfers a player to a remote chain using the Router Gateway.
     * @param _destination The name of the destination chain.
     * @param _recipientAsAddress The address of the recipient on the destination chain.
     * @param _recipientAsString The string representation of the recipient on the destination chain.
     * @param _playerId The ID of the player to transfer.
     * @param _requestMetadata Additional metadata to include in the request packet.
     * Requirements:
     * - The player must exist in the local storage.
     * - The player must be burned after the transfer.
     * Emits a {SentTransferRemote} event.
     */
    function transferRemote(
        string calldata _destination,
        address _recipientAsAddress,
        string calldata _recipientAsString,
        uint256 _playerId,
        bytes memory _requestMetadata
    ) public payable {
        // Call the _transferRemote function in the PlayerStorageLib library to get the gateway contract address and request packet.
        (address gatewayContractAddress, bytes memory requestPacket) = PlayerStorageLib._transferRemote(
            PlayerStorageLib.TransferRemote({
                _destination: _destination,
                _recipientAsAddress: _recipientAsAddress,
                _recipientAsString: _recipientAsString,
                _playerId: _playerId
            })
        );

        // Get the Router Gateway contract instance.
        IGateway gatewayContract = IGateway(gatewayContractAddress);

        // Call the iSend function on the Router Gateway contract to send the request packet to the destination chain.
        gatewayContract.iSend{value: msg.value}(1, 0, string(""), _destination, _requestMetadata, requestPacket);

        // Burn the player after the transfer.
        _burn(_playerId);

        // Emit a SentTransferRemote event.
        emit SentTransferRemote(_destination, _recipientAsAddress, _playerId);
    }

    /// @notice function to handle the cross-chain request received from some other chain.
    /// @param packet the payload sent by the source chain contract when the request was created.
    /// @param srcChainId chain ID of the source chain in string.
    function iReceive(
        string memory, // requestSender,
        bytes memory packet,
        string memory srcChainId
    ) internal returns (bytes memory) {
        // decoding our payload
        (address recipient, uint256 nftId, bytes memory toChainId) = PlayerStorageLib._iReceive(packet, srcChainId);
        _safeMint(recipient, nftId);

        return abi.encode(toChainId);
    }

    /// @notice Mints a new player
    /// @dev Emits a Mint event
    /// @dev Calls the _mint function from the PlayerStorageLib
    /// @param _name The name of the player
    /// @param _isMale The gender of the player
    function mint(string memory _name, bool _isMale, uint256 _class) external {
        PlayerStorageLib._mint(_name, _isMale, _class);
        uint256 count = playerCount();
        emit Mint(count, msg.sender, _name, _class);

        //TODO - somehow
        _safeMint(msg.sender, count);
    }

    /// @notice Changes the name of a player
    /// @dev Emits a NameChange event
    /// @param _id The id of the player
    /// @param _newName The new name of the player
    function changeName(uint256 _id, string memory _newName) external {
        PlayerStorageLib._changeName(_id, _newName);
        emit NameChange(msg.sender, _id, _newName);
    }

    /// @notice Retrieves a player
    /// @param _playerId The id of the player
    /// @return player The player data
    function getPlayer(uint256 _playerId) external view returns (PlayerSlotLib.Player memory player) {
        player = PlayerStorageLib._getPlayer(_playerId);
    }

    function nameAvailable(string memory _name) external view returns (bool available) {
        available = PlayerStorageLib._nameAvailable(_name);
    }

    function ownerOfPlayer(uint256 _playerId) external view returns (address owner) {
        owner = PlayerStorageLib._ownerOf(_playerId);
    }

    /// @notice Retrieves the players owned by an address
    /// @param _address The owner address
    /// @return An array of player ids
    function getPlayers(address _address) external view returns (uint256[] memory) {
        return PlayerStorageLib._getPlayers(_address);
    }

    /// @notice Retrieves the current block timestamp
    /// @return The current block timestamp
    function getBlocktime() external view returns (uint256) {
        return (block.timestamp);
    }

    function levelUp(uint256 _playerId, uint256 _stat) external {
        PlayerStorageLib._levelUp(_playerId, _stat);
    }

    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../libraries/RouterUtils.sol";

/**
 * @dev Interface of the Gateway Self External Calls.
 */
interface IGateway {
    // requestMetadata = abi.encodePacked(
    //     uint256 destGasLimit;
    //     uint256 destGasPrice;
    //     uint256 ackGasLimit;
    //     uint256 ackGasPrice;
    //     uint256 relayerFees;
    //     uint8 ackType;
    //     bool isReadCall;
    //     bytes asmAddress;
    // )

    function iSend(
        uint256 version,
        uint256 routeAmount,
        string calldata routeRecipient,
        string calldata destChainId,
        bytes calldata requestMetadata,
        bytes calldata requestPacket
    ) external payable returns (uint256);

    function setDappMetadata(string memory feePayerAddress) external payable returns (uint256);

    function currentVersion() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PlayerSlotLib {
    struct Player {
        uint256 level;
        uint256 xp;
        uint256 status;
        uint256 strength;
        uint256 health;
        uint256 currentHealth;
        uint256 magic;
        uint256 mana;
        uint256 maxMana;
        uint256 agility;
        uint256 luck;
        uint256 wisdom;
        uint256 haki;
        uint256 perception;
        uint256 defense;
        string name;
        string uri;
        bool male;
        Slot slot;
        PlayerClass playerClass;
    }

    // slots {
    //     0: head;
    //     1: body;
    //     2: lefthand;
    //     3: rightHand;
    //     4: pants;
    //     5: feet;
    // }

    // StatusCodes {
    //     0: idle;
    //     1: combatTrain;
    //     2: goldQuest;
    //     3: manaTrain;
    //     4: Arena;
    //     5: gemQuest;
    // }

    struct Slot {
        uint256 head;
        uint256 body;
        uint256 leftHand;
        uint256 rightHand;
        uint256 pants;
        uint256 feet;
        uint256 neck;
    }

    enum TokenTypes {
        PlayerMale,
        PlayerFemale,
        Guitar,
        Sword,
        Armor,
        Helmet,
        WizHat,
        SorcShoes,
        GemSword,
        GoldCoin,
        GemCoin,
        TotemCoin,
        DiamondCoin
    }

    enum PlayerClass {
        Warrior,
        Assasin,
        Mage
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Utils {
    // This is used purely to avoid stack too deep errors
    // represents everything about a given validator set
    struct ValsetArgs {
        // the validators in this set, represented by an Ethereum address
        address[] validators;
        // the powers of the given validators in the same order as above
        uint64[] powers;
        // the nonce of this validator set
        uint256 valsetNonce;
    }

    struct RequestPayload {
        uint256 routeAmount;
        uint256 requestIdentifier;
        uint256 requestTimestamp;
        string srcChainId;
        address routeRecipient;
        string destChainId;
        address asmAddress;
        string requestSender;
        address handlerAddress;
        bytes packet;
        bool isReadCall;
    }

    struct CrossChainAckPayload {
        uint256 requestIdentifier;
        uint256 ackRequestIdentifier;
        string destChainId;
        address requestSender;
        bytes execData;
        bool execFlag;
    }

    enum AckType {
        NO_ACK,
        ACK_ON_SUCCESS,
        ACK_ON_ERROR,
        ACK_ON_BOTH
    }

    error IncorrectCheckpoint();
    error InvalidValsetNonce(uint256 newNonce, uint256 currentNonce);
    error MalformedNewValidatorSet();
    error MalformedCurrentValidatorSet();
    error InsufficientPower(uint64 cumulativePower, uint64 powerThreshold);
    error InvalidSignature();
    // constants

    string constant MSG_PREFIX = "\x19Ethereum Signed Message:\n32";
    // The number of 'votes' required to execute a valset
    // update or batch execution, set to 2/3 of 2^32
    uint64 constant CONSTANT_POWER_THRESHOLD = 2791728742;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage)
        internal
        returns (bytes memory)
    {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage)
        internal
        returns (bytes memory)
    {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage)
        internal
        view
        returns (bytes memory)
    {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage)
        internal
        pure
        returns (bytes memory)
    {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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
            } lt(dataPtr, endPtr) {} {
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
            case 2 { mstore8(sub(resultPtr, 1), 0x3d) }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC165.sol";

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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./Math.sol";

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
}