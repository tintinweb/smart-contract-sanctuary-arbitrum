// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

    uint8 public maximum;

    struct GameInfo {
        address user;
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

    constructor(address randomizer_, uint8 maximum_) BaseRandomizer(randomizer_) {
        maximum= maximum_;
    }

    // external

    function setMaximum(uint8 maximum_) external onlyOwner {
        maximum = maximum_;
    }

    function viewGameInfo(uint256 requestId_) external view returns (GameInfo memory){
        return _requestIdGameInfo[requestId_];
    }

    function viewGameInfos(address user_, uint256 startIndex_, uint256 endIndex_) external view returns (GameInfo[] memory gameInfos){
        if (startIndex_ >= 0 && endIndex_ >= startIndex_) {
            uint256 len = endIndex_ + 1 - startIndex_;
            uint256 total = _userRequestCount[user_];
            uint256 arrayLen = len > total ? total : len;
            gameInfos = new GameInfo[](arrayLen);
            uint256 arrayIndex_ = 0;
            for (uint256 index_ = startIndex_; index_ < ((endIndex_ > total) ? total : endIndex_);) {
                uint256 requestId_ = _userRequestIds[user_][index_];
                gameInfos[arrayIndex_] = _requestIdGameInfo[requestId_];
                unchecked{++index_; ++arrayIndex_;}
            }
        }
        return gameInfos;
    }

    // internal

    function afterPlay(address user_,  uint256 callbackGasLimit_) internal returns (uint256) {
        uint256 requestId_ = IRandomizer(randomizer()).request(callbackGasLimit_);
        _requestIdGameInfo[requestId_] = GameInfo(user_, "");
        _userRequestIds[user_][_userRequestCount[user_]] = requestId_;
        _userRequestCount[user_] += 1;
        emit Play(user_, requestId_);
        return requestId_;
    }

    function beforeRandomizerCallback(uint256 requestId_, bytes32 seed_) internal returns (address) {
        require(msg.sender == randomizer(), "BaseGame: only the randomizer contract can call this function");
        GameInfo storage gameInfo_ = _requestIdGameInfo[requestId_];
        gameInfo_.seed = seed_;
        emit PlayResult(gameInfo_.user, requestId_, seed_);
        return gameInfo_.user;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseL2 is Ownable{

    address public l2;

    constructor(address l2_) {
        l2 = l2_;
    }

    function setL2(address l2_) external onlyOwner {
        l2 = l2_;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseL2Unicorn is Ownable{

    address public l2Unicorn;

    constructor(address l2Unicorn_) {
        l2Unicorn = l2Unicorn_;
    }

    function setL2Unicorn(address l2Unicorn_) external onlyOwner {
        l2Unicorn = l2Unicorn_;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseL2UnicornRule is Ownable {

    address public l2UnicornRule;

    constructor(address l2UnicornRule_) {
        l2UnicornRule = l2UnicornRule_;
    }

    function setL2UnicornRule(address l2UnicornRule_) external onlyOwner {
        l2UnicornRule = l2UnicornRule_;
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

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseRecipient is Ownable{

    address public recipient;

    constructor(address recipient_) {
        recipient = recipient_;
    }

    function setRecipient(address recipient_) external onlyOwner {
        recipient = recipient_;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {IPausable} from "../interfaces/IPausable.sol";
import {IL2Unicorn} from "../interfaces/IL2Unicorn.sol";
import {IL2UnicornRule} from "../interfaces/IL2UnicornRule.sol";

import {BaseGame} from "../abstract/BaseGame.sol";
import {BaseL2} from "../abstract/BaseL2.sol";
import {BaseL2Unicorn} from "../abstract/BaseL2Unicorn.sol";
import {BaseL2UnicornRule} from "../abstract/BaseL2UnicornRule.sol";
import {BaseRecipient} from "../abstract/BaseRecipient.sol";

/**
 * @notice 孵化
 */
contract L2UnicornHatcher is BaseL2, BaseL2Unicorn, BaseL2UnicornRule, BaseRecipient, BaseGame {

    mapping(uint8 => uint256) private _costAmount;

    mapping(uint256 => uint8) private _requestIdHatchCount;

    mapping(uint256 => uint8) private _requestIdESeries;

    constructor(address randomizer_, address l2Unicorn_, address l2UnicornRule_, address l2_, address recipient_)
        BaseGame(randomizer_, 80)
        BaseL2Unicorn(l2Unicorn_)
        BaseL2UnicornRule(l2UnicornRule_)
        BaseL2(l2_)
        BaseRecipient(recipient_) {
        _costAmount[0] = 100e18;
        _costAmount[1] = 1000e18;
    }

    /**
     * @notice 孵化
     */
    function hatch(uint256 gasPrice_, uint256 callbackGasLimit_, uint8 hatchCount_, uint8 eSeries_) payable external {
        require(hatchCount_ > 0 && hatchCount_ <= maximum, "L2UnicornHatcher: exceed maximum");
        require(eSeries_ == 0 || eSeries_ == 1, "L2UnicornHatcher: e series invalid");
        require(IAccessControl(l2Unicorn).hasRole(0xaeaef46186eb59f884e36929b6d682a6ae35e1e43d8f05f058dcefb92b601461, address(this)), "L2UnicornHatcher: access denied");
        require(!IPausable(l2Unicorn).paused(), "L2UnicornHatcher: contract already paused");
        require(_costAmount[eSeries_] > 0 && IERC20(l2).transferFrom(_msgSender(), recipient, hatchCount_ * _costAmount[eSeries_]), "L2UnicornHatcher: L2 transfer failure");
        //
        uint256 randomizerFee_ = estimateFeeUsingConfirmationsAndGasPrice(callbackGasLimit_, 2, gasPrice_);
        require(msg.value >= randomizerFee_, "L2UnicornHatcher: randomizer fee insufficient");
        depositFund();
        //
        uint256 requestId_ = afterPlay(_msgSender(), callbackGasLimit_);
        _requestIdHatchCount[requestId_] = hatchCount_;
        _requestIdESeries[requestId_] = eSeries_;
    }

    /**
     * @notice 孵化回调
     */
    function randomizerCallback(uint256 requestId_, bytes32 seed_) external {
        //用户
        address user_ = beforeRandomizerCallback(requestId_, seed_);
        //孵化个数
        uint8 hatchCount_ = _requestIdHatchCount[requestId_];
        //孵化系列
        uint8 eSeries_ = _requestIdESeries[requestId_];
        //
        for (uint256 index_ = 0; index_ < hatchCount_;) {
            //根据种子计算随机数
            bytes32 newSeed_ = keccak256(abi.encodePacked(seed_, bytes32(index_)));
            uint256 randomNumber_ = uint256(newSeed_) % IL2UnicornRule(l2UnicornRule).modNumber();
            //根据系列和随机数，取孵化到的TokenId
            IL2UnicornRule.HatchRule memory hatchRule = IL2UnicornRule(l2UnicornRule).getHatchRuleByESeriesRandomNum(eSeries_, randomNumber_);
            //孵化铸造
            IL2Unicorn(l2Unicorn).mintForLevel(user_, hatchRule.level, hatchRule.startTokenId);
            unchecked{++index_;}
        }
    }

    function setCostAmount(uint8 eSeries_, uint256 costAmount_) external onlyOwner {
        require(eSeries_ == 0 || eSeries_ == 1, "L2UnicornHatcher: e series invalid");
        _costAmount[eSeries_] = costAmount_;
    }

    function getCostAmount(uint8 eSeries_) view external returns (uint256){
        return _costAmount[eSeries_];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IL2Unicorn {

    function mintForLevel(address to_, uint8 level_, uint256 levelStartTokenId_) external;

    function batchBurn(uint256[] calldata tokenIdArr) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IL2UnicornRule {

    struct HatchRule {
        uint8 level;
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
        uint8 level;
        uint256 startRandomNum;
        uint256 endRandomNum;
    }

    function modNumber() external view returns (uint256);

    function getHatchRuleNone() external pure returns (HatchRule memory);

    function getHatchRuleByLevel(uint8 level_) external pure returns (HatchRule memory);

    function getHatchRuleByESeriesRandomNum(uint8 eSeries_, uint256 randomNum_) external pure returns (HatchRule memory);

    function getHatchRuleByTokenId(uint256 tokenId) external pure returns (HatchRule memory);

    function getHatchRuleByEvolveTokenIdLevelRandomNum(uint8 evolveTokenIdLevel_, uint256 randomNum_) external pure returns (HatchRule memory);

    function getEvolveRuleByEvolveTokenIdLevelNextLevelIndex(uint8 evolveTokenIdLevel_, uint8 nextLevelIndex_) external pure returns (EvolveRule memory);

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