// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IRandomizer} from "../interfaces/IRandomizer.sol";

import {BaseRandomizer} from "./BaseRandomizer.sol";

abstract contract BaseGame is BaseRandomizer {

    struct GameInfo {
        address user;
        uint256 seed;
        uint256 result;
    }

    event Play(address indexed user, uint256 indexed id);

    event PlayResult(
        address indexed user,
        uint256 indexed id,
        uint256 seed
    );

    mapping(address => uint256) private _userRequestCount;

    mapping(address => mapping(uint256 => uint256)) private _userRequestIds;

    mapping(uint256 => GameInfo) private _requestIdGameInfo;

    constructor(address randomizer_) BaseRandomizer(randomizer_) {}

    // public

    function getGameResult(uint256 seed_) public virtual returns (uint256);

    // external

    function viewGameInfos(address user_, uint256 startIndex_, uint256 endIndex_) external view returns (GameInfo[] memory gameInfos){
        if (startIndex_ >= 0 && endIndex_ >= startIndex_) {
            uint len = endIndex_ + 1 - startIndex_;
            uint total = _userRequestCount[user_];
            uint arrayLen = len > total ? total : len;
            gameInfos = new GameInfo[](arrayLen);
            uint arrayIndex_ = 0;
            for (uint index_ = startIndex_; index_ < ((endIndex_ > total) ? total : endIndex_);) {
                uint256 requestId_ = _userRequestIds[user_][index_];
                gameInfos[arrayIndex_] = _requestIdGameInfo[requestId_];
                unchecked{++index_; ++arrayIndex_;}
            }
        }
        return gameInfos;
    }

    // internal

    function afterPlay(address user_, uint256 callbackGasLimit_) internal {
        uint256 requestId_ = IRandomizer(randomizer()).request(callbackGasLimit_);
        _requestIdGameInfo[requestId_] = GameInfo(user_, 0, 0);
        _userRequestIds[user_][_userRequestCount[user_]] = requestId_;
        _userRequestCount[user_] += 1;
        emit Play(user_, requestId_);
    }

    function beforeRandomizerCallback(uint256 requestId_, bytes32 value_) internal returns (address, uint256, uint256){
        require(msg.sender == randomizer(), "BaseRandomizer: only the randomizer contract can call this function");
        uint256 seed_ = uint256(value_);
        GameInfo storage gameInfo_ = _requestIdGameInfo[requestId_];
        gameInfo_.seed = seed_;
        gameInfo_.result = getGameResult(seed_);
        emit PlayResult(gameInfo_.user, requestId_, seed_);
        return (gameInfo_.user, gameInfo_.seed, gameInfo_.result);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IRandomizer} from "../interfaces/IRandomizer.sol";

import {BaseRandomizer} from "./BaseRandomizer.sol";

abstract contract BaseOwnable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address private _owner;

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    // public

    function owner() public view returns (address) {
        return _owner;
    }

    // external

    function transferOwnership(address newOwner_) external {
        require(msg.sender == owner(), "L2UnicornMinter: caller is not the owner");
        require(newOwner_ != address(0), "L2UnicornMinter: new owner is the zero address");
        _owner = newOwner_;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IRandomizer} from "../interfaces/IRandomizer.sol";

import {BaseOwnable} from "./BaseOwnable.sol";

abstract contract BaseRandomizer is BaseOwnable {

    address private _randomizer;

    constructor(address randomizer_) {
        _randomizer = randomizer_;
    }

    // public

    function randomizer() public view returns (address) {
        return _randomizer;
    }

    function depositFund() public payable {
        IRandomizer(_randomizer).clientDeposit{value : msg.value}(address(this));
    }

    function balanceOfFund() public view returns (uint256, uint256){
        return IRandomizer(_randomizer).clientBalanceOf(address(this));
    }

    function estimateFeeUsingConfirmationsAndGasPrice(uint256 callbackGasLimit, uint256 confirmations, uint256 gasPrice) public view returns (uint256) {
        return IRandomizer(_randomizer).estimateFeeUsingConfirmationsAndGasPrice(callbackGasLimit, confirmations, gasPrice);
    }

    function withdrawFund(uint256 amount_) public {
        require(msg.sender == owner(), "Randomizer: caller is not the owner");
        require(amount_ > 0, "Randomizer: amount is zero");
        IRandomizer(_randomizer).clientWithdrawTo(msg.sender, amount_);
    }

    // external

    function withdrawFund() external {
        (uint256 balance_, uint256 balance2_) = balanceOfFund();
        withdrawFund(balance_ - balance2_);
    }

    function estimateFee(uint256 callbackGasLimit) external view returns (uint256) {
        return IRandomizer(_randomizer).estimateFee(callbackGasLimit);
    }

    function estimateFee(uint256 callbackGasLimit, uint256 confirmations) external view returns (uint256) {
        return IRandomizer(_randomizer).estimateFee(callbackGasLimit, confirmations);
    }

    function estimateFeeUsingGasPrice(uint256 callbackGasLimit, uint256 gasPrice) external view returns (uint256) {
        return IRandomizer(_randomizer).estimateFeeUsingGasPrice(callbackGasLimit, gasPrice);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {BaseGame} from "../abstract/BaseGame.sol";

import {IL2Unicorn} from "../interfaces/IL2Unicorn.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IPausable} from "../interfaces/IPausable.sol";

contract L2UnicornMinter is BaseGame {

    address public l2Unicorn;

    address public l2;

    uint256 public costAmount;

    mapping(uint256 => uint256) private _levelTokenId;

    constructor(address randomizer_, address l2Unicorn_, address l2_) BaseGame(randomizer_) {
        l2Unicorn = l2Unicorn_;
        l2 = l2_;
        costAmount = 100e18;
    }

    function play(uint256 gasPrice_, uint256 callCount) payable external {
        uint256 callbackGasLimit_ = 50000;
        //
        require(callCount > 0, "L2UnicornMinter: call count greater than 0");
        require(IL2Unicorn(l2Unicorn).minter() == address(this), "L2UnicornMinter: L2Unicorn not call");
        require(!IPausable(l2Unicorn).paused(), "L2UnicornMinter: L2Unicorn already paused");
        require(costAmount > 0 && IERC20(l2).transferFrom(msg.sender, address(this), callCount * costAmount), "L2UnicornMinter: L2 transfer failure");
        //
        uint256 randomizerFee_ = estimateFeeUsingConfirmationsAndGasPrice(callbackGasLimit_, 2, gasPrice_);
        require(msg.value >= callCount * randomizerFee_, "L2UnicornMinter: randomizer fee insufficient");
        depositFund();
        //
        for (uint index_ = 0; index_ < callCount;) {
            afterPlay(msg.sender, callbackGasLimit_);
            unchecked{++index_;}
        }
    }

    function randomizerCallback(uint256 id, bytes32 value) external {
        (address user,,uint256 result) = beforeRandomizerCallback(id, value);
        IL2Unicorn(l2Unicorn).mintWithMinter(user, result);
    }

    function getGameResult(uint256 seed_) public override returns (uint256) {
        uint256 number = seed_ % 1e10;
        return _getTokenIdByRandomNumber(number);
    }

    function setCostAmount(uint256 costAmount_) external {
        require(msg.sender == owner(), "L2UnicornMinter: caller is not the owner");
        costAmount = costAmount_;
    }

    function adjustLevelTokenId(uint256 level_, uint256 tokenId_) external {
        require(msg.sender == owner(), "L2UnicornMinter: caller is not the owner");
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