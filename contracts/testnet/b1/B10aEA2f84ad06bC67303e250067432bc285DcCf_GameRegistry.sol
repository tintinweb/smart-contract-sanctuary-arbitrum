// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {IGameRegistry} from "./interfaces/IGameRegistry.sol";
import {Position, PlayerStats, PlayerStatsResponse} from "./interfaces/Types.sol";

contract GameRegistry is IGameRegistry {
    mapping(address => PlayerStats) private _playersStats;

    uint public bulletPrice;
    address private _balanceReceiver;

    constructor(uint bulletPrice_, address balanceReceiver) {
        bulletPrice = bulletPrice_;
        _balanceReceiver = balanceReceiver;
    }

    function initPlayer(address player_, Position[] calldata ethersPosition_) public {
        require(_playersStats[player_].ethersAmount == _playersStats[player_].wreckedEthers, "Game is not over");

        uint amount = ethersPosition_.length;

        _playersStats[player_].ethersAmount = amount;

        for (uint i = 0; i < amount; ) {
            _playersStats[player_].ethersPosition[i] = ethersPosition_[i];

            unchecked {
                ++i;
            }
        }
    }

    function updatePlayerPosition(address player_, Position calldata newPosition_) public {
        _playersStats[player_].currentPosition = newPosition_;
    }

    function removeBullets(address player_, uint amount_) public {
        require(_playersStats[player_].bullets >= amount_, "No more bullets");

        _playersStats[player_].bullets -= amount_;
    }

    function removeEther(address player_, uint[] calldata ids_) public {
        uint removeAmount = ids_.length;

        require(
            _playersStats[player_].ethersAmount >= _playersStats[player_].wreckedEthers + removeAmount,
            "No more ethers"
        );

        for (uint i = 0; i < removeAmount; ) {
            delete _playersStats[player_].ethersPosition[i];

            unchecked {
                ++i;
            }
        }

        _playersStats[player_].wreckedEthers += removeAmount;
    }

    function buyBullets(address player_, uint amount_) public payable {
        require(amount_ * bulletPrice <= msg.value, "Not enough funds");

        (bool sent, ) = payable(_balanceReceiver).call{value: msg.value}("");

        require(sent, "Fund transfer failure");

        _playersStats[player_].bullets += amount_;
    }

    function getGameData(address player_) public view returns (PlayerStatsResponse memory response) {
        uint liveEthersAmount = _playersStats[player_].ethersAmount - _playersStats[player_].wreckedEthers;
        Position[] memory ethersPositionArray = new Position[](liveEthersAmount);
        uint[] memory ethersIdArray = new uint[](liveEthersAmount);
        uint pushId;

        for (uint i = 0; i < _playersStats[player_].ethersAmount && pushId < liveEthersAmount; ) {
            if (_playersStats[player_].ethersPosition[i].x != 0) {
                ethersPositionArray[pushId] = _playersStats[player_].ethersPosition[i];
                ethersIdArray[pushId] = i;

                unchecked {
                    ++pushId;
                }
            }

            unchecked {
                ++i;
            }
        }

        response = PlayerStatsResponse({
            bullets: _playersStats[player_].bullets,
            currentPosition: _playersStats[player_].currentPosition,
            ethersAmount: _playersStats[player_].ethersAmount,
            ethersPosition: ethersPositionArray,
            ethersId: ethersIdArray,
            wreckedEthers: _playersStats[player_].wreckedEthers
        });
    }

    fallback() external payable {
        revert("Not implemented");
    }

    // Receive is a variant of fallback that is triggered when msg.data is empty
    receive() external payable {
        revert("Not implemented");
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