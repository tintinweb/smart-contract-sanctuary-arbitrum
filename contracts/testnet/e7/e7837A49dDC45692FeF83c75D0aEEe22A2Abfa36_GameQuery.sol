pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
pragma abicoder v2;
//import "../lib/forge-std/src/console.sol";

import "./IBattleRoyaleNFT.sol";
import "./IBattleRoyaleGameV1.sol";
import "./libraries/PlayerDataHelper.sol";

contract GameQuery {

    struct GameData {
        address gameAddress;
        IBattleRoyaleGameV1.GameConfig config;
        IBattleRoyaleGameV1.GameState state;
        uint currentPlayerCount;
        bool playerIsEntered;
    }

    function allGames(IBattleRoyaleNFT nft, address player) external view returns (GameData[] memory games) {
        address[] memory gameAddresses = nft.games();
        GameData[] memory tempGames = new GameData[](gameAddresses.length);
        uint gameIndex = 0;
        for (uint i = 0; i < gameAddresses.length; i++) {
            IBattleRoyaleGameV1 game = IBattleRoyaleGameV1(gameAddresses[i]);
            try game.gameConfig() returns (IBattleRoyaleGameV1.GameConfig memory config) {
                tempGames[gameIndex++] = GameData({
                    gameAddress: gameAddresses[i],
                    config: config,
                    state: game.gameState(),
                    currentPlayerCount: game.playerCount(),
                    playerIsEntered: game.playersData(player) != 0
                });
            } catch (bytes memory) {
                continue;
            }
        }
        games = new GameData[](gameIndex);
        for (uint i = 0; i < gameIndex; i++) {
            games[i] = tempGames[i];
        }
    }

    struct PlayerData {
        address playerAddress;
        uint tick;
        uint posX;
        uint posY;
        uint[] tokenIds;
        uint[] tokenProperties;
    }
    function onePlayer(IBattleRoyaleGameV1 game, address addr) public view returns (PlayerData memory playerData) {
        (, uint pos, uint tick, uint[] memory tokenIds) = game.playerProperty(addr);
        if (pos == PlayerDataHelper.MAX_POS) {
            pos = game.playerSpawnPos(addr);
        }
        IBattleRoyaleNFT nft = game.nft();

        uint[] memory properties = new uint[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++) {
            properties[i] = nft.tokenProperty(tokenIds[i]);
        }
        playerData = PlayerData({
            playerAddress: addr,
            tick: tick,
            posX: pos & 0xff,
            posY: (pos >> 8) & 0xff,
            tokenIds: tokenIds,
            tokenProperties: properties
        });
    }

    function allPlayers(IBattleRoyaleGameV1 game) external view returns (PlayerData[] memory players) {
        uint count = game.playerCount();
        players = new PlayerData[](count);
        for(uint i = 0; i < count; i++) {
            players[i] = onePlayer(game, game.players(i));
        }
    }

    function allTiles(IBattleRoyaleGameV1 game) external view returns(uint[] memory tiles) {
        uint tileSize = game.gameConfig().mapSize / 8;
        tiles = new uint[](tileSize * tileSize);
        for(uint i = 0; i < tileSize; i++) {
            for (uint j = 0; j < tileSize; j++) {
                tiles[i * tileSize + j] = game.tilemap(i * tileSize + j);
            }
        }
        return tiles;
    }

    function canForceRemovePlayers(IBattleRoyaleGameV1 game) external view returns(address[] memory players) {
        uint count = game.playerCount();
        address[] memory tempPlayers = new address[](count);
        uint index = 0;
        for (uint i = 0; i < count; i++) {
            address addr = game.players(i);
            if (game.canForceRemovePlayer(addr)) {
                tempPlayers[index++] = addr;
            }
        }
        players = new address[](index);
        for(uint i = 0; i < index; i++) {
            players[i] = tempPlayers[i];
        }
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
pragma abicoder v2;
//import "../lib/forge-std/src/console.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IBattleRoyaleNFT is IERC721Enumerable {
    function tokenType(uint tokenId) external view returns (uint);
    function tokenProperty(uint tokenId) external view returns (uint);
    function nextTokenId() external view returns (uint);

    function burn(uint256 tokenId) external;

    function setProperty(uint tokenId, uint newProperty) external;
    function mintByGame(address to, uint property) external returns (uint);

    function games() external view returns (address[] memory);
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
pragma abicoder v2;
//import "hardhat/console.sol";
//import "../lib/forge-std/src/console.sol";
import "./IBattleRoyaleNFT.sol";

interface IBattleRoyaleGameV1 {
    enum TileType {
        None, // nothing here, player can pass through, bullet can pass through, not destroyable
        Water, // player cannot pass through, bullet can pass through, not destroyable
        Mountain, // player cannot pass through, bullet cannot pass through, not destroyable
        Wall, // player cannot pass through, bullet cannot pass through, destroyable
        ChestBox // player cannot pass through, bullet cannot pass through, destroyable
    }

    event RegisterGame(uint indexed round, address indexed player, bool indexed isRegister, uint[] tokenIds);
    event ActionMove(uint indexed round, address indexed player, uint startPos, uint[] path);
    event ActionShoot(uint indexed round, address indexed player, uint fromPos, uint targetPos, bool hitSucceed);
    event ActionPick(uint indexed round, address indexed player);
    event ActionDrop(uint indexed round, address indexed player);
    event ActionBomb(uint indexed round, address indexed player, uint fromPos, uint targetPos, uint explosionRange);
    event ActionEat(uint indexed round, address indexed player, uint heal);

    event ActionDefend(uint indexed round, address indexed player, uint defense);
    event ActionDodge(uint indexed round, address indexed player, bool succeed);

    event PlayerHurt(uint indexed round, address indexed player, uint damage);
    event PlayerKilled(uint indexed round, address indexed player);
    event PlayerWin(uint indexed round, address indexed player, uint tokenReward, uint nftReward);

    event TileChanged(uint indexed round, uint pos);

    event TokensOnGroundChanged(uint indexed round, uint pos);

    event GameStateChanged();

    struct GameConfig {
        uint24 needPlayerCount;
        uint24 mapSize;
        // seconds in ont tick
        uint16 tickTime;
        // ticks in one game
        uint16 ticksInOneGame;
        uint16 forceRemoveTicks;
        uint16 forceRemoveRewardToken;
        uint8 moveMaxSteps;
        uint8 chestboxGenerateIntervalTicks;

        uint24 playerRewardToken;
        uint24 winnerRewardToken;
        uint8 winnerRewardNFT;

        uint24 playerBonusRewardToken;
        uint24 winnerBonusRewardToken;
        uint8 winnerBonusRewardNFT;

        uint8 tokenRewardTax;

        string name;
    }

    struct GameState {
        uint8 status;

        uint16 initedTileCount;
        uint24 round;
        uint40 startTime;
        uint16 newChestBoxLastTick;
        
        uint8 shrinkLeft;
        uint8 shrinkRight;
        uint8 shrinkTop;
        uint8 shrinkBottom;

        uint8 shrinkCenterX;
        uint8 shrinkCenterY;
        
        uint16 shrinkTick;
    }

    function gameConfig() external view returns (GameConfig memory);
    function gameState() external view returns (GameState memory);
    function playerCount() external view returns(uint);
    function playersData(address player) external view returns(uint);
    function players(uint index) external view returns(address);
    function playerProperty(address playerAddress) external view returns(uint keyIndex, uint pos, uint tick, uint[] memory tokenIds);
    function playerSpawnPos(address playerAddress) external view returns(uint playerPos);
    function nft() external view returns (IBattleRoyaleNFT nft);
    function tilemap(uint i) external view returns(uint tile);
    function canForceRemovePlayer(address playerAddress) external view returns(bool);
}

pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT


library PlayerDataHelper {

    // 2^16 - 1
    uint constant MAX_POS = 65535;

    /**
     * 0-8: keyIndex
     * 8-24: pos
     * 24-44: game tick
     * 44-48: token count
     * 48-248: tokenIds, max 10 tokenIds, 20 bits for one token, hope tokenId will not exceed 2^20
     */
    function encode(uint keyIndex, uint pos, uint gameTick, uint[] memory tokenIds) internal pure returns(uint r) {
        require(tokenIds.length <= 10, "No more than 10 tokenIds");
        require(keyIndex > 0, "keyIndex = 0");
        r |= keyIndex;
        r |= (pos << 8);
        r |= (gameTick << 24);
        r |= (tokenIds.length << 44);
        for (uint i = 0; i < tokenIds.length; i++) {
            r |= (tokenIds[i] << (48 + i * 20));
        }
    }

    function decode(uint encodeData) internal pure returns(uint keyIndex, uint pos, uint tick, uint[] memory tokenIds) {
        require(encodeData != 0, "No Player");
        keyIndex = encodeData & 0xff;
        pos = (encodeData >> 8) & 0xffff;
        tick = (encodeData >> 24) & 0xfffff;
        tokenIds = getTokenIds(encodeData);
    }

    function getTokenIds(uint encodeData) internal pure returns(uint[] memory tokenIds) {
        uint tokenCount = (encodeData >> 44) & 0xf;
        tokenIds = new uint[](tokenCount);
        for(uint i = 0; i < tokenCount; i++) {
            tokenIds[i] = (encodeData >> (48 + i * 20)) & 1048575;
        }
    }

    function firstTokenId(uint encodeData) internal pure returns(uint tokenId) {
        require(encodeData != 0, "No Player");
        return (encodeData >> 48) & 1048575;
    }

    function getPos(uint encodeData) internal pure returns(uint pos) {
        require(encodeData != 0, "No Player");
        pos = (encodeData >> 8) & 0xffff;
    }

    function getTokenCount(uint encodeData) internal pure returns(uint count) {
        require(encodeData != 0, "No Player");
        count = (encodeData >> 44) & 0xf;
    }

    function getTick(uint encodeData) internal pure returns(uint tick) {
        require(encodeData != 0, "No Player");
        tick = (encodeData >> 24) & 0xfffff;
    }

    function updateTick(uint encodeData, uint tick) internal pure returns(uint) {
        return (tick << 24) | (encodeData & (~uint(0xfffff << 24)));
    }

    function updatePos(uint encodeData, uint pos) internal pure returns(uint) {
        return (pos << 8) | (encodeData & (~uint(0xffff<<8)));
    }

    function getKeyIndex(uint encodeData) internal pure returns(uint) {
        require(encodeData != 0, "No Player");
        return encodeData & 0xff;
    }

    function updateKeyIndex(uint encodeData, uint keyIndex) internal pure returns(uint) {
        return keyIndex | (encodeData & (~uint(0xff)));
    }

    function removeTokenAt(uint encodeData, uint index) internal pure returns(uint) {
        uint part1 = encodeData & 0xfffffffffff;
        uint tokenCount = (encodeData >> 44) & 0xf;
        require(index < tokenCount, "RT");
        uint tokens = encodeData >> 48;
        uint newtokens = (tokens & ((1 << (index * 20)) - 1)) | ((tokens >> 20) & (type(uint).max << (index * 20)));
        return part1 | ((tokenCount - 1) << 44) | (newtokens << 48);
    }

    function addToken(uint encodeData, uint tokenId, uint bagCapacity) internal pure returns(uint) {
        uint tokenCount = (encodeData >> 44) & 0xf;
        require(tokenCount < 10 && tokenCount < bagCapacity + 1, "AT");
        return (((encodeData & ~uint(0xf << 44)) | ((tokenCount + 1) << 44)) & ~uint(0xfffff << (48 + tokenCount * 20))) | (tokenId << (48 + tokenCount * 20));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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