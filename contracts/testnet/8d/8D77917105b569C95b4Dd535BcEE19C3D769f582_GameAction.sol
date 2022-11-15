pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
//SPDX-License-Identifier: MIT
import "./PlayerDataHelper.sol";
import "./TokenOnGroundHelper.sol";
import "./GameConstants.sol";
import "./GameView.sol";
import "./GameBasic.sol";
import "./Utils.sol";
import "../IBattleRoyaleGameV1.sol";
import "../IBattleRoyaleNFT.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

//import "hardhat/console.sol";

library GameAction {
    using SignedMath for int;

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

    function _move(mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, MoveParams memory p) private {
        uint mapSize = p.config.mapSize;
        uint pos = GameView.getPlayerPos(playersData, tilemap, p.mapSeed, mapSize, p.player);
        (uint x, uint y) = GameView.decodePos(pos);
        for (uint i = 0; i < p.path.length; i++) {
            uint dir = p.path[i];
            // left
            if (dir == 0) {
                require(x > 0);
                x -= 1;
            }
            // up
            else if (dir == 1) {
                require(y > 0);
                y -= 1;
            }
            // right
            else if (dir == 2) {
                require(x < mapSize - 1);
                x += 1;
            }
            // down
            else if (dir == 3) {
                require(y < mapSize - 1);
                y += 1;
            } else {
                revert();
            }
            require(GameView.getTileType(tilemap, x, y, mapSize) == IBattleRoyaleGameV1.TileType.None);
        }
        playersData[p.player] = PlayerDataHelper.updatePos(playersData[p.player], x + (y << 8));
        emit ActionMove(p.round, p.player, pos, p.path);
    }

    struct MoveParams {
        IBattleRoyaleGameV1.GameConfig config;
        uint round;
        uint mapSeed;
        address player;
        uint[] path;
    }
    
    function move(mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, MoveParams memory p) external {
        require(p.path.length > 0 && p.path.length <= p.config.moveMaxSteps);
        _move(playersData, tilemap, p);
    }

    struct BootsParams {
        IBattleRoyaleGameV1.GameConfig config;
        IBattleRoyaleGameV1.GameState state;
        IBattleRoyaleNFT nft;

        uint mapSeed;
        address player;
        uint[] path;
        uint tokenIndex;
    }

    function moveWithBoots(mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, BootsParams memory p) external {
        uint bootsId = _getTokenId(playersData[p.player], p.tokenIndex);
        (uint usageCount, uint moveMaxSteps) = Property.decodeBootsProperty(p.nft.tokenProperty(bootsId));
        require(usageCount > 0, "Boots1");
        require(p.path.length > 0 && p.path.length <= p.config.moveMaxSteps + moveMaxSteps);
        _move(playersData, tilemap, MoveParams({
            config: p.config,
            round: p.state.round,
            mapSeed: p.mapSeed,
            player: p.player,
            path: p.path
        }));

        p.nft.setProperty(bootsId, Property.encodeBootsProperty(usageCount - 1, moveMaxSteps));
        if (usageCount == 1) {
            p.nft.burn(bootsId);
            playersData[p.player] = PlayerDataHelper.removeTokenAt(playersData[p.player], p.tokenIndex);
        }
    }

    struct LinePathParams {
        int x0;
        int y0;
        int x1;
        int y1;

        int dx;
        int dy;
        int err;
        int ystep;
        bool steep;
    }

    function _getXY(int fromPos, int toPos) private pure returns(LinePathParams memory) {
        int x0 = fromPos & 0xff;
        int y0 = (fromPos >> 8) & 0xff;
        int x1 = toPos & 0xff;
        int y1 = (toPos >> 8) & 0xff;

        bool steep = (y1 - y0).abs() > (x1-x0).abs();

        if (steep) {
            (x0, y0) = (y0, x0);
            (x1, y1) = (y1, x1);
        }
        if (x0 > x1) {
            (x0, x1) = (x1, x0);
            (y0, y1) = (y1, y0);
        }
        return LinePathParams({
            x0: x0,
            y0: y0,
            x1: x1,
            y1: y1,
            dx: x1 - x0,
            dy: int((y1 - y0).abs()),
            err: (x1 - x0) / 2,
            ystep: y0 < y1 ? int(1) : int(-1),
            steep: steep
        });
    }
    
    // Bresenham's line algorithm
    function _checkPathForShoot(mapping(uint => uint) storage tilemap, uint mapSize, int fromPos, int toPos, int excludePos) private view {
        LinePathParams memory p = _getXY(fromPos, toPos);
        int y = p.y0;
        for(int x = p.x0; x <= p.x1; x++) {
            IBattleRoyaleGameV1.TileType t = p.steep ? GameView.getTileType(tilemap, uint(y), uint(x), mapSize) : GameView.getTileType(tilemap, uint(x), uint(y), mapSize);
            require((p.steep ? (x << 8) + y : (y << 8) + x) == excludePos || t == IBattleRoyaleGameV1.TileType.None || t == IBattleRoyaleGameV1.TileType.Water);
            p.err -= p.dy;
            if (p.err < 0) {
                y += p.ystep;
                p.err += p.dx;
            }
        }
    }

    function _getTokenId(uint playerData, uint tokenIndex) private pure returns(uint) {
        (,,,uint[] memory tokenIds) = PlayerDataHelper.decode(playerData);
        require(tokenIndex < tokenIds.length);
        return tokenIds[tokenIndex];
    }

    struct ShootParams2 {
        uint fromPos;
        uint toPos;
        address player;
        address target;
        bool targetIsPlayer;
        uint shootRange;
        uint shootDamage;
        uint criticalStrikeProbability;
        uint tokenId;
        IBattleRoyaleNFT nft;
        uint mapSeed;
        IBattleRoyaleGameV1.GameState state;
        IBattleRoyaleGameV1.GameConfig config;
    }

    function _calcDamage(ShootParams2 memory p) private view returns(uint) {
        uint distance = Math.sqrt(Utils.distanceSquare(p.fromPos, p.toPos) * 10000);
        uint missChance = (Math.max(distance, 100) - 100) / p.shootRange;
        if (missChance >= 100) {
            return 0;
        }
        uint seed = uint(keccak256(abi.encodePacked(p.mapSeed, p.player, p.tokenId, GameView.gameTick(p.state.startTime, p.config.tickTime))));
        if(seed % 100 < missChance) {
            return 0;
        }
        bool criticalStrike = (seed >> 8) % 100 < p.criticalStrikeProbability;
        return p.shootDamage * (criticalStrike ? 3 : 1);
    }

    function _shoot(
        address[] storage players, 
        mapping(address => uint) storage playersData,
        mapping(uint => uint) storage tokensOnGround,
        mapping(uint => uint) storage tilemap, 
        ShootParams2 memory p
    ) private {
        uint damage = _calcDamage(p);
        emit ActionShoot(p.state.round, p.player, p.fromPos, p.toPos, damage > 0);
        if (damage > 0) {
            if (p.targetIsPlayer) {
                GameBasic.applyDamage(players, playersData, tokensOnGround, tilemap, GameBasic.ApplyDamageParams({
                    nft: p.nft,
                    mapSeed: p.mapSeed,
                    state: p.state,
                    config: p.config,
                    player: p.target,
                    damage: damage,
                    canDodge: true
                }));
            } else {
                GameBasic.destroyTile(tilemap, tokensOnGround, p.config.mapSize, p.toPos, p.mapSeed,p.state.round, GameView.gameTick(p.state.startTime, p.config.tickTime), p.nft);
            }
        }
    }

    struct ShootParams {
        IBattleRoyaleNFT nft;
        uint mapSeed;
        IBattleRoyaleGameV1.GameState state;
        IBattleRoyaleGameV1.GameConfig config;

        address player;

        uint tokenIndex;
        address target;
        bool targetIsPlayer;
    }

    function shoot(
        address[] storage players, 
        mapping(address => uint) storage playersData, 
        mapping(uint => uint) storage tokensOnGround, 
        mapping(uint => uint) storage tilemap, 
        ShootParams memory p
    ) external {
        uint gunId = _getTokenId(playersData[p.player], p.tokenIndex);
        (uint bulletCount, uint shootRange, uint bulletDamage, uint criticalStrikeProbability) = Property.decodeGunProperty(p.nft.tokenProperty(gunId));
        require(bulletCount > 0, "No Bullet");
        uint fromPos = GameView.getPlayerPos(playersData, tilemap, p.mapSeed, p.config.mapSize, p.player);
        uint toPos = p.targetIsPlayer ? GameView.getPlayerPos(playersData, tilemap, p.mapSeed, p.config.mapSize, p.target) : uint256(uint160(p.target));
        _checkPathForShoot(tilemap, p.config.mapSize, int(fromPos), int(toPos), p.targetIsPlayer ? int(PlayerDataHelper.MAX_POS) : int(toPos));

        _shoot(
            players, playersData, tokensOnGround, tilemap,
            ShootParams2({
            fromPos: fromPos,
            toPos: toPos,
            target: p.target,
            targetIsPlayer: p.targetIsPlayer,
            shootRange: shootRange,
            shootDamage: bulletDamage,
            criticalStrikeProbability: criticalStrikeProbability,
            tokenId: gunId,
            nft: p.nft,
            mapSeed: p.mapSeed,
            player: p.player,
            state: p.state,
            config: p.config
        }));
        p.nft.setProperty(gunId, Property.encodeGunProperty(bulletCount - 1, shootRange, bulletDamage, criticalStrikeProbability));
        if (bulletCount == 1) {
            p.nft.burn(gunId);
            playersData[p.player] = PlayerDataHelper.removeTokenAt(playersData[p.player], p.tokenIndex);
        }
    }

    struct PickParams2 {
        int playerX;
        int playerY;
        uint bagCapacity;
        uint round;
        uint posLength;
        uint playerData;
    }

    function _pickOne(mapping(uint => uint) storage tokensOnGround, PickParams2 memory p, uint pos, uint[] memory tokensIdAndIndex) private {
        uint groundTokens = tokensOnGround[pos];
        uint[] memory tokens = TokenOnGroundHelper.tokens(groundTokens, p.round);
        require(tokensIdAndIndex.length % 2 == 0, "Pick3");
        uint j = 0;
        for (j = 0; j < tokensIdAndIndex.length; j += 2) {
            require(tokensIdAndIndex[j] == tokens[tokensIdAndIndex[j+1]], "Pick4");
            require(j + 3 >= tokensIdAndIndex.length || tokensIdAndIndex[j+1] > tokensIdAndIndex[j+3], "Pick5");
            p.playerData = PlayerDataHelper.addToken(p.playerData, tokensIdAndIndex[j], p.bagCapacity);
            groundTokens = TokenOnGroundHelper.removeToken(groundTokens, p.round, tokensIdAndIndex[j+1]);
        }
        tokensOnGround[pos] = groundTokens;
        emit TokensOnGroundChanged(p.round, pos);
    }

    struct PickParams {
        IBattleRoyaleGameV1.GameState state;
        uint mapSeed; 
        uint mapSize;
        IBattleRoyaleNFT nft;
        address player;
        uint[] pos;
        uint[][] tokensIdAndIndex;
    }

    function pick(
        mapping(address => uint) storage playersData,
        mapping(uint => uint) storage tokensOnGround, 
        mapping(uint => uint) storage tilemap, 
        PickParams memory p
    ) external {
        require(p.pos.length == p.tokensIdAndIndex.length, "Pick1");

        uint playerData = playersData[p.player];
        uint playerPos = GameView.getPlayerPos(playersData, tilemap, p.mapSeed, p.mapSize, p.player);

        PickParams2 memory p2 = PickParams2({
            playerX: int(playerPos & 0xff),
            playerY: int(playerPos >> 8),
            bagCapacity: 0,
            round: p.state.round,
            posLength: p.pos.length,
            playerData: playerData
        });
        (,,p2.bagCapacity) = Property.decodeCharacterProperty(p.nft.tokenProperty(PlayerDataHelper.firstTokenId(playerData)));
        for (uint i = 0; i < p2.posLength; i++) {
            require((int(p.pos[i] & 0xff) - p2.playerX).abs() + (int(p.pos[i] >> 8) - p2.playerY).abs() <= 1, "Pick2");
            _pickOne(tokensOnGround, p2, p.pos[i], p.tokensIdAndIndex[i]);
        }
        playersData[p.player] = p2.playerData;
        emit ActionPick(p.state.round, p.player);
    }

    struct DropParams {
        uint round;
        address player;
        uint pos;
        uint[] tokenIndexes;
    }

    function drop(mapping(address => uint) storage playersData,mapping(uint => uint) storage tokensOnGround, DropParams memory p) external {
        uint playerData = playersData[p.player];
        (,uint playerPos,, uint[] memory tokenIds) = PlayerDataHelper.decode(playerData);
        require((int(p.pos & 0xff) - int(playerPos & 0xff)).abs() + (int(p.pos >> 8) - int(playerPos >> 8)).abs() <= 1, "Drop");
        uint data = tokensOnGround[p.pos];
        uint round = p.round;
        for (uint i = p.tokenIndexes.length; i > 0; i--) {
            if (i > 1) {
                require(p.tokenIndexes[i-2] < p.tokenIndexes[i-1], "Drop");
            }
            playerData = PlayerDataHelper.removeTokenAt(playerData, p.tokenIndexes[i-1]);
            data = TokenOnGroundHelper.addToken(data, round, tokenIds[p.tokenIndexes[i-1]]);
        }
        playersData[p.player] = playerData;
        emit ActionDrop(p.round, p.player);
        tokensOnGround[p.pos] = data;
        emit TokensOnGroundChanged(p.round, p.pos);
    }

    struct BombParams2 {
        uint mapSeed;
        IBattleRoyaleGameV1.GameState state;
        IBattleRoyaleGameV1.GameConfig config;

        uint bombPos;

        uint throwRange;
        uint explosionRange;
        uint damage;

        address target;
        bool targetIsPlayer;
        IBattleRoyaleNFT nft;
    }

    function _checkBombOne(mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, BombParams2 memory p) private {
        uint pos = p.targetIsPlayer ? GameView.getPlayerPos(playersData, tilemap, p.mapSeed, p.config.mapSize, p.target): uint(uint160(p.target));
        uint distance = Utils.distanceSquare(pos, p.bombPos);
        require(distance <= p.explosionRange * p.explosionRange, "Bomb");
        _checkPathForShoot(tilemap, p.config.mapSize, int(p.bombPos), int(pos), int(pos));
    }

    function _bombOne(address[] storage players, mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, mapping(uint => uint) storage tokensOnGround, BombParams2 memory p) private {
        if (p.targetIsPlayer) {
            uint pos = PlayerDataHelper.getPos(playersData[p.target]);
            uint distance = Utils.distanceSquare(pos, p.bombPos);
            uint damage = p.damage * (100 - Math.sqrt(distance * 10000) / (p.explosionRange + 1)) / 100;
            GameBasic.applyDamage(players, playersData, tokensOnGround, tilemap,
                GameBasic.ApplyDamageParams({
                    nft: p.nft,
                    mapSeed: p.mapSeed,
                    state: p.state,
                    config: p.config,
                    player: p.target,
                    damage: damage,
                    canDodge: false
                })
            );
        } else {
            GameBasic.destroyTile(tilemap, tokensOnGround, p.config.mapSize, uint(uint160(p.target)), p.mapSeed, p.state.round, GameView.gameTick(p.state.startTime, p.config.tickTime), p.nft);
        }
    }

    struct BombParams {
        uint mapSeed;
        IBattleRoyaleGameV1.GameState state;
        IBattleRoyaleGameV1.GameConfig config;

        IBattleRoyaleNFT nft;
        address player;

        uint tokenIndex;
        uint bombPos;
        address[] targets;
        bool[] targetsIsPlayer;
    }

    function bomb(address[] storage players, mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, mapping(uint => uint) storage tokensOnGround,BombParams memory p) external {
        uint bombId = _getTokenId(playersData[p.player], p.tokenIndex);
        (uint throwRange, uint explosionRange, uint damage) = Property.decodeBombProperty(p.nft.tokenProperty(bombId));
        uint playerPos = GameView.getPlayerPos(playersData, tilemap, p.mapSeed, p.config.mapSize, p.player);
        require(Utils.distanceSquare(playerPos, p.bombPos) <= throwRange * throwRange, "Bomb1");
        require(p.targets.length == p.targetsIsPlayer.length, "Bomb2");
        require(GameView.getTileType(tilemap, p.bombPos & 0xff, p.bombPos >> 8, p.config.mapSize) == IBattleRoyaleGameV1.TileType.None, "Bomb3");

        for(uint i = 0; i < p.targets.length; i++) {
            _checkBombOne(playersData, tilemap, BombParams2({
                throwRange: throwRange,
                explosionRange: explosionRange,
                damage: damage,
                bombPos: p.bombPos,
                target: p.targets[i],
                targetIsPlayer: p.targetsIsPlayer[i],
                nft: p.nft,
                mapSeed: p.mapSeed,
                state: p.state,
                config: p.config
            }));
        }

        for(uint i = 0; i < p.targets.length; i++) {
            _bombOne(players, playersData, tilemap, tokensOnGround, BombParams2({
                throwRange: throwRange,
                explosionRange: explosionRange,
                damage: damage,
                bombPos: p.bombPos,
                target: p.targets[i],
                targetIsPlayer: p.targetsIsPlayer[i],
                nft: p.nft,
                mapSeed: p.mapSeed,
                state: p.state,
                config: p.config
            }));
        }
        p.nft.burn(bombId);
        playersData[p.player] = PlayerDataHelper.removeTokenAt(playersData[p.player], p.tokenIndex);

        emit ActionBomb(p.state.round, p.player, playerPos, p.bombPos, explosionRange);
    }

    struct EatParams {
        uint round;
        IBattleRoyaleNFT nft;
        address player;
        uint tokenIndex;
    }
    function eat(mapping(address => uint) storage playersData, EatParams memory p) external {
        uint playerData = playersData[p.player];
        uint characterId = PlayerDataHelper.firstTokenId(playerData);
        uint foodId = _getTokenId(playerData, p.tokenIndex);
        uint heal = Property.decodeFoodProperty(p.nft.tokenProperty(foodId));
        (uint hp, uint maxHP, uint bag) = Property.decodeCharacterProperty(p.nft.tokenProperty(characterId));
        uint hp2 = Math.min(maxHP, hp + heal);
        p.nft.setProperty(characterId, Property.encodeCharacterProperty(hp2, maxHP, bag));

        p.nft.burn(foodId);
        playersData[p.player] = PlayerDataHelper.removeTokenAt(playersData[p.player], p.tokenIndex);

        emit ActionEat(p.round, p.player, hp2 - hp);
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


library GameConstants {
    uint8 public constant GAME_STATUS_REGISTER = 0;
    uint8 public constant GAME_STATUS_RUNNING = 1;
}

pragma solidity >=0.8.0 <0.9.0;

pragma abicoder v2;

//SPDX-License-Identifier: MIT
import "./PlayerDataHelper.sol";
import "./TokenOnGroundHelper.sol";
import "../IBattleRoyaleGameV1.sol";
import "../IBattleRoyaleNFT.sol";

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

    function allTokensOnGround(mapping(uint => uint) storage tokensOnGround, IBattleRoyaleNFT nft, uint round, uint fromX, uint fromY, uint toX, uint toY) public view returns(uint[][] memory allTokenIds, uint[][] memory allTokenProperties) {
        allTokenIds = new uint[][]((toX - fromX) * (toY - fromY));
        allTokenProperties = new uint[][]((toX - fromX) * (toY - fromY));
        uint i = 0;
        for (uint y = fromY; y < toY; y++) {
            for (uint x = fromX; x < toX; x++) {
                uint[] memory tokenIds = TokenOnGroundHelper.tokens(tokensOnGround[x + (y << 8)], round);
                uint[] memory properties = new uint[](tokenIds.length);
                for(uint k = 0; k < properties.length; k++) {
                    properties[k] = nft.tokenProperty(tokenIds[k]);
                }
                allTokenIds[i] = tokenIds;
                allTokenProperties[i] = properties;
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
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "./PlayerDataHelper.sol";
import "./TokenOnGroundHelper.sol";
import "./Map.sol";
import "./GameConstants.sol";
import "./GameView.sol";
import "../IBattleRoyaleGameV1.sol";
import "../IBattleRoyaleNFT.sol";
import "../IBATTLE.sol";
import "./Property.sol";
import "./Utils.sol";

library GameBasic {
    
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

    struct RegisterParams {
        IBattleRoyaleNFT nft;
        uint[] tokenIds;
        IBattleRoyaleGameV1.GameConfig config;
        uint mapSeed;
        address player;
    }

    function register(
        address[] storage players, 
        mapping(address => uint) storage playersData,
        mapping(address => uint) storage playersReward, 
        mapping(uint => uint) storage tokensOnGround, 
        mapping(uint => uint) storage tilemap, 
        IBattleRoyaleGameV1.GameState storage state, 
        RegisterParams memory p
    ) external returns(uint) {
        _register(players, playersData, p.nft, state.status, p.config.needPlayerCount, p.tokenIds, p.player);
        _generateMap(tokensOnGround, tilemap, state,p.nft, p.config.mapSize, p.mapSeed);
        playersReward[p.player] = Utils.addReward(playersReward[p.player], p.config.playerRewardToken + p.config.playerBonusRewardToken, 0);
        emit RegisterGame(state.round, p.player, true, p.tokenIds);
        if(players.length == p.config.needPlayerCount) {
            return startGame(p.mapSeed, state, p.config.mapSize, p.player);
        }
        return p.mapSeed;
    }

    function _register(
        address[] storage players, 
        mapping(address => uint) storage playersData, 
        IBattleRoyaleNFT nft, 
        uint8 gameStatus, 
        uint needPlayerCount, 
        uint[] memory tokenIds, 
        address player
    ) private {
        require(gameStatus == 0, "wrong status");
        require(players.length < needPlayerCount, "too many players");
        require(playersData[player] == 0, "registered");
        require(tokenIds.length > 0, "no tokens");
        require(nft.tokenType(tokenIds[0]) == Property.NFT_TYPE_CHARACTER, "first token must be a character");

        (uint hp,,uint bagCapacity) = Property.decodeCharacterProperty(nft.tokenProperty(tokenIds[0]));
        require(bagCapacity >= tokenIds.length-1, "small bag capacity");
        require(hp > 0, "died");

        uint len = tokenIds.length;
        for (uint i = 0; i < len; i++) {
            require(i == 0 || nft.tokenType(tokenIds[i]) != Property.NFT_TYPE_CHARACTER, "only one character");
            nft.transferFrom(player, address(this), tokenIds[i]);
        }
        players.push(player);
        playersData[player] = PlayerDataHelper.encode(players.length, PlayerDataHelper.MAX_POS, 0, tokenIds);
    }

    function _generateMap(
        mapping(uint => uint) storage tokensOnGround, 
        mapping(uint => uint) storage tilemap,
        IBattleRoyaleGameV1.GameState storage state,
        IBattleRoyaleNFT nft,
        uint mapSize, 
        uint mapSeed
    ) private {
        uint tileSize = mapSize / 8;
        uint tilePos = state.initedTileCount;
        if(tilePos < tileSize * tileSize) {
            uint curMap = Map.genTile(mapSeed, tilePos, mapSize);
            tilemap[tilePos] = curMap;
            state.initedTileCount = uint16(tilePos + 1)
            ;
            _dropRandomEquipments(tokensOnGround, DropRandomParams({
                nft: nft,
                mapSeed: mapSeed,
                round: state.round,
                tilePos: tilePos,
                curMap: curMap,
                mapSize: mapSize
            }));
        }
    }

    function unregister(
        address[] storage players,
        mapping(address => uint) storage playersData,
        mapping(address => uint) storage playersReward, 
        IBattleRoyaleGameV1.GameState memory state, 
        IBattleRoyaleGameV1.GameConfig memory config, 
        IBattleRoyaleNFT nft, 
        address player
    ) external {
        require(state.status == GameConstants.GAME_STATUS_REGISTER, "wrong status");
        (uint tokenReward, uint nftReward) = Utils.decodeReward(playersReward[player]);
        require(tokenReward >= config.playerRewardToken + config.playerBonusRewardToken, "Reward Claimed!");
        playersReward[player] = Utils.encodeReward(tokenReward - config.playerRewardToken - config.playerBonusRewardToken, nftReward);
        (,,,uint[] memory tokenIds) = PlayerDataHelper.decode(playersData[player]);
        // send back tokens
        for(uint i = 0; i < tokenIds.length; i++) {
            nft.transferFrom(address(this), player, tokenIds[i]);
        }
        _removePlayer(players, playersData, player);
        emit RegisterGame(state.round, player, false, tokenIds);
    }


    function claimReward(mapping(address => uint) storage playersReward, IBATTLE battleToken, IBattleRoyaleNFT nft, address owner, uint tax, address player) external {
        (uint tokenReward, uint nftReward) = Utils.decodeReward(playersReward[player]);
        playersReward[player] = 0;
        require(tokenReward > 0 || nftReward > 0, "No Reward");
        if (tokenReward > 0) {
            battleToken.mint(player, tokenReward * (1 ether));
            uint rewardToDev = tokenReward * (1 ether) * tax / 100;
            if (rewardToDev > 0 && owner != address(0)) {
                battleToken.mint(owner, rewardToDev);
            }
        }

        for(uint i = 0; i < nftReward; i++) {
            _mint(player, nft, 0x77665544332222211111);
        }
    }

    function startGame(uint mapSeed, IBattleRoyaleGameV1.GameState storage state, uint mapSize, address player) private returns(uint) {
        mapSeed = uint(keccak256(abi.encodePacked(mapSeed, block.timestamp, player)));
        state.startTime = uint40(block.timestamp);
        state.newChestBoxLastTick = 0;

        state.shrinkLeft = 0;
        state.shrinkRight = 0;
        state.shrinkTop = 0;
        state.shrinkBottom = 0;
        state.status = 1;

        state.shrinkCenterX = uint8(mapSeed % mapSize);
        state.shrinkCenterY = uint8((mapSeed >> 8) % mapSize);

        state.shrinkTick = 1;
        emit GameStateChanged();
        return mapSeed;
    }

    function endGame(
        IBattleRoyaleGameV1.GameState storage state, 
        address[] storage players, 
        mapping(address => uint) storage playersData, 
        mapping(address => uint) storage playersReward, 
        IBattleRoyaleNFT nft, 
        IBattleRoyaleGameV1.GameConfig memory config
    ) external {
        uint leftPlayerCount = players.length;
        require(state.status == GameConstants.GAME_STATUS_RUNNING && leftPlayerCount <= 1, "EndGame");
        endGameState(state);
        if (leftPlayerCount == 1) {
            address winerAddr = players[0];
            (,,,uint[] memory tokenIds) = PlayerDataHelper.decode(playersData[winerAddr]);
            _removePlayer(players, playersData, winerAddr);
            // send back tokens
            for(uint i = 0; i < tokenIds.length; i++) {
                nft.transferFrom(address(this), winerAddr, tokenIds[i]);
            }
            playersReward[winerAddr] = Utils.addReward(playersReward[winerAddr], config.winnerRewardToken + config.winnerBonusRewardToken, config.winnerRewardNFT + config.winnerBonusRewardNFT);
            emit PlayerWin(state.round, winerAddr, config.winnerRewardToken, config.winnerRewardNFT);
        }
        //burn left tokens
        burnAllTokens(nft);
        emit GameStateChanged();
    }

    struct DropRandomParams {
        IBattleRoyaleNFT nft;
        uint mapSeed;
        uint round;
        uint tilePos;
        uint curMap;
        uint mapSize;
    }

    function _dropRandomEquipments(mapping(uint => uint) storage tokensOnGround, DropRandomParams memory p) private { 
        uint seed = uint(keccak256(abi.encodePacked(p.mapSeed, bytes("equipment"), p.tilePos)));

        uint count = seed % 3 + 3;
        uint x1 = p.tilePos % (p.mapSize / 8) * 8;
        uint y1 = p.tilePos / (p.mapSize / 8) * 8;

        for (uint i = 0; i < count; i++) {
            uint pos = (seed >> (8 + (i * 6))) % 64;
            if (Map.isEmptyTile(p.curMap, pos)) {
                /**
                 * Gun: 30%
                 * Bomb: 15%
                 * Armor: 15%
                 * Ring: 15%
                 * Food: 15%
                 * Boots: 10%
                 */
                pos = (x1 + (pos % 8)) + ((y1 + (pos / 8)) << 8);
                tokensOnGround[pos] = TokenOnGroundHelper.addToken(tokensOnGround[pos], p.round, _mint(address(this), p.nft, 0x77666555444333222222));
            }
        }
    }

    function _mint(address to, IBattleRoyaleNFT nft, uint probability) private returns(uint) {
        uint seed = uint(
            keccak256(abi.encodePacked(block.timestamp, address(this), nft.nextTokenId()))
        );
        return nft.mintByGame(to, Property.newProperty(seed, probability));
    }

    function _drop(mapping(uint => uint) storage tokensOnGround, uint round, uint[] memory tokenIds, uint startTokenIndex, uint pos) private {
        uint data = tokensOnGround[pos];
        for (uint i = startTokenIndex; i < tokenIds.length; i++) {
            data = TokenOnGroundHelper.addToken(data, round, tokenIds[i]);
        }
        tokensOnGround[pos] = data;
        emit TokensOnGroundChanged(round, pos);
    }
    
    function destroyTile(mapping(uint => uint) storage tilemap, mapping(uint => uint) storage tokensOnGround, uint mapSize, uint pos, uint mapSeed, uint round, uint tick, IBattleRoyaleNFT nft) internal {
        (uint x, uint y) = GameView.decodePos(pos);
        IBattleRoyaleGameV1.TileType t = GameView.getTileType(tilemap, x, y, mapSize);
        if (t == IBattleRoyaleGameV1.TileType.Wall || t == IBattleRoyaleGameV1.TileType.ChestBox) {
            _setTileType(tilemap, x, y, mapSize, IBattleRoyaleGameV1.TileType.None);
            if (t == IBattleRoyaleGameV1.TileType.ChestBox) {
                uint seed = uint(keccak256(abi.encodePacked(mapSeed, pos, tick, "chestbox")));
                uint count = seed % 4 + 1;
                for(uint i = 0; i < count; i++) {
                    tokensOnGround[pos] = TokenOnGroundHelper.addToken(tokensOnGround[pos], round, _mint(address(this), nft, 0x77766655544433332222));
                }
                emit TokensOnGroundChanged(round, pos);
            }
            emit TileChanged(round, pos);
        } else if (t != IBattleRoyaleGameV1.TileType.None) {
            revert("destroyTile");
        }
    }
    
    struct RingParams{
        uint round;
        address player;
        uint mapSeed;
        uint tick;
        IBattleRoyaleNFT nft;
    }

    function applyRing(mapping(address => uint) storage playersData,RingParams memory p) private returns(bool dodge) {
        dodge = false;
        uint playerData = playersData[p.player];
        uint[] memory tokenIds = PlayerDataHelper.getTokenIds(playerData);
        for (uint i = tokenIds.length - 1; i > 0; i--) {
            uint token = p.nft.tokenProperty(tokenIds[i]);
            if (Property.decodeType(token) == Property.NFT_TYPE_RING) {
                (uint dodgeCount, uint dodgeChance) = Property.decodeRingProperty(token);
                if(dodgeCount > 0) {
                    uint seed = uint(keccak256(abi.encodePacked(p.mapSeed, tokenIds[i], p.tick)));
                    if (seed % 100 < dodgeChance) {
                        dodge = true;
                    }
                    emit ActionDodge(p.round, p.player, dodge);
                    dodgeCount -= 1;
                    p.nft.setProperty(tokenIds[i], Property.encodeRingProperty(dodgeCount, dodgeChance));
                }
                if (dodgeCount == 0) {
                    p.nft.burn(tokenIds[i]);
                    playerData = PlayerDataHelper.removeTokenAt(playerData, i);
                }
            }

            if (dodge) {
                break;
            }
        }
        playersData[p.player] = playerData;
    }

    struct ArmorParams{
        uint round;
        address player;
        uint damage;
        IBattleRoyaleNFT nft;
    }

    function applyArmor(mapping(address => uint) storage playersData, ArmorParams memory p) private returns(uint) {
        uint playerData = playersData[p.player];
        (,,,uint[] memory tokenIds) = PlayerDataHelper.decode(playerData);
        for (uint i = tokenIds.length - 1; i > 0; i--) {
            uint token = p.nft.tokenProperty(tokenIds[i]);
            if (Property.decodeType(token) == Property.NFT_TYPE_ARMOR) {
                uint defense = Property.decodeArmorProperty(token);
                uint leftDefense = defense < p.damage ? 0 : defense - p.damage;
                p.damage -= defense - leftDefense;
                p.nft.setProperty(tokenIds[i], Property.encodeArmorProperty(leftDefense));
                if (leftDefense == 0) {
                    p.nft.burn(tokenIds[i]);
                    playerData = PlayerDataHelper.removeTokenAt(playerData, i);
                }
                emit ActionDefend(p.round, p.player, defense - leftDefense);
            }
            if (p.damage == 0) {
                break;
            }
        }
        playersData[p.player] = playerData;
        return p.damage;
    }

    struct ApplyDamageParams {
        IBattleRoyaleNFT nft;
        uint mapSeed;
        IBattleRoyaleGameV1.GameState state;
        IBattleRoyaleGameV1.GameConfig config;
        address player;
        uint damage;
        bool canDodge;
    }

    function applyDamage(address[] storage players, mapping(address => uint) storage playersData,mapping(uint => uint) storage tokensOnGround,mapping(uint => uint) storage tilemap, ApplyDamageParams memory p) public {
        if (p.damage == 0) return;

        uint characterId = PlayerDataHelper.firstTokenId(playersData[p.player]);
        uint tick = GameView.gameTick(p.state.startTime, p.config.tickTime);
        if (p.canDodge && applyRing(playersData, RingParams({
            round: p.state.round,
            player: p.player,
            mapSeed: p.mapSeed,
            tick: tick,
            nft: p.nft
        }))) {
            return;
        }
        p.damage = applyArmor(playersData, ArmorParams({
            round: p.state.round,
            player: p.player,
            damage: p.damage,
            nft: p.nft
        }));
        if (p.damage == 0) {
            return;
        }

        (uint hp, uint maxHP, uint bagCapacity) = Property.decodeCharacterProperty(p.nft.tokenProperty(characterId));
        hp = hp < p.damage ? 0 : hp - p.damage;
        p.nft.setProperty(characterId, Property.encodeCharacterProperty(hp, maxHP, bagCapacity));
        emit PlayerHurt(p.state.round, p.player, p.damage);
        if (hp == 0) {
            killPlayer(players, playersData, tokensOnGround, tilemap,
                KillParams({
                    nft: p.nft,
                    mapSeed: p.mapSeed,
                    round: p.state.round,
                    config: p.config,
                    player: p.player
                })
            );
        }
    }

    struct KillParams {
        IBattleRoyaleNFT nft;
        uint mapSeed;
        uint round;
        IBattleRoyaleGameV1.GameConfig config;
        address player;
    }

    function killPlayer(
        address[] storage players, 
        mapping(address => uint) storage playersData,
        mapping(uint => uint) storage tokensOnGround,
        mapping(uint => uint) storage tilemap,
        KillParams memory p
    ) public {
        uint[] memory tokenIds = PlayerDataHelper.getTokenIds(playersData[p.player]);
        p.nft.burn(tokenIds[0]);
        uint pos = GameView.getPlayerPos(playersData, tilemap, p.mapSeed, p.config.mapSize, p.player);
        _drop(tokensOnGround, p.round, tokenIds, 1, pos);
        _removePlayer(players, playersData, p.player);
        emit PlayerKilled(p.round, p.player);
    }

    function _removePlayer(address[] storage players, mapping(address => uint) storage playersData, address player) private {
        uint index = PlayerDataHelper.getKeyIndex(playersData[player]);
        uint totalPlayerCount = players.length;
        if (index != totalPlayerCount) {
            address lastPlayer = players[totalPlayerCount-1];
            players[index-1] = lastPlayer;
            playersData[lastPlayer] = PlayerDataHelper.updateKeyIndex(playersData[lastPlayer], index);
        }
        players.pop();
        delete playersData[player];
    }
    
    function endGameState(IBattleRoyaleGameV1.GameState storage state) internal {
        state.round += 1;
        state.initedTileCount = 0;
        state.status = 0;
    }

    function burnAllTokens(IBattleRoyaleNFT nft) internal {
        uint tokenCount = nft.balanceOf(address(this));
        for(uint i = tokenCount; i > 0; i--) {
            nft.burn(nft.tokenOfOwnerByIndex(address(this), i-1));
        }
    }

    function adjustShrinkCenter(IBattleRoyaleGameV1.GameState storage state, IBattleRoyaleGameV1.GameConfig memory config, uint mapSeed, address player) external {
        uint ticksInOneGame = config.ticksInOneGame;
        uint tick = GameView.gameTick(state.startTime, config.tickTime);
        if (tick < ticksInOneGame && tick - state.shrinkTick > 20) {
            (uint left, uint top, uint right, uint bottom) = GameView.shrinkRect(state, config);
            state.shrinkLeft = uint8(left);
            state.shrinkTop = uint8(top);
            state.shrinkRight = uint8(right);
            state.shrinkBottom = uint8(bottom);
            state.shrinkTick = uint16(tick);

            uint mapSize = config.mapSize;
            uint seed =  uint(keccak256(abi.encodePacked(mapSeed, bytes("shrink"), block.timestamp, player)));
            state.shrinkCenterX = uint8(seed % (mapSize - left - right) + left);
            state.shrinkCenterY = uint8((seed >> 8) % (mapSize - top - bottom) + top);
            emit GameStateChanged();
        }
    }

    function newChestBox(mapping(uint => uint) storage tilemap, IBattleRoyaleGameV1.GameState memory state, IBattleRoyaleGameV1.GameConfig memory config, uint mapSeed, address player) external {
        (uint left, uint top, uint right, uint bottom) = GameView.shrinkRect(state, config);
        uint mapSize = config.mapSize;
        if (left + right < mapSize && top + bottom < mapSize) {
            for (uint i = 0; i < 3; i++) {
                uint seed = uint(keccak256(abi.encodePacked(mapSeed, bytes("newChestBox"), block.timestamp, player, i)));
                uint x = seed % (mapSize - left - right) + left;
                uint y = (seed >> 8) % (mapSize - top - bottom) + top;
                if (GameView.getTileType(tilemap, x, y, mapSize) == IBattleRoyaleGameV1.TileType.None) {
                    _setTileType(tilemap, x, y, mapSize, IBattleRoyaleGameV1.TileType.ChestBox);
                    emit TileChanged(state.round, x + (y << 8));
                    break;
                }
            }
        }
    }

    function _setTileType(mapping(uint => uint) storage tilemap, uint x, uint y, uint mapSize, IBattleRoyaleGameV1.TileType tileType) internal {
        uint tilePos = y / 8 * (mapSize / 8) + x / 8;
        uint index = (y % 8 * 8 + x % 8) * 4;
        tilemap[tilePos] = (tilemap[tilePos] & ~(uint(0xf << index))) | (uint(tileType) << index);
    }
}

pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

library Utils {
    function distanceSquare(uint pos1, uint pos2) internal pure returns(uint) {
        uint x1 = pos1 & 0xff;
        uint y1 = (pos1 >> 8) & 0xff;
        uint x2 = pos2 & 0xff;
        uint y2 = (pos2 >> 8) & 0xff;
        uint dx = (x1 > x2) ? (x1 - x2) : (x2 - x1);
        uint dy = (y1 > y2) ? (y1 - y2) : (y2 - y1);
        return dx * dx + dy * dy;
    }

    /**
     * 0-16: nft count
     * 16-256: token count
     */
    function decodeReward(uint encodeData) internal pure returns (uint tokenReward, uint nftReward) {
        return (encodeData >> 16, encodeData & 0xffff);
    }

    function encodeReward(uint tokenReward, uint nftReward) internal pure returns (uint data) {
        return (tokenReward << 16) + nftReward;
    }

    function addReward(uint encodeData, uint tokenReward, uint nftReward) internal pure returns(uint data) {
        (uint r1, uint r2) = decodeReward(encodeData);
        return encodeReward(r1 + tokenReward, r2 + nftReward);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
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

pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

library Map {

    struct Rect {
        uint x1;
        uint y1;
        uint x2;
        uint y2;
    }
    
    function genTile(uint mapSeed, uint tilePos, uint mapSize) internal pure returns(uint result) {
        require(mapSize % 8 == 0, "invalid map size");
        uint mapSize16 = mapSize % 16 == 0 ? mapSize : mapSize + 8;
        uint tileX = tilePos % (mapSize/ 8);
        uint tileY = tilePos / (mapSize/ 8);
        for(uint i = 0; i < 5; i++) {
            result |= genTileWaterByOneStep(uint(keccak256(abi.encodePacked(mapSeed,bytes("water"),tileX / 2 + mapSize16 / 16 * tileY / 2, i))), tileX % 2, tileY % 2, 16);
        }

        result = genMountain(uint(keccak256(abi.encodePacked(mapSeed, bytes("mountain"),tilePos))), result);

        result = genWall(uint(keccak256(abi.encodePacked(mapSeed, bytes("wall"),tileX / 2 + mapSize16 / 16 * tileY / 2))), int(tileX % 2), int(tileY % 2), 16, result);

        result = genChestBox(uint(keccak256(abi.encodePacked(mapSeed, bytes("mountain"), tilePos))), result);

        return result;
    }

    function isEmptyTile(uint curMap, uint tilePos) internal pure returns(bool) {
        return (curMap >> (4 * tilePos)) & 0xf == 0;
    }

    function genMountain(uint seed, uint curMap) private pure returns(uint) {
        uint index;
        uint x;
        uint y;
        uint pos;
        if (seed % 100 < 50) {
            index = (seed >> 8) % 25;
            x = index % 5;
            y = index / 5;
            uint bigMountain = 0;
            pos = y * 8 + x;
            for (uint i = 0; i < 9; i++) {
                if (isEmptyTile(curMap, pos)) {
                    bigMountain |= 2 << (4 * pos);
                } else {
                    bigMountain = 0;
                    break;
                }
                pos += (i+1) % 3 == 0 ? 6 : 1;
            }
            curMap |= bigMountain;
        }
        uint singleCount = (seed >> 16) % (seed % 100 < 50 ? 6 : 9);
        for (uint i = 0; i < singleCount; i++) {
            pos = (seed >> (24 + i * 6)) % 64;
            if (pos >= 8 && isEmptyTile(curMap, pos) && isEmptyTile(curMap, pos-8)) {
                curMap |= 2 << (4 * pos);
                curMap |= 2 << (4 * (pos - 8));
            }
        }

        singleCount = (seed >> 160) % (seed % 100 < 50 ? 4 : 6);
        for (uint i = 0; i < singleCount; i++) {
            pos = (seed >> (164 + i * 6)) % 64;
            if (isEmptyTile(curMap, pos)) {
                curMap |= 2 << (4 * pos);
            }
        }
        return curMap;
    }

    function genWall(uint seed, int tileX, int tileY, uint mapSize, uint curMap) private pure returns(uint) {
        uint wallLineCount = seed % 4 + 1;
        for (uint i = 0; i < wallLineCount; i++) {
            int x = int((seed >> (2 + i * 16)) % (mapSize * mapSize));
            int y = x / int(mapSize);
            x %= int(mapSize);
            for (uint j = 0; j < 4; j++) {
                int dx = (seed >> (100 + (4 * i + j) * 2)) % 2 == 0 ? int(1) : int(-1);
                int dy = 0;
                if (j % 2 != 0) {
                    (dx, dy) = (dy, dx);
                }
                uint count = (seed >> (160 + (4 * i + j) * 4)) % 10;
                for (uint m = 0; m < count; m++) {
                    x += dx;
                    y += dy;
                    if (x >= tileX * 8 && x < tileX * 8 + 8 && y >= tileY * 8 && y < tileY * 8 + 8) {
                        uint pos = uint((x - tileX * 8) + (y - tileY * 8) * 8);
                        if (isEmptyTile(curMap, pos)) {
                            curMap |= 3 << (4 * pos);
                        }
                    }
                }
            }
        }
        return curMap;
    }

    function genChestBox(uint seed, uint curMap) private pure returns(uint) {
        uint singleCount = seed % 3;
        for (uint i = 0; i < singleCount; i++) {
            uint pos = (seed >> (24 + i * 6)) % 64;
            if (isEmptyTile(curMap, pos)) {
                curMap |= 4 << (4 * pos);
            }
        }
        return curMap;
    }

    function genTileWaterByOneStep(uint seed, uint tileX, uint tileY, uint mapSize) private pure returns(uint) {
        Rect memory curMap = Rect({
            x1: tileX * 8,
            y1: tileY * 8,
            x2: tileX * 8 + 8,
            y2: tileY * 8 + 8
        });
        uint cx = seed % (mapSize * mapSize);
        uint cy = cx / mapSize;
        cx %= mapSize;

        uint[8] memory all_f = [
            (seed >> 0) % 64, 
            (seed >> 6) % 64,
            (seed >> 12) % 64,
            (seed >> 18) % 64,
            (seed >> 24) % 64,
            (seed >> 30) % 64,
            (seed >> 36) % 64,
            (seed >> 42) % 64
        ];
        Rect memory fullMap = Rect(0, 0, 0, 0);
        uint[4] memory f;

        uint water = 0;

        fullMap.x1 = 0;
        fullMap.y1 = 0;
        fullMap.x2 = cx;
        fullMap.y2 = cy;
        f[0] = all_f[0];
        f[1] = all_f[1];
        f[2] = 99;
        f[3] = all_f[3];
        water |= interpolate(fullMap, curMap, f);

        fullMap.x1 = cx;
        fullMap.y1 = 0;
        fullMap.x2 = mapSize;
        fullMap.y2 = cy;
        f[0] = all_f[1];
        f[1] = all_f[2];
        f[2] = all_f[4];
        f[3] = 99;
        water |= interpolate(fullMap, curMap, f);

        fullMap.x1 = 0;
        fullMap.y1 = cy;
        fullMap.x2 = cx;
        fullMap.y2 = mapSize;
        f[0] = all_f[3];
        f[1] = 99;
        f[2] = all_f[6];
        f[3] = all_f[5];
        water |= interpolate(fullMap, curMap, f);

        fullMap.x1 = cx;
        fullMap.y1 = cy;
        fullMap.x2 = mapSize;
        fullMap.y2 = mapSize;
        f[0] = 99;
        f[1] = all_f[4];
        f[2] = all_f[7];
        f[3] = all_f[6];
        water |= interpolate(fullMap, curMap, f);

        return water;
    }

    function interpolate(Rect memory fullMap, Rect memory curMap, uint[4] memory f) private pure returns(uint result) {
        Rect memory intersect = Rect({
            x1: fullMap.x1 > curMap.x1 ? fullMap.x1 : curMap.x1,
            y1: fullMap.y1 > curMap.y1 ? fullMap.y1 : curMap.y1,
            x2: fullMap.x2 < curMap.x2 ? fullMap.x2 : curMap.x2,
            y2: fullMap.y2 < curMap.y2 ? fullMap.y2 : curMap.y2
        });

        if (intersect.x1 >= intersect.x2 || intersect.y1 >= intersect.y2) return 0;
        uint w = fullMap.x2 - fullMap.x1;
        uint h = fullMap.y2 - fullMap.y1;
        
        for (uint j = intersect.y1; j < intersect.y2; j++) {
            for (uint i = intersect.x1; i < intersect.x2; i++) {
                uint s = (i - fullMap.x1) * 100 / w;
                uint t = (j - fullMap.y1) * 100 / h;
                uint r = (100 - s) * (100 - t) * f[0] + s * (100-t)*f[1] + s * t * f[2] + (100 - s) * t * f[3];
                // uint s = (i - fullMap.x1);
                // uint t = (j - fullMap.y1);
                // uint r = s+t;
                if (r > 850000) {
                    result |= 1 << (4 * ((j - curMap.y1) * 8 + i - curMap.x1));
                }
            }
        }

    }

    //uint constant TargetF = 85;

    // function genTile8x8ByOneStep2(uint seed, uint tileX, uint tileY, uint mapSize) private view returns(uint) {
    //     Rect memory curMap = Rect({
    //         x1: tileX * 8,
    //         y1: tileY * 8,
    //         x2: tileX * 8 + 8,
    //         y2: tileY * 8 + 8
    //     });
    //     uint cx = seed % (mapSize * mapSize);
    //     uint cy = cx / mapSize;
    //     cx %= mapSize;

    //     uint[4] memory f = [
    //         (seed >> 0) % 64, 
    //         (seed >> 6) % 64,
    //         (seed >> 12) % 64,
    //         (seed >> 18) % 64
    //     ];
    //     uint i;
    //     uint j;

    //     uint a = (99 - TargetF) * cx / (99 - f[1]);
    //     uint b = (99 - TargetF) * cy / (99 - f[0]);

    //     for(i = 0; i < a; i++) {
    //         for(j = 0; j < b; j++) {

    //         }
    //     }

    //     Rect memory fullMap = Rect(0, 0, 0, 0);
    //     uint[4] memory f;

    //     uint water = 0;

    //     fullMap.x1 = 0;
    //     fullMap.y1 = 0;
    //     fullMap.x2 = cx;
    //     fullMap.y2 = cy;
    //     f[0] = all_f[0];
    //     f[1] = all_f[1];
    //     f[2] = 99;
    //     f[3] = all_f[3];
    //     water |= interpolate(fullMap, curMap, f);

    //     fullMap.x1 = cx;
    //     fullMap.y1 = 0;
    //     fullMap.x2 = mapSize;
    //     fullMap.y2 = cy;
    //     f[0] = all_f[1];
    //     f[1] = all_f[2];
    //     f[2] = all_f[4];
    //     f[3] = 99;
    //     water |= interpolate(fullMap, curMap, f);

    //     fullMap.x1 = 0;
    //     fullMap.y1 = cy;
    //     fullMap.x2 = cx;
    //     fullMap.y2 = mapSize;
    //     f[0] = all_f[3];
    //     f[1] = 99;
    //     f[2] = all_f[6];
    //     f[3] = all_f[5];
    //     water |= interpolate(fullMap, curMap, f);

    //     fullMap.x1 = cx;
    //     fullMap.y1 = cy;
    //     fullMap.x2 = mapSize;
    //     fullMap.y2 = mapSize;
    //     f[0] = 99;
    //     f[1] = all_f[4];
    //     f[2] = all_f[7];
    //     f[3] = all_f[6];
    //     water |= interpolate(fullMap, curMap, f);

    //     return water;
    // }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
pragma abicoder v2;
//import "../lib/forge-std/src/console.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IBATTLE {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Property {

    uint public constant NFT_TYPE_CHARACTER = 1;
    uint public constant NFT_TYPE_GUN = 2;
    uint public constant NFT_TYPE_BOMB = 3;
    uint public constant NFT_TYPE_ARMOR = 4;
    uint public constant NFT_TYPE_RING = 5;
    uint public constant NFT_TYPE_FOOD = 6;
    uint public constant NFT_TYPE_BOOTS = 7;

    function decodeType(uint encodeData) internal pure returns (uint) {
        uint t = encodeData >> 248;
        require(t > 0);
        return t;
    }

    function propertyCount(uint encodeData) internal pure returns (uint) {
        return encodeData & 0xffff;
    }

    // function encodeProperty(uint nftType, uint[] memory properties) internal pure returns (uint encodeData) {
    //     encodeData = (nftType << 248) | (properties.length);
    //     for(uint i = 0; i < properties.length; i++) {
    //         encodeData |= (properties[i] << (i * 16 + 16));
    //     }
    // }

    function encodeProperty1(uint nftType, uint property1) internal pure returns (uint encodeData) {
        encodeData = (nftType << 248) | 1;
        encodeData |= property1 << 16;
    }

    function encodeProperty2(uint nftType, uint property1, uint property2) internal pure returns (uint encodeData) {
        encodeData = (nftType << 248) | 2;
        encodeData |= property1 << 16;
        encodeData |= property2 << 32;
    }

    function encodeProperty3(uint nftType, uint property1, uint property2, uint property3) internal pure returns (uint encodeData) {
        encodeData = (nftType << 248) | 3;
        encodeData |= property1 << 16;
        encodeData |= property2 << 32;
        encodeData |= property3 << 48;
    }

    function encodeProperty4(uint nftType, uint property1, uint property2, uint property3, uint property4) internal pure returns (uint encodeData) {
        encodeData = (nftType << 248) | 4;
        encodeData |= property1 << 16;
        encodeData |= property2 << 32;
        encodeData |= property3 << 48;
        encodeData |= property4 << 64;
    }

    function decodeProperty1(uint encodeData) internal pure returns (uint) {
        return (encodeData >> 16) & 0xffff;
    }

    function decodeProperty2(uint encodeData) internal pure returns (uint, uint) {
        return ((encodeData >> 16) & 0xffff, (encodeData >> 32) & 0xffff);
    }

    function decodeProperty3(uint encodeData) internal pure returns (uint, uint, uint) {
        return ((encodeData >> 16) & 0xffff, (encodeData >> 32) & 0xffff, (encodeData >> 48) & 0xffff);
    }

    function decodeProperty4(uint encodeData) internal pure returns (uint, uint, uint, uint) {
        return ((encodeData >> 16) & 0xffff, (encodeData >> 32) & 0xffff, (encodeData >> 48) & 0xffff, (encodeData >> 64) & 0xffff);
    }

    /**
     * 0-16: hp
     * 16-32: max hp
     * 32-48: bag capacity
     */
    function decodeCharacterProperty(uint encodeData) internal pure returns (uint hp, uint maxHP, uint bagCapacity) {
        require(decodeType(encodeData) == NFT_TYPE_CHARACTER && propertyCount(encodeData) == 3, "not character");
        return decodeProperty3(encodeData);
    }

    function encodeCharacterProperty(uint hp, uint maxHP, uint bagCapacity) internal pure returns (uint) {
        return encodeProperty3(NFT_TYPE_CHARACTER, hp, maxHP, bagCapacity);
    }

    /**
     * 0-16: bullet count
     * 16-32: shoot range
     * 32-48: bullet damage
     * 48-64: triple damage chance
     */
    function decodeGunProperty(uint encodeData) internal pure returns (uint bulletCount, uint shootRange, uint bulletDamage, uint tripleDamageChance) {
        require(decodeType(encodeData) == NFT_TYPE_GUN && propertyCount(encodeData) == 4, "not gun");
        return decodeProperty4(encodeData);
    }

    function encodeGunProperty(uint bulletCount, uint shootRange, uint bulletDamage, uint tripleDamageChance) internal pure returns (uint) {
        return encodeProperty4(NFT_TYPE_GUN, bulletCount, shootRange, bulletDamage, tripleDamageChance);
    }

    /**
     * 0-16: throwing range
     * 16-32: explosion range
     * 32-48: damage
     */
    function decodeBombProperty(uint encodeData) internal pure returns (uint throwRange, uint explosionRange, uint damage) {
        require(decodeType(encodeData) == NFT_TYPE_BOMB && propertyCount(encodeData) == 3, "not bomb");
        return decodeProperty3(encodeData);
    }

    function encodeBombProperty(uint throwRange, uint explosionRange, uint damage) internal pure returns (uint) {
        return encodeProperty3(NFT_TYPE_BOMB, throwRange, explosionRange, damage);
    }

    /**
     * 
     * 0-16: defense
     */
    function decodeArmorProperty(uint encodeData) internal pure returns (uint defense) {
        require(decodeType(encodeData) == NFT_TYPE_ARMOR && propertyCount(encodeData) == 1, "not armor");
        return decodeProperty1(encodeData);
    }


    function encodeArmorProperty(uint defense) internal pure returns(uint) {
        return encodeProperty1(NFT_TYPE_ARMOR, defense);
    }

    /**
     * 
     * 0-16: dodgeCount
     * 16-32: dodgeChance
     */
    function decodeRingProperty(uint encodeData) internal pure returns (uint dodgeCount, uint dodgeChance) {
        require(decodeType(encodeData) == NFT_TYPE_RING && propertyCount(encodeData) == 2, "not ring");
        return decodeProperty2(encodeData);
    }

    function encodeRingProperty(uint dodgeCount, uint dodgeChance) internal pure returns(uint) {
        return encodeProperty2(NFT_TYPE_RING, dodgeCount, dodgeChance);
    }

    function decodeFoodProperty(uint encodeData) internal pure returns (uint heal) {
        require(decodeType(encodeData) == NFT_TYPE_FOOD && propertyCount(encodeData) == 1, "not food");
        return decodeProperty1(encodeData);
    }

    function encodeFoodProperty(uint heal) internal pure returns(uint) {
        return encodeProperty1(NFT_TYPE_FOOD, heal);
    }
    
    function decodeBootsProperty(uint encodeData) internal pure returns(uint usageCount, uint moveMaxSteps) {
        require(decodeType(encodeData) == NFT_TYPE_BOOTS && propertyCount(encodeData) == 2, "not boots");
        return decodeProperty2(encodeData);
    }

    function encodeBootsProperty(uint usageCount, uint moveMaxSteps) internal pure returns(uint) {
        return encodeProperty2(NFT_TYPE_BOOTS, usageCount, moveMaxSteps);
    }


    function newProperty(uint seed, uint probability) internal pure returns(uint property) {
        uint t = (probability >> (4 * (seed % 20))) & 0xf;
        seed = seed >> 8;
        property = 0;
        if (t == Property.NFT_TYPE_CHARACTER) {
            property = newCharacterProperty(seed);
        } else if (t == Property.NFT_TYPE_GUN) {
            property = newGunProperty(seed);
        } else if (t == Property.NFT_TYPE_BOMB) {
            property = newBombProperty(seed);
        } else if (t == Property.NFT_TYPE_ARMOR) {
            property = newArmorProperty(seed);
        } else if (t == Property.NFT_TYPE_RING) {
            property = newRingProperty(seed);
        } else if (t == Property.NFT_TYPE_FOOD) {
            property = newFoodProperty(seed);
        } else if (t == Property.NFT_TYPE_BOOTS) {
            property = newBootsProperty(seed);
        } else {
            revert("Unknown Type");
        }
    }

    /**
     * maxHp: 16-100(possible: 16, 20, 25, 33, 50, 100)
     * bagCapacity: 1-6(possible: 1-6)
     * maxHP * bagCapacity = 100 (volatility 30%)
     */
    function newCharacterProperty(uint seed) private pure returns (uint) {
        uint bagCapacity = seed % 6 + 1;
        uint hp = 100 * ((seed >> 4) % 60 + 70) / bagCapacity / 100;
        return encodeCharacterProperty(hp, hp, bagCapacity);
    }

    /**
     * bulletCount: 1-10: 1-10
     * shootRange: 1-16: 1-16
     * bulletDamage: 3-30: 3,7,10,15,30
     * criticalStrikeProbability: 10%-100%
     * 
     * bulletCount * (1 - 1/(shootRange/4+1)) * bulletDamage = 30 (volatility 30%)
     * bulletCount * criticalStrikeProbability = 100%
     */
    function newGunProperty(uint seed) private pure returns (uint) {
        uint bulletCount = seed % 10 + 1;
        uint shootRange = (seed >> 4) % 16 + 1;
        uint bulletDamage = 30 * ((seed >> 8) % 60 + 70) / bulletCount / (100 - 100/(shootRange/4+2));
        uint tripleDamageChance = 100 / bulletCount;
        return encodeGunProperty(bulletCount, shootRange, bulletDamage, tripleDamageChance);
    }

    /**
     * throwRange: 5-16
     * explosionRange: 1-10
     * damage: 10-100: 10, 11, 12, 14, 16, 20, 25, 33, 50, 100
     * 
     * explosionRange * damage = 100 (volatility 30%)
     */
    function newBombProperty(uint seed) private pure returns (uint) {
        uint throwRange = seed % 12 + 5;
        uint explosionRange = (seed >> 4) % 10 + 1;
        uint damage = 100 * ((seed >> 8) % 60 + 70) / explosionRange / 100;
        return encodeBombProperty(throwRange, explosionRange, damage);
    }

    /**
     * defense: 20-100
     */
    function newArmorProperty(uint seed) private pure returns (uint) {
        uint defense = seed % 80 + 20;
        return encodeArmorProperty(defense);
    }

    /**
     * dodgeCount: 3-6
     * dodgeChance: 50-100
     * 
     * dodgeChance * dodgeCount = 300 (volatility 30%)
     */
    function newRingProperty(uint seed) private pure returns (uint) {
        uint dodgeCount = seed % 4 + 3;
        uint dodgeChance = 300 * ((seed >> 8) % 60 + 70) / dodgeCount / 100;
        dodgeChance = dodgeChance > 100 ? 100 : dodgeChance;
        return encodeRingProperty(dodgeCount, dodgeChance);
    }

    /**
     * heal: 20-100
     */
    function newFoodProperty(uint seed) private pure returns (uint) {
        uint heal = seed % 80 + 20;
        return encodeFoodProperty(heal);
    }

    /**
     * usageCount: 1-3
     * moveMaxSteps: 5-15: 5, 10, 15
     * 
     * usageCount * moveMaxSteps = 15 (volatility 30%)
     */
    function newBootsProperty(uint seed) private pure returns (uint) {
        uint usageCount = seed % 3 + 1;
        uint moveMaxSteps = 15 * ((seed >> 8) % 60 + 70) / usageCount / 100;
        return encodeBootsProperty(usageCount, moveMaxSteps);
    }
}