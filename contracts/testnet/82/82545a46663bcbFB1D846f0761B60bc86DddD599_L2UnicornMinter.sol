// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IRandomizer} from "../interfaces/IRandomizer.sol";
import {IL2Unicorn} from "../interfaces/IL2Unicorn.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IPausable} from "../interfaces/IPausable.sol";

contract L2UnicornMinter {

    struct GameInfo {
        address player;
        uint256 seed;
    }

    event Play(address indexed player, uint256 indexed id);

    event PlayResult(
        address indexed player,
        uint256 indexed id,
        uint256 seed
    );

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    mapping(uint256 => GameInfo) private gameInfos;

    mapping(address => uint256[]) private playerRequestIds;

    mapping(uint256 => uint256) private _levelTokenId;

    address public owner;

    address public l2Unicorn;

    address public l2;

    uint256 public costAmount;

    IRandomizer private randomizer;

    constructor(address randomizer_, address l2Unicorn_, address l2_) {
        randomizer = IRandomizer(randomizer_);
        l2Unicorn = l2Unicorn_;
        l2 = l2_;
        owner = msg.sender;
        costAmount = 100e18;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Called by player to initiate a coinflip
     * Using randomizer's request id as the game id
     */
    function play() external {
        uint256 id = randomizer.request(500000);
        playerRequestIds[msg.sender].push(id);
        gameInfos[id] = GameInfo(msg.sender, 0);
        emit Play(msg.sender, id);
    }

    // @dev The callback function called by randomizer when the random bytes are ready
    function randomizerCallback(uint256 _id, bytes32 _value) external {
        require(
            msg.sender == address(randomizer),
            "Only the randomizer contract can call this function"
        );
        GameInfo storage game = gameInfos[_id];
        uint256 seed = uint256(_value);
        game.seed = seed;
        /*uint256 randomNum_ = getRandomNum(seed);
        uint256 tokenId_ = _getTokenIdByRandomNumber(randomNum_);
        IL2Unicorn(l2Unicorn).mintWithMinter(game.player, tokenId_);*/
        emit PlayResult(game.player, _id, seed);
    }

    function getRandomNum(uint256 seed_) public pure returns (uint256) {
        return seed_ % 1e10;
    }

    function setCostAmount(uint256 costAmount_) external {
        require(msg.sender == owner, "L2UnicornMinter: caller is not the owner");
        costAmount = costAmount_;
    }

    function getGameInfo(uint256 _id) external view returns (GameInfo memory) {
        return gameInfos[_id];
    }

    function getPlayerGameIds(address _player) external view returns (uint256[] memory){
        return playerRequestIds[_player];
    }

    /* Non-game functions */

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "L2UnicornMinter: caller is not the owner");
        require(newOwner != address(0), "L2UnicornMinter: new owner is the zero address");
        owner = newOwner;
    }

    function depositFund() external payable {
        randomizer.clientDeposit{value : msg.value}(address(this));
    }

    function withdrawFund() external {
        require(msg.sender == owner);
        (uint256 balance_,uint256 balance2_) = balanceOfFund();
        require(balance_ > 0, "L2Unicorn: balance is zero");
        randomizer.clientWithdrawTo(msg.sender, (balance_ - balance2_));
    }

    function withdrawFund(uint256 amount_) external {
        require(msg.sender == owner);
        require(amount_ > 0, "L2Unicorn: amount is zero");
        randomizer.clientWithdrawTo(msg.sender, amount_);
    }

    function balanceOfFund() public view returns (uint256, uint256){
        return randomizer.clientBalanceOf(address(this));
    }

    function estimateFee(uint256 callbackGasLimit) external view returns (uint256) {
        return randomizer.estimateFee(callbackGasLimit);
    }

    function estimateFee(uint256 callbackGasLimit, uint256 confirmations) external view returns (uint256) {
        return randomizer.estimateFee(callbackGasLimit, confirmations);
    }

    function estimateFeeUsingGasPrice(uint256 callbackGasLimit, uint256 gasPrice) external view returns (uint256) {
        return randomizer.estimateFeeUsingGasPrice(callbackGasLimit, gasPrice);
    }

    function estimateFeeUsingConfirmationsAndGasPrice(uint256 callbackGasLimit, uint256 confirmations, uint256 gasPrice) external view returns (uint256) {
        return randomizer.estimateFeeUsingConfirmationsAndGasPrice(callbackGasLimit, confirmations, gasPrice);
    }

    function adjustLevelTokenId(uint256 level_, uint256 tokenId_) external {
        require(msg.sender == owner, "L2UnicornMinter: caller is not the owner");
        require(level_ >= 0 && level_ <= 9, "L2UnicornMinter: level invalid value");
        require(_levelTokenId[level_] != tokenId_ && tokenId_ > _levelTokenId[level_], "L2UnicornMinter: tokenId invalid value");
        _levelTokenId[level_] += tokenId_;
    }

    function levelTokenId(uint256 level_) public view returns (uint256) {
        return _levelTokenId[level_];
    }

    function getLevelInfo(uint256 randomNum_) public pure returns (uint, uint, uint) {
        if (randomNum_ >= 1 && randomNum_ <= 4388888500) {
            return (0, 100000000001, 200000000000);
        } else if (randomNum_ >= 4388888501 && randomNum_ <= 9388888500) {
            return (1, 10000000001, 20000000000);
        } else if (randomNum_ >= 9388888501 && randomNum_ <= 9888888500) {
            return (2, 1000000001, 2999900000);
        } else if (randomNum_ >= 9888888501 && randomNum_ <= 9988888500) {
            return (3, 100000001, 200000000);
        } else if (randomNum_ >= 9988888501 && randomNum_ <= 9998888500) {
            return (4, 10000001, 20000000);
        } else if (randomNum_ >= 9998888501 && randomNum_ <= 9999888500) {
            return (5, 1000001, 2000000);
        } else if (randomNum_ >= 9999888501 && randomNum_ <= 9999988500) {
            return (6, 100001, 200000);
        } else if (randomNum_ >= 9999988501 && randomNum_ <= 9999998500) {
            return (7, 10001, 20000);
        } else if (randomNum_ >= 9999998501 && randomNum_ <= 9999999500) {
            return (8, 1001, 2000);
        } else if (randomNum_ >= 9999999501 && randomNum_ <= 10000000000) {
            return (9, 1, 500);
        } else {
            return (type(uint).max, 0, 0);
        }
    }

    function _getTokenIdByRandomNumber(uint256 randomNum_) private returns (uint256) {
        (uint level, uint startTokenId, uint endTokenId) = getLevelInfo(randomNum_);
        uint256 tokenId;
        if (level != type(uint8).max) {
            if (_levelTokenId[level] == 0) {
                _levelTokenId[level] = startTokenId;
            }
            tokenId = _levelTokenId[level];
            if (tokenId <= endTokenId) {
                unchecked {_levelTokenId[level]++;}
            } else {
                tokenId = 0;
            }
        } else {
            tokenId = 0;
        }
        return tokenId;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IL2Unicorn {

    function minter() external view returns (address);

    function mintWithMinter(address to_, uint256 tokenId_) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPausable {

    function paused() external view returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRandomizer {

    function request(uint256 callbackGasLimit) external returns (uint256);

    function clientDeposit(address client) external payable;

    function clientWithdrawTo(address to, uint256 amount) external;

    function clientBalanceOf(address client) external view returns (uint256, uint256);

    function estimateFee(uint256 callbackGasLimit) external view returns (uint256);

    function estimateFee(uint256 callbackGasLimit, uint256 confirmations) external view returns (uint256);

    function estimateFeeUsingGasPrice(uint256 callbackGasLimit, uint256 gasPrice) external view returns (uint256);

    function estimateFeeUsingConfirmationsAndGasPrice(uint256 callbackGasLimit, uint256 confirmations, uint256 gasPrice) external view returns (uint256);

}