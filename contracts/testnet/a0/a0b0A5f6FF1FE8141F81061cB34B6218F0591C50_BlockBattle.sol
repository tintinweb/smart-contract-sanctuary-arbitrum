// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract BlockBattle {
    enum AssetType {
        Gun,
        Vehicle,
        Character
    }
    address public owner;
    struct Player {
        string name;
        uint coins;
        uint diamonds;
        uint level;
        address walletAddress;
        Asset[] ownedAssets;
    }

    constructor() {
        owner = msg.sender;
    }

    struct Asset {
        string name;
        string imageHash;
        uint price;
        uint strength;
        uint armorPower;
        uint rateOfFire;
        uint range;
        uint speed;
        AssetType assetType;
    }

    struct Game {
        address[] players;
        address winner;
        uint highestKills;
    }

    struct NFT {
        string imageHash;
        uint playerRoomId;
    }

    mapping(address => Player) public players;
    mapping(uint => Asset) public guns;
    mapping(uint => Asset) public characters;
    mapping(uint => Asset) public vehicles;
    mapping(uint => Game) public games;
    mapping(address => NFT[]) public playerNFTs;
    mapping(address => uint) public kills;

    function registerPlayer(
        address playerAddress,
        string memory playerName
    ) public {
        Player storage newPlayer = players[playerAddress];
        newPlayer.name = playerName;
        newPlayer.coins = 200;
        newPlayer.diamonds = 10;
        newPlayer.level = 0;
        newPlayer.walletAddress = playerAddress;
    }

    function isPlayerRegistered(
        address playerAddress
    ) public view returns (bool) {
        return players[playerAddress].walletAddress != address(0);
    }

    function addGun(
        uint gunId,
        string memory name,
        string memory imageHash,
        uint price,
        uint rateOfFire,
        uint gunRange
    ) public {
        guns[gunId] = Asset(
            name,
            imageHash,
            price,
            0,
            0,
            rateOfFire,
            gunRange,
            0,
            AssetType.Gun
        );
    }

    function addCharacter(
        uint characterId,
        string memory name,
        string memory imageHash,
        uint price,
        uint strength,
        uint armorPower
    ) public {
        characters[characterId] = Asset(
            name,
            imageHash,
            price,
            strength,
            armorPower,
            0,
            0,
            0,
            AssetType.Character
        );
    }

    function addVehicle(
        uint vehicleId,
        string memory name,
        string memory imageHash,
        uint price,
        uint vehicleRange,
        uint speed
    ) public {
        vehicles[vehicleId] = Asset(
            name,
            imageHash,
            price,
            0,
            0,
            0,
            vehicleRange,
            speed,
            AssetType.Vehicle
        );
    }

    function buyAsset(
        address playerAddress,
        uint assetId,
        AssetType assetType
    ) public payable {
        require(isPlayerRegistered(playerAddress), "Player not registered");

        Asset memory assetToBuy;
        if (assetType == AssetType.Gun) {
            assetToBuy = guns[assetId];
        } else if (assetType == AssetType.Vehicle) {
            assetToBuy = vehicles[assetId];
        } else if (assetType == AssetType.Character) {
            assetToBuy = characters[assetId];
        }

        require(msg.value == assetToBuy.price, "Incorrect payment amount");

        Asset storage newAsset = players[playerAddress].ownedAssets.push();
        newAsset.name = assetToBuy.name;
        newAsset.imageHash = assetToBuy.imageHash;
        newAsset.price = assetToBuy.price;
        newAsset.strength = assetToBuy.strength;
        newAsset.armorPower = assetToBuy.armorPower;
        newAsset.rateOfFire = assetToBuy.rateOfFire;
        newAsset.range = assetToBuy.range;
        newAsset.speed = assetToBuy.speed;
        newAsset.assetType = assetToBuy.assetType;
        payable(owner).transfer(msg.value);
    }

    function startGame(uint gameId, address[] memory gamePlayers) public {
        games[gameId] = Game(gamePlayers, address(0), 0);
    }

    function getPlayerData(
        address playerAddress
    ) public view returns (Player memory) {
        require(isPlayerRegistered(playerAddress), "Player not registered");
        return players[playerAddress];
    }

    function endGame(
        uint gameId,
        address winner,
        uint highestKills,
        string memory imageHash
    ) public {
        Game storage game = games[gameId];
        game.winner = winner;
        game.highestKills = highestKills;
        _mintNFT(gameId, imageHash, winner);
        _updatePlayerLevels(game.players, winner);

        for (uint i = 0; i < game.players.length; i++) {
            if (game.players[i] != winner) {
                players[game.players[i]].coins -= 10;
            }
        }
    }

    function getPlayerAssets(
        address playerAddress
    ) public view returns (Asset[] memory) {
        return players[playerAddress].ownedAssets;
    }

    function updatePlayerProfile(
        address playerAddress,
        string memory newName
    ) public {
        players[playerAddress].name = newName;
    }

    function _mintNFT(
        uint gameId,
        string memory imageHash,
        address playerAddress
    ) private {
        NFT memory newNFT = NFT(imageHash, gameId);
        playerNFTs[playerAddress].push(newNFT);
    }

    function getPlayerNFTs(
        address playerAddress
    ) public view returns (NFT[] memory) {
        return playerNFTs[playerAddress];
    }

    function _updatePlayerLevels(
        address[] memory gamePlayers,
        address winner
    ) private {
        for (uint i = 0; i < gamePlayers.length; i++) {
            if (gamePlayers[i] == winner) {
                players[winner].level += 1;
            }
        }
    }
}