pragma solidity >=0.8.0 <0.9.0;

pragma abicoder v2;

//SPDX-License-Identifier: MIT
import "./PlayerDataHelper.sol";
import "./TokenOnGroundHelper.sol";
import "../IBattleRoyaleGameV1.sol";

library GameView {
    function playerSpawnPos(mapping(uint => uint) storage tilemap, uint mapSeed, uint mapSize, address playerAddress) internal view returns(uint playerPos) {
        for(uint j = 0;;j++) {
            uint index = uint(keccak256(abi.encodePacked(mapSeed, playerAddress, j))) % (mapSize * mapSize);
            uint x = index % mapSize;
            uint y = index / mapSize;
            if (getTileType(tilemap, x, y, mapSize) == IBattleRoyaleGameV1.TileType.None) {
                return x + (y<<8);
            }
        }
    }

    function getPlayerPos(mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, uint mapSeed, uint mapSize, address playerAddress) internal returns(uint pos) {
        uint data = playersData[playerAddress];
        pos = PlayerDataHelper.getPos(data);
        // initial position
        if (pos == PlayerDataHelper.MAX_POS) {
            pos = playerSpawnPos(tilemap, mapSeed, mapSize, playerAddress);
            playersData[playerAddress] = PlayerDataHelper.updatePos(data, pos);
        }
    }

    function getPlayerPosView(mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, uint mapSeed, uint mapSize, address playerAddress) public view returns(uint pos) {
        uint data = playersData[playerAddress];
        pos = PlayerDataHelper.getPos(data);
        // initial position
        if (pos == PlayerDataHelper.MAX_POS) {
            pos = playerSpawnPos(tilemap, mapSeed, mapSize, playerAddress);
        }
    }

    function gameTick(uint startTime, uint tickTime) internal view returns(uint) {
        return (block.timestamp - startTime) / tickTime + 1;
    }

    function shrinkRect(IBattleRoyaleGameV1.GameState memory state, IBattleRoyaleGameV1.GameConfig memory config) public view returns(uint left, uint top, uint right, uint bottom) {
        uint tick = gameTick(state.startTime, config.tickTime) - state.shrinkTick;
        uint ticksInOneGame = config.ticksInOneGame + 1 - state.shrinkTick;
        uint mapSize = config.mapSize;
        left = state.shrinkLeft + tick * (state.shrinkCenterX - state.shrinkLeft) / ticksInOneGame;
        top = state.shrinkTop + tick * (state.shrinkCenterY - state.shrinkTop) / ticksInOneGame;
        right = state.shrinkRight + tick * (mapSize - 1 - state.shrinkCenterX - state.shrinkRight) / ticksInOneGame;
        bottom = state.shrinkBottom + tick * (mapSize - 1 - state.shrinkCenterY - state.shrinkBottom) / ticksInOneGame;
    }

    function isOutOfShrinkCircle(mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, uint mapSeed, IBattleRoyaleGameV1.GameState memory state, IBattleRoyaleGameV1.GameConfig memory config, address playerAddress) public view returns(bool) {
        (uint left, uint top, uint right, uint bottom) = shrinkRect(state, config);
        uint mapSize = config.mapSize;
        uint pos = getPlayerPosView(playersData, tilemap, mapSeed, config.mapSize, playerAddress);
        (uint x, uint y) = decodePos(pos);
        return x < left || x + right >= mapSize || y < top || y + bottom >= mapSize;
    }

    function damageByShrinkCircle(mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, uint mapSeed, IBattleRoyaleGameV1.GameState memory state, IBattleRoyaleGameV1.GameConfig memory config, address playerAddress) public view returns(uint damage) {
        if (isOutOfShrinkCircle(playersData, tilemap, mapSeed, state, config, playerAddress)) {
            uint currentTick = gameTick(state.startTime, config.tickTime);
            uint tick = currentTick - PlayerDataHelper.getTick(playersData[playerAddress]);
            return 5 + tick + 10 * currentTick / config.ticksInOneGame;
        }
        return 0;
    }

    function getTileType(mapping(uint => uint) storage tilemap, uint x, uint y, uint mapSize) internal view returns(IBattleRoyaleGameV1.TileType) {
        uint tile = tilemap[ y / 8 * (mapSize / 8) + x / 8];
        return IBattleRoyaleGameV1.TileType((tile >> ((y % 8 * 8 + x % 8) * 4)) & 0xf);
    }

    function allTokensOnGround(mapping(uint => uint) storage tokensOnGround, uint round, uint fromX, uint fromY, uint toX, uint toY) internal view returns(uint[][] memory allTokenIds) {
        allTokenIds = new uint[][]((toX - fromX) * (toY - fromY));
        uint i = 0;
        for (uint y = fromY; y < toY; y++) {
            for (uint x = fromX; x < toX; x++) {
                allTokenIds[i] = TokenOnGroundHelper.tokens(tokensOnGround[x + (y << 8)], round);
                i += 1;
            }
        }
    }

    function decodePos(uint pos) internal pure returns(uint x, uint y) {
        x = pos & 0xff;
        y = (pos >> 8) & 0xff;
    }
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

pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

library TokenOnGroundHelper {

    /**
     * 0-12: game round
     * 12-16: token count
     * 16-256: max 12 token, 20 bits for one token
     */
    function tokens(uint encodeData, uint currentRound) internal pure returns(uint[] memory tokenIds) {
        if ((encodeData & 0xfff) == currentRound) {
            uint tokenCount = (encodeData >> 12) & 0xf;
            tokenIds = new uint[](tokenCount);
            for (uint i = 0; i < tokenCount; i++) {
                tokenIds[i] = (encodeData >> (16 + i * 20)) & 1048575;
            }
        } else {
            tokenIds = new uint[](0);
        }
    }

    function addToken(uint encodeData, uint currentRound, uint tokenId) internal pure returns(uint) {
        if ((encodeData & 0xfff) == currentRound) {
            uint tokenCount = (encodeData >> 12) & 0xf;
            if (tokenCount < 12) {
                return currentRound | ((tokenCount +1) << 12) | (encodeData & ~(0xffff + (0xfffff << (16 + tokenCount * 20)))) | (tokenId << (16 + tokenCount * 20));
            }
            return encodeData;
        } else {
            return currentRound | (1 << 12) | (tokenId << 16);
        }
    }

    function removeToken(uint encodeData, uint currentRound, uint tokenIndex) internal pure returns(uint) {
        if ((encodeData & 0xfff) == currentRound) {
            uint tokenCount = (encodeData >> 12) & 0xf;
            require(tokenIndex < tokenCount, "RT");
            uint tokenData = encodeData >> 16;
            uint newtokens = (tokenData & ((1 << (tokenIndex * 20)) - 1)) | ((tokenData >> 20) & (type(uint).max << (tokenIndex * 20)));
            return currentRound | ((tokenCount - 1) << 12) | (newtokens << 16);
        } else {
            revert("RT");
        }
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
pragma abicoder v2;
//import "hardhat/console.sol";
//import "../lib/forge-std/src/console.sol";

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
}