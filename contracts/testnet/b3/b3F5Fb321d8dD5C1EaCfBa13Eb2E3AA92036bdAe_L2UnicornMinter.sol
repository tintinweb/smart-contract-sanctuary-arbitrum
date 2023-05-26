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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
pragma solidity ^0.8.9;

import {IRandomizer} from "../interfaces/IRandomizer.sol";

import {BaseRandomizer} from "./BaseRandomizer.sol";

abstract contract BaseGame is BaseRandomizer {

    struct GameInfo {
        address user;
        uint256 playCount;
        bytes32 seed;
        bytes32 params;
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

    function afterPlay(address user_, uint256 playCount_, uint256 callbackGasLimit_, bytes32 params) internal {
        require(playCount_ > 0, "BaseGame: play count greater than 0");
        uint256 requestId_ = IRandomizer(randomizer()).request(callbackGasLimit_);
        _requestIdGameInfo[requestId_] = GameInfo(user_, playCount_, "", params);
        _userRequestIds[user_][_userRequestCount[user_]] = requestId_;
        _userRequestCount[user_] += 1;
        emit Play(user_, requestId_);
    }

    function beforeRandomizerCallback(uint256 requestId_, bytes32 seed_) internal returns (address, uint256, bytes32) {
        require(msg.sender == randomizer(), "BaseGame: only the randomizer contract can call this function");
        GameInfo storage gameInfo_ = _requestIdGameInfo[requestId_];
        gameInfo_.seed = seed_;
        emit PlayResult(gameInfo_.user, requestId_, seed_);
        return (gameInfo_.user, gameInfo_.playCount, gameInfo_.params);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IRandomizer} from "../interfaces/IRandomizer.sol";

abstract contract BaseRandomizer is Ownable {

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

    function withdrawFund(uint256 amount_) public onlyOwner {
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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

import {IL2Unicorn} from "../interfaces/IL2Unicorn.sol";
import {IL2UnicornRule} from "../interfaces/IL2UnicornRule.sol";

import {BaseGame} from "../abstract/BaseGame.sol";

import {L2UnicornPeriphery} from "../libraries/L2UnicornPeriphery.sol";

contract L2UnicornMinter is BaseGame {

    uint256 public hatchLimit;

    address public l2Unicorn;

    address public l2UnicornRule;

    address public l2;

    address public recipient;

    mapping(uint256 => uint256) private _costAmount;

    mapping(uint256 => uint256) private _levelTokenId;

    constructor(address randomizer_, address l2Unicorn_, address l2UnicornRule_, address l2_, address recipient_) BaseGame(randomizer_) {
        hatchLimit = 80;
        l2Unicorn = l2Unicorn_;
        l2UnicornRule = l2UnicornRule_;
        l2 = l2_;
        recipient = recipient_;
        _costAmount[L2UnicornPeriphery.E_SERIES_0] = 100e18;
        _costAmount[L2UnicornPeriphery.E_SERIES_1] = 1000e18;
    }

    function hatch(uint256 gasPrice_, uint256 hatchCount_, uint256 callbackGasLimit_, uint256 eSeries_) payable external {
        require(hatchCount_ <= 80, "L2UnicornMinter: hatch count invalid");
        require(eSeries_ == L2UnicornPeriphery.E_SERIES_0 || eSeries_ == L2UnicornPeriphery.E_SERIES_1, "L2UnicornMinter: e series invalid");
        require(IL2Unicorn(l2Unicorn).minter() == address(this), "L2UnicornMinter: L2Unicorn not call");
        require(!Pausable(l2Unicorn).paused(), "L2UnicornMinter: L2Unicorn already paused");
        require(_costAmount[eSeries_] > 0 && IERC20(l2).transferFrom(_msgSender(), recipient, hatchCount_ * _costAmount[eSeries_]), "L2UnicornMinter: L2 transfer failure");
        //
        uint256 randomizerFee_ = estimateFeeUsingConfirmationsAndGasPrice(callbackGasLimit_, 2, gasPrice_);
        require(msg.value >= randomizerFee_, "L2UnicornMinter: randomizer fee insufficient");
        depositFund();
        //
        afterPlay(_msgSender(), hatchCount_, callbackGasLimit_, bytes32(eSeries_));
    }

    function randomizerCallback(uint256 requestId_, bytes32 seed_) external {
        (address user_, uint256 hatchCount_, bytes32 params_) = beforeRandomizerCallback(requestId_, seed_);
        //
        for (uint index_ = 0; index_ < hatchCount_;) {
            bytes32 newSeed_ = keccak256(abi.encodePacked(seed_, bytes32(index_)));
            uint256 number = uint256(newSeed_) % L2UnicornPeriphery.R_SERIAL_MOD_NUMBER;
            IL2Unicorn(l2Unicorn).mintWithMinter(user_, _getTokenIdByRandomNum(number, params_));
            unchecked{++index_;}
        }
    }

    function setCostAmount(uint256 eSeries_, uint256 costAmount_) external onlyOwner {
        require(eSeries_ == L2UnicornPeriphery.E_SERIES_0 || eSeries_ == L2UnicornPeriphery.E_SERIES_1, "L2UnicornMinter: e series invalid");
        _costAmount[eSeries_] = costAmount_;
    }

    function getCostAmount(uint256 eSeries_) view external returns (uint256){
        return _costAmount[eSeries_];
    }

    function setHatchLimit(uint256 hatchLimit_) external onlyOwner {
        hatchLimit = hatchLimit_;
    }

    function setL2Unicorn(address l2Unicorn_) external onlyOwner {
        l2Unicorn = l2Unicorn_;
    }

    function setL2UnicornRule(address l2UnicornRule_) external onlyOwner {
        l2UnicornRule = l2UnicornRule_;
    }

    function setL2(address l2_) external onlyOwner {
        l2 = l2_;
    }

    function setRecipient(address recipient_) external onlyOwner {
        recipient = recipient_;
    }

    function adjustLevelTokenId(uint256[] calldata levelArr_, uint256[] calldata tokenIdArr_) external onlyOwner {
        require(levelArr_.length == tokenIdArr_.length, "L2UnicornMinter: invalid parameter");
        uint256 length = levelArr_.length;
        for (uint i_ = 0; i_ < length;) {
            uint256 level_ = levelArr_[i_];
            uint256 tokenId_ = tokenIdArr_[i_];
            require(level_ >= 0 && level_ <= 9, "L2UnicornMinter: level invalid value");
            require(_levelTokenId[level_] != tokenId_ && tokenId_ > _levelTokenId[level_], "L2UnicornMinter: tokenId invalid value");
            _levelTokenId[level_] = tokenId_;
            unchecked {i_++;}
        }
    }

    function viewLevelTokenId(uint256[] calldata levelArr_) public view returns (uint256[] memory) {
        uint256 length = levelArr_.length;
        uint256[] memory tokenIdArr = new uint256[](length);
        for (uint i_ = 0; i_ < length;) {
            tokenIdArr[i_] = _levelTokenId[levelArr_[i_]];
            unchecked {i_++;}
        }
        return tokenIdArr;
    }

    function _getTokenIdByRandomNum(uint256 randomNum_, bytes32 params_) private returns (uint256) {
        uint256 eSeries = uint256(params_);
        IL2UnicornRule.HatchRule memory hatchRule = IL2UnicornRule(l2UnicornRule).getHatchRuleByRandomNumESeries(randomNum_, eSeries);
        uint256 tokenId;
        if (hatchRule.tokenIdTotalSupply != 0) {
            if (_levelTokenId[hatchRule.level] == 0) {
                _levelTokenId[hatchRule.level] = hatchRule.startTokenId;
            }
            tokenId = _levelTokenId[hatchRule.level];
            if (tokenId <= hatchRule.endTokenId) {
                unchecked {_levelTokenId[hatchRule.level]++;}
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

interface IL2Unicorn {

    function burn(uint256 tokenId) external;

    function minter() external view returns (address);

    function mintWithMinter(address to_, uint256 tokenId_) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IL2UnicornRule {

    struct HatchRule {
        uint256 level;
        uint256 startRandomNumE0;
        uint256 endRandomNumE0;
        uint256 startRandomNumE1;
        uint256 endRandomNumE1;
        uint256 startTokenId;
        uint256 endTokenId;
        uint256 tokenIdTotalSupply;
        uint256 awardAmount;
    }

    struct EvolveRule {
        uint256 level;
        uint256 startRandomNum;
        uint256 endRandomNum;
    }

    function getHatchRuleNone() external pure returns (HatchRule memory);

    function getHatchRuleByLevel(uint256 level_) external pure returns (HatchRule memory);

    function getHatchRuleByRandomNumESeries(uint256 randomNum, uint256 eSeries) external pure returns (HatchRule memory);

    function getHatchRuleByTokenId(uint256 tokenId) external pure returns (HatchRule memory);

    function getHatchRuleByCurrentLevelRandomNum(uint256 currentLevel_, uint256 randomNum_) external pure returns (HatchRule memory);

    function getEvolveRuleByCurrentLevelIndex(uint256 currentLevel_, uint256 index_) external pure returns (EvolveRule memory);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library L2UnicornPeriphery {

    uint8 public constant E_SERIES_0 = 0;

    uint8 public constant E_SERIES_1 = 1;

    uint256 public constant R_SERIAL_MOD_NUMBER = 1000000;

}