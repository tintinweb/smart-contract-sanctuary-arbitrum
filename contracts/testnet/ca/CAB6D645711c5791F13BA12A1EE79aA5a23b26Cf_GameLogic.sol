// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {IGameRegistry} from "./interfaces/IGameRegistry.sol";
import {Position, PlayerStats, PlayerStatsResponse} from "./interfaces/Types.sol";

contract GameLogic {
    IGameRegistry public gameRegistry;

    constructor(address gameRegistry_) {
        gameRegistry = IGameRegistry(gameRegistry_);
    }

    function start(Position[] calldata ethersPosition_) external {
        gameRegistry.initPlayer(msg.sender, ethersPosition_);
    }

    function buyBullets(uint amount_) external payable {
        gameRegistry.buyBullets{value: msg.value}(msg.sender, amount_);
    }

    function getGameData() external view returns (PlayerStatsResponse memory) {
        return gameRegistry.getGameData(msg.sender);
    }

    function registerAction(
        uint[] calldata etherIds_,
        uint bulletsAmount_,
        Position calldata newPlayerPosition_
    ) external {
        if (bulletsAmount_ > 0) {
            gameRegistry.removeBullets(msg.sender, bulletsAmount_);
        }

        if (etherIds_.length > 0) {
            gameRegistry.removeEther(msg.sender, etherIds_);
        }

        if (newPlayerPosition_.x != 0 && newPlayerPosition_.y != 0 && newPlayerPosition_.z != 0) {
            gameRegistry.updatePlayerPosition(msg.sender, newPlayerPosition_);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Position, PlayerStats, PlayerStatsResponse} from "./Types.sol";

interface IGameRegistry {
    function initPlayer(address player_, Position[] calldata ethersPosition_) external;

    function updatePlayerPosition(address player_, Position calldata newPosition_) external;

    function removeBullets(address player_, uint256 amount_) external;

    function removeEther(address player_, uint256[] calldata ids_) external;

    function buyBullets(address player_, uint256 amount_) external payable;

    function getGameData(address player_) external view returns (PlayerStatsResponse memory response);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

struct Position {
    int256 x;
    int256 y;
    int256 z;
}

struct PlayerStats {
    uint256 bullets;
    Position currentPosition;
    uint256 ethersAmount;
    mapping(uint256 => Position) ethersPosition;
    uint256 wreckedEthers;
}

struct PlayerStatsResponse {
    uint256 bullets;
    Position currentPosition;
    uint256 ethersAmount;
    Position[] ethersPosition;
    uint256[] ethersId;
    uint256 wreckedEthers;
}