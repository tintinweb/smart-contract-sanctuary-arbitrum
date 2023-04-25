// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

import "Ownable.sol";
import "IERC20.sol";
import "IERC721.sol";
import "IUsers.sol";
import "ReentrancyGuard.sol";


contract Chats is Ownable, ReentrancyGuard {
    address public usersContract;
    address public treasuryAddress;
    address public nftAddress;
    uint8 public treasuryPct = 0;
    enum Statuses {
        pending,
        started,
        finished
    }
    struct Chat {
        bytes32 id;  // TODO: Redundant field?
        address caller;
        address callee;
        uint startDateTime;
        uint endDateTime;
        uint fee;
        uint lastFeeTimestamp;
        Statuses status;
    }
    event ChatInit(bytes32 indexed id, address indexed caller, address indexed callee, uint fee, address sender);
    event ChatConfirmed(bytes32 indexed id, address indexed caller, address indexed callee, uint dateTime, address sender);
    event ChatRejected(bytes32 indexed id, address indexed caller, address indexed callee, uint dateTime, address sender);
    event ChatCanceled(bytes32 indexed id, address indexed caller, address indexed callee, uint dateTime, address sender);
    event ChatFinished(bytes32 indexed id, address indexed caller, address indexed callee, uint dateTime, uint feeClaimed, uint treasuryShare, address sender);
    event ChatExtended(bytes32 indexed id, address indexed caller, address indexed callee, uint dateTime, address sender);
    mapping (bytes32 => Chat) private chatsMapping;  // Emulating many-to-many relationship between users with a surrogate PK

    function setUsersContractAddress (address _address) external onlyOwner {
        require(_address != address(0), 'Invalid address');
        usersContract = _address;
    }

    function setTreasuryAddress(address _address) external onlyOwner {
        require(_address != address(0), 'Invalid address');
        treasuryAddress = _address;
    }

    function setTreasuryPct(uint8 _pct) external onlyOwner {
        treasuryPct = _pct;
    }

    function getChatByID(bytes32 _id) public view returns (Chat memory) {
        return chatsMapping[_id];
    }

    function getChatByUser(address _address) external view returns (Chat memory) {
        IUsers users = IUsers(usersContract);
        bytes32 chatId = users.getUserByAddress(_address).currentChatId;
        return chatsMapping[chatId];
    }

    function setNftAddress(address _address) external onlyOwner {
        require(_address != address(0), 'Invalid address');
        nftAddress = _address;
    }

    function _startChat(address _callee) private returns (bytes32) {
        IUsers users = IUsers(usersContract);
        IERC721 nft = IERC721(nftAddress);

        bytes32 callerCurrentChatId = users.getUserByAddress(msg.sender).currentChatId;
        require(msg.sender != _callee, 'Caller and callee are the same');
        require(
            callerCurrentChatId == '' ||
            (
                callerCurrentChatId != '' &&
                chatsMapping[callerCurrentChatId].callee == msg.sender &&
                chatsMapping[callerCurrentChatId].status == Statuses.pending
            ), 'Caller is already on a call');

        bytes32 calleeCurrentChatId = users.getUserByAddress(_callee).currentChatId;
        require (
            calleeCurrentChatId == '' ||
            (
                calleeCurrentChatId != '' &&
                chatsMapping[calleeCurrentChatId].callee == _callee &&
                chatsMapping[calleeCurrentChatId].status == Statuses.pending
            ), 'Callee is already on a call');
        require(users.callerCanCoverFees(msg.sender, _callee), 'Caller funds not sufficient');
        require(users.isBlocked(_callee, msg.sender) != true, 'Callee blocked by caller');
        require(nft.balanceOf(msg.sender) > 0 && nft.balanceOf(_callee) > 0, 'NFTs for both users required');
        require(users.callerCanCoverFees(msg.sender, _callee), 'Caller funds not sufficient');

        uint fee = users.getFee(_callee);
        Chat memory chat = Chat(
            keccak256(abi.encodePacked(msg.sender, _callee, block.timestamp)),
            msg.sender,
            _callee,
            0,
            0,
            fee,
            0,
            Statuses.pending
        );
        chatsMapping[chat.id] = chat;
        users.setChatId(msg.sender, _callee, chat.id);
        users.lockDeposit(msg.sender, chat.fee);
        emit ChatInit(chat.id, chat.caller, chat.callee, chat.fee, msg.sender);
        return chat.id;
    }

    function startChat(address _callee) external nonReentrant returns (bytes32) {
        return _startChat(_callee);
    }

    function confirmChat(bytes32 _id) external nonReentrant {
        Chat storage chat = chatsMapping[_id];
        require(chat.status == Statuses.pending, 'Chat status is not "pending"');
        require(msg.sender == chat.callee, 'You cannot confirm the chat');
        chat.status = Statuses.started;
        chat.startDateTime = block.timestamp;
        emit ChatConfirmed(chat.id, chat.caller, chat.callee, chat.startDateTime, msg.sender);
    }

    function _cancelChat(bytes32 _id) private {
        IUsers users = IUsers(usersContract);
        Chat storage chat = chatsMapping[_id];

        require(chat.status == Statuses.pending, 'Chat status is not "pending"');
        require(msg.sender == chat.caller, 'You cannot cancel the chat');

        users.setChatId(chat.caller, chat.callee, '');
        users.unlockDeposit(chat.caller, 0);
        delete chatsMapping[_id];
        emit ChatCanceled(chat.id, chat.caller, chat.callee, block.timestamp, msg.sender);
    }

    function cancelChat(bytes32 _id) external nonReentrant {
        _cancelChat(_id);
    }

    function cancelCurrentStartNewChat(bytes32 _chatId, address _callee) external nonReentrant returns (bytes32) {
        IUsers users = IUsers(usersContract);
        bytes32 currentChatId = users.getUserByAddress(msg.sender).currentChatId;
        Chat memory currentChat = chatsMapping[currentChatId];
        require (currentChatId == _chatId, 'Chat id not current');
        require (currentChat.status == Statuses.pending, 'Current chat status is not pending');
        _cancelChat(_chatId);
        return _startChat(_callee);
    }

    function rejectChat(bytes32 _id) external nonReentrant {
        IUsers users = IUsers(usersContract);
        Chat storage chat = chatsMapping[_id];

        require(chat.status == Statuses.pending, 'Chat status is not "pending"');
        require(msg.sender == chat.callee, 'You cannot confirm the chat');

        users.setChatId(chat.caller, chat.callee, '');
        users.unlockDeposit(chat.caller, 0);
        delete chatsMapping[_id];
        emit ChatRejected(chat.id, chat.caller, chat.callee, block.timestamp, msg.sender);
    }

    function finishChat(bytes32 _id) external nonReentrant {
        Chat storage chat = chatsMapping[_id];
        require(chat.status == Statuses.started, 'Chat status is not "started"');
        require(msg.sender == chat.caller || msg.sender == chat.callee, 'You cannot finish the chat');
        IUsers users = IUsers(usersContract);
        users.setChatId(chat.caller, chat.callee, '');

        uint totalFee = getUnclaimedFee(chat.id);
        uint lockedAmount = users.getUserByAddress(chat.caller).lockedAmount;
        if (totalFee > lockedAmount) {
            totalFee = lockedAmount;
        }
        uint treasuryShare = totalFee * treasuryPct / 100;
        uint feePayable = totalFee - treasuryShare;
        users.pay(chat.callee, feePayable, chat.caller);
        users.pay(treasuryAddress, treasuryShare, chat.caller);
        users.unlockDeposit(chat.caller, 0);

        users.updateStats(chat.caller, chat.callee, chat.startDateTime, block.timestamp);

        emit ChatFinished(chat.id, chat.caller, chat.callee, block.timestamp, feePayable, treasuryShare, msg.sender);
        delete chatsMapping[_id];
    }

    function extendChat(bytes32 _id) external nonReentrant {
        Chat storage chat = chatsMapping[_id];
        require(chat.status == Statuses.started, 'Chat status is not "started"');
        require(msg.sender == chat.caller, 'You cannot extend the chat');
        emit ChatExtended(_id, chat.caller, chat.callee, block.timestamp, msg.sender);
        // TODO: Handle the case in which the user doesn't have enough deposits
        IUsers users = IUsers(usersContract);
        require(users.callerCanCoverFees(msg.sender, chat.callee), 'Caller funds not sufficient');
        users.lockDeposit(msg.sender, chat.fee);
    }

    function getUnclaimedFee(bytes32 _id) public view returns (uint) {
        Chat storage chat = chatsMapping[_id];
        uint start;
        uint end;
        if (chat.endDateTime > 0) {
            end = block.timestamp > chat.endDateTime ? chat.endDateTime : block.timestamp;
        } else {
            end = block.timestamp;
        }
        start = chat.lastFeeTimestamp > 0 ? chat.lastFeeTimestamp : chat.startDateTime;
        return chat.fee * (end - start) / 3600;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


interface IUsers {
    enum Genders {
        unknown,
        male,
        female
    }
    enum Statuses {
        notRegistered,
        available,
        notAvailable
    }
    enum AreasOfInterest {
        Crypto,
        Dating,
        NSFW,
        Sports,
        Movies,
        Anime
    }
    enum Zodiac {
        unknown,
        Aries,
        Taurus,
        Gemini,
        Cancer,
        Leo,
        Virgo,
        Libra,
        Scorpio,
        Sagittarius,
        Capricorn,
        Aquarius,
        Pisces
    }
    struct User {
        string userName;
        uint birthYear;
        Genders gender;
        Statuses status;
        uint fee;
        uint depositBalance;
        uint lockedAmount;
        bytes32 currentChatId;
        AreasOfInterest[] interests;
        string bio;
        uint latitude;
        uint longitude;
        Zodiac sign;
        uint avgRating;
        uint cntRating;
        bytes32 firstRating;
        bytes32 lastRating;
        string[] media;
        uint registrationDateTime;
        uint avgChatDuration;
        uint cntChats;
        uint lastChatDateTime;
    }
    struct Rating {
        address rated;
        uint rating;
        bytes32 prevRating;
        bytes32 nextRating;
    }
    function getFee (address _address) external returns (uint fee);
    function getUserByAddress (address _address) external view returns (User memory);
    function setChatId(address _caller, address _callee, bytes32 _id) external;
    function lockDeposit(address _address, uint _amount) external;
    function unlockDeposit(address _address, uint exclude) external returns (uint);
    function pay(address _address, uint _amount, address _depositor) external;
    function callerCanCoverFees(address _caller, address _callee) external view returns (bool);
    function isBlocked(address _blocker, address _blocked) external view returns (bool);
    function isBlocked(address _blocker, address[] calldata _blocked) external view returns (bool[] memory);
    function updateMedia(string[] memory _mediaArray) external;
    function addRating(address _address, uint _rating) external;
    function removeRating(address _address) external;
    function getRatingsGiven(bytes32 _start, uint _length) external view returns (Rating[] memory);
    function updateStats(address _caller, address _callee, uint _chatStartDateTime, uint _chatEndDateTime) external;
    function toggleBlocksEnabled() external returns (bool);
    function toggleRatingsEnabled() external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}