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
import "../BATTLE.sol";
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
        playersReward[p.player] = Utils.addReward(playersReward[p.player], p.config.playerRewardToken, 0);
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
        // address[] memory
        uint tileSize = mapSize / 8;
        uint tilePos = state.initedTileCount;
        if(tilePos < tileSize * tileSize) {
            uint curMap = Map.genTile(mapSeed, tilePos, mapSize);
            tilemap[tilePos] = curMap;
            state.initedTileCount = uint16(tilePos + 1);
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
        require(tokenReward >= config.playerRewardToken, "Reward Claimed!");
        playersReward[player] = Utils.encodeReward(tokenReward - config.playerRewardToken, nftReward);
        (,,,uint[] memory tokenIds) = PlayerDataHelper.decode(playersData[player]);
        // send back tokens
        for(uint i = 0; i < tokenIds.length; i++) {
            nft.transferFrom(address(this), player, tokenIds[i]);
        }
        _removePlayer(players, playersData, player);
        emit RegisterGame(state.round, player, false, tokenIds);
    }


    function claimReward(mapping(address => uint) storage playersReward, BATTLE battleToken, IBattleRoyaleNFT nft, address owner, uint tax, address player) external {
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
            playersReward[winerAddr] = Utils.addReward(playersReward[winerAddr], config.winnerRewardToken, config.winnerRewardNFT);
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
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BATTLE is ERC20Permit, Ownable {

    mapping(address => bool) public games;

    constructor() ERC20Permit("Battle Token") ERC20("Battle Token", "BATTLE") {}

    modifier onlyGame() {
        require(games[msg.sender], "Only Game");
        _;
    }

    /**
     * mints $BATTLE to a recipient
     * @param to the recipient of the $BATTLE
     * @param amount the amount of $BATTLE to mint
     */
    function mint(address to, uint256 amount) external onlyGame {
        _mint(to, amount);
    }

    /**
     * burns $BATTLE from a holder
     * @param from the holder of the $BATTLE
     * @param amount the amount of $BATTLE to burn
     */
    function burn(address from, uint256 amount) external onlyGame {
        _burn(from, amount);
    }

    function setGame(address game, bool enable) external onlyOwner {
        games[game] = enable;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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