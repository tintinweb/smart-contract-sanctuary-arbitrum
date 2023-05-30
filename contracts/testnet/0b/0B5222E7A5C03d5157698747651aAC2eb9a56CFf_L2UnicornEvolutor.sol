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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {IPausable} from "../interfaces/IPausable.sol";
import {IL2Unicorn} from "../interfaces/IL2Unicorn.sol";
import {IL2UnicornRule} from "../interfaces/IL2UnicornRule.sol";

import {BaseGame} from "../abstract/BaseGame.sol";
import {BaseL2Unicorn} from "../abstract/BaseL2Unicorn.sol";
import {BaseL2UnicornRule} from "../abstract/BaseL2UnicornRule.sol";
import {BaseRecipient} from "../abstract/BaseRecipient.sol";

/**
 * @notice 进化
 */
contract L2UnicornEvolutor is BaseGame, BaseL2Unicorn, BaseL2UnicornRule, BaseRecipient {

    mapping(uint256 => uint8[]) private _requestIdEvolveTokenIdLevelArr;

    constructor(address randomizer_, address l2Unicorn_, address l2UnicornRule_, address recipient_)
        BaseGame(randomizer_, 80)
        BaseL2Unicorn(l2Unicorn_)
        BaseL2UnicornRule(l2UnicornRule_)
        BaseRecipient(recipient_) {}

    /**
     * @notice 进化
     */
    function evolve(uint256 gasPrice_, uint256 callbackGasLimit_, uint256[] calldata tokenIdArr) payable external {
        //验证
        uint256 length_ = tokenIdArr.length;
        require(length_ <= maximum, "L2UnicornEvolutor: exceed maximum");
        require(IAccessControl(l2Unicorn).hasRole(0xaeaef46186eb59f884e36929b6d682a6ae35e1e43d8f05f058dcefb92b601461, address(this)), "L2UnicornEvolutor: access denied");
        require(!IPausable(l2Unicorn).paused(), "L2UnicornEvolutor: contract already paused");
        //存入随机数手续费
        uint256 randomizerFee_ = estimateFeeUsingConfirmationsAndGasPrice(callbackGasLimit_, 2, gasPrice_);
        require(msg.value >= randomizerFee_, "L2UnicornEvolutor: randomizer fee insufficient");
        depositFund();
        //
        uint256 requestId_ = afterPlay(_msgSender(), callbackGasLimit_);
        for (uint256 i_ = 0; i_ < length_;) {
            uint256 tokenId_ = tokenIdArr[i_];
            //取孵化的级别
            IL2UnicornRule.HatchRule memory hatchRule = IL2UnicornRule(l2UnicornRule).getHatchRuleByTokenId(tokenId_);
            //判断是否可以进化
            require(hatchRule.level >= 2 && hatchRule.level <= 6, "L2UnicornEvolutor: tokenId can't evolve");
            //回收tokenId
            IERC721(l2Unicorn).safeTransferFrom(_msgSender(), recipient, tokenId_);
            //记录进化级别
            _requestIdEvolveTokenIdLevelArr[requestId_].push(hatchRule.level);
            unchecked{++i_;}
        }
    }

    /**
     * @notice 进化回调
     */
    function randomizerCallback(uint256 requestId_, bytes32 seed_) external {
        address user_ = beforeRandomizerCallback(requestId_, seed_);
        //根据种子计算随机数
        uint256 randomNumber_ = uint256(seed_) % IL2UnicornRule(l2UnicornRule).modNumber();
        //进化级别集合
        uint8[] memory evolveTokenIdLevelArr_ = _requestIdEvolveTokenIdLevelArr[requestId_];
        uint256 length_ = evolveTokenIdLevelArr_.length;
        //
        for (uint256 index_ = 0; index_ < length_;) {
            //根据进化TokenId级别和随机数，取进化到的TokenId
            IL2UnicornRule.HatchRule memory hatchRule = IL2UnicornRule(l2UnicornRule).getHatchRuleByEvolveTokenIdLevelRandomNum(evolveTokenIdLevelArr_[index_], randomNumber_);
            //进化铸造
            IL2Unicorn(l2Unicorn).mintForLevel(user_, hatchRule.level, hatchRule.startTokenId);
            unchecked{++index_;}
        }
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