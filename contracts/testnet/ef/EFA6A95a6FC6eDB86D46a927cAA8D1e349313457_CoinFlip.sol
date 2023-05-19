// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IRandomizer} from "../interfaces/IRandomizer.sol";

import {BaseRandomizer} from "./BaseRandomizer.sol";

abstract contract BaseGame is BaseRandomizer {

    struct GameInfo {
        address user;
        uint256 playCount;
        bytes32 seed;
    }

    event Play(address indexed user, uint256 indexed id);

    event PlayResult(
        address indexed user,
        uint256 indexed requestId,
        bytes32 seed
    );

    mapping(address => uint256) private _userRequestCount;

    mapping(address => mapping(uint256 => uint256)) private _userRequestIds;

    mapping(uint256 => GameInfo) private _requestIdGameInfo;

    constructor(address randomizer_) BaseRandomizer(randomizer_) {}

    // external

    function viewGameInfo(uint256 requestId_) external view returns (GameInfo memory){
        return _requestIdGameInfo[requestId_];
    }

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

    function afterPlay(address user_, uint256 playCount_, uint256 callbackGasLimit_) internal {
        require(playCount_ > 0, "BaseGame: play count greater than 0");
        uint256 requestId_ = IRandomizer(randomizer()).request(callbackGasLimit_);
        _requestIdGameInfo[requestId_] = GameInfo(user_, playCount_, "");
        _userRequestIds[user_][_userRequestCount[user_]] = requestId_;
        _userRequestCount[user_] += 1;
        emit Play(user_, requestId_);
    }

    function beforeRandomizerCallback(uint256 requestId_, bytes32 seed_) internal returns (address, uint256) {
        require(msg.sender == randomizer(), "BaseGame: only the randomizer contract can call this function");
        GameInfo storage gameInfo_ = _requestIdGameInfo[requestId_];
        gameInfo_.seed = seed_;
        emit PlayResult(gameInfo_.user, requestId_, seed_);
        return (gameInfo_.user, gameInfo_.playCount);
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

import {IRandomizer} from "../interfaces/IRandomizer.sol";

import {BaseGame} from "../abstract/BaseGame.sol";

contract CoinFlip is BaseGame {

    constructor(address randomizer_) BaseGame(randomizer_) {}

    function play() external {
        afterPlay(msg.sender, 1, 100000);
    }

    function randomizerCallback(uint256 id, bytes32 value) external {
        beforeRandomizerCallback(id, value);
    }

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