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
        uint256 tokenId;
    }

    event PlayGame(address indexed player, uint256 indexed id);

    event PlayGameResult(
        address indexed player,
        uint256 indexed id,
        uint256 seed,
        uint256 tokenId
    );

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    mapping(uint256 => GameInfo) playerGameInfo;

    mapping(address => uint256[]) playerGameIds;

    mapping(uint256 => uint256) levelTokenId;

    address public owner;

    address public l2Unicorn;

    address public l2;

    uint256 public costAmount;

    IRandomizer private _randomizer;

    constructor(address randomizer_, address l2Unicorn_, address l2_) {
        _randomizer = IRandomizer(randomizer_);
        l2Unicorn = l2Unicorn_;
        l2 = l2_;
        owner = msg.sender;
        costAmount = 10e18;
        emit OwnershipTransferred(address(0), owner);
    }

    function play(uint256 gasPrice_) payable external {
        //randomizerFee
        uint256 callbackGasLimit_ = 50000;
        uint256 randomizerFee_ = estimateFeeUsingConfirmationsAndGasPrice(callbackGasLimit_, 2, gasPrice_);
        require(msg.value >= randomizerFee_, "L2UnicornMinter: randomizer fee insufficient");
        depositFund();
        //
        require(IL2Unicorn(l2Unicorn).minter() == address(this), "L2UnicornMinter: L2Unicorn not call");
        require(!IPausable(l2Unicorn).paused(), "L2UnicornMinter: L2Unicorn already paused");
        require(costAmount > 0 && IERC20(l2).transferFrom(msg.sender, address(this), costAmount), "L2UnicornMinter: L2 transfer failure");
        //
        uint256 id = _randomizer.request(callbackGasLimit_);
        playerGameIds[msg.sender].push(id);
        playerGameInfo[id] = GameInfo(msg.sender, 0, 0);
        emit PlayGame(msg.sender, id);
    }

    function randomizerCallback(uint256 id_, bytes32 value_) external {
        uint256 seed_ = uint256(value_);
        require(msg.sender == address(_randomizer), "L2UnicornMinter: only the randomizer contract can call this function");
        GameInfo storage gameInfo_ = playerGameInfo[id_];
        gameInfo_.seed = seed_;
        if (seed_ != 0) {
            uint256 randomNum_ = getRandomNum(seed_);
            uint256 tokenId_ = _calTokenId(randomNum_);
            IL2Unicorn(l2Unicorn).mintForMinter(gameInfo_.player, tokenId_);
            gameInfo_.tokenId = tokenId_;
            emit PlayGameResult(gameInfo_.player, id_, seed_, tokenId_);
        } else {
            emit PlayGameResult(gameInfo_.player, id_, seed_, 0);
        }
    }

    function getRandomNum(uint256 seed_) public pure returns (uint256) {
        return seed_ % 1e10;
    }

    function getGameInfoById(uint256 id_) external view returns (GameInfo memory) {
        return playerGameInfo[id_];
    }

    function getPlayerGameIds(address player_) external view returns (uint256[] memory){
        return playerGameIds[player_];
    }

    function setCostAmount(uint256 costAmount_) external {
        require(msg.sender == owner, "L2UnicornMinter: caller is not the owner");
        costAmount = costAmount_;
    }

    /* Non-game functions */

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "L2UnicornMinter: caller is not the owner");
        require(newOwner != address(0), "L2UnicornMinter: new owner is the zero address");
        owner = newOwner;
    }

    function depositFund() public payable {
        _randomizer.clientDeposit{value : msg.value}(address(this));
    }

    function withdrawFund() external {
        require(msg.sender == owner, "L2UnicornMinter: caller is not the owner");
        _withdrawFund1();
    }

    function withdrawFund(uint256 amount_) external {
        require(msg.sender == owner, "L2UnicornMinter: caller is not the owner");
        _withdrawFund2(amount_);
    }

    function _withdrawFund1() internal {
        (uint256 balance_, uint256 balance2_) = balanceOfFund();
        _withdrawFund2(balance_ - balance2_);
    }

    function _withdrawFund2(uint256 amount_) internal {
        require(amount_ > 0, "L2UnicornMinter: balance is zero");
        _randomizer.clientWithdrawTo(msg.sender, amount_);
    }

    function balanceOfFund() public view returns (uint256, uint256){
        return _randomizer.clientBalanceOf(address(this));
    }

    function estimateFee(uint256 callbackGasLimit) external view returns (uint256) {
        return _randomizer.estimateFee(callbackGasLimit);
    }

    function estimateFee(uint256 callbackGasLimit, uint256 confirmations) external view returns (uint256) {
        return _randomizer.estimateFee(callbackGasLimit, confirmations);
    }

    function estimateFeeUsingGasPrice(uint256 callbackGasLimit, uint256 gasPrice) external view returns (uint256) {
        return _randomizer.estimateFeeUsingGasPrice(callbackGasLimit, gasPrice);
    }

    function estimateFeeUsingConfirmationsAndGasPrice(uint256 callbackGasLimit, uint256 confirmations, uint256 gasPrice) public view returns (uint256) {
        return _randomizer.estimateFeeUsingConfirmationsAndGasPrice(callbackGasLimit, confirmations, gasPrice);
    }

    function adjustLevelTokenId(uint256 level_, uint256 tokenId_) external {
        require(msg.sender == owner, "L2UnicornMinter: caller is not the owner");
        levelTokenId[level_] = tokenId_;
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

    function _calTokenId(uint256 randomNum_) private returns (uint256) {
        (uint level, uint startTokenId, uint endTokenId) = getLevelInfo(randomNum_);
        uint256 tokenId;
        if (level != type(uint8).max) {
            if (levelTokenId[level] == 0) {
                levelTokenId[level] = startTokenId;
            }
            tokenId = levelTokenId[level];
            if (tokenId <= endTokenId) {
            unchecked {levelTokenId[level]++;}
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

    function mintForMinter(address to_, uint256 tokenId_) external;

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