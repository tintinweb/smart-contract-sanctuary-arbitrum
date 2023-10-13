// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

import "Ownable.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "ReentrancyGuard.sol";
import "Pausable.sol";
import "Math.sol";
import "IUsers.sol";
import "IUserProfile.sol";
import "Domains.sol";


contract Users is IUsers, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    modifier onlyBy (address _address) {
        require(msg.sender == _address, 'Not authorized');
        _;
    }
    modifier blocksEnabled {
        require(_blocksEnabled, 'Blocks disabled');
        _;
    }
    modifier ratingsEnabled {
        require(_ratingsEnabled, 'Ratings disabled');
        _;
    }

    address public stableCoinContract;
    address public chatsContract;
    address public domainsContract;

    bool _blocksEnabled = true;
    bool _ratingsEnabled = true;

    event UserProfileUpdated(
        string userName,
        string domainName,
        uint fee,
        string[] media
    );
    event UserRegistered(
        string userName,
        string domainName,
        uint registrationDateTime
    );
    event UserDeposit(address indexed _address, uint _amount, uint _balance);
    event UserWithdrawal(address indexed _address, uint _amount, uint _balance);
    event RatingAdded(address indexed from, address indexed to, uint dateTime, uint ratingGiven, uint countRating, uint averageRating);
    event RatingRemoved(address indexed from, address indexed to, uint dateTime);
    event UserBlocked(address indexed from, address indexed to);
    event UserUnblocked(address indexed from, address indexed to);
    event UserStatsUpdate(address indexed _address, uint avgChatDuration, uint cntChats, uint lastChatDateTime);

    mapping (address => User) private users;

    mapping (bytes32 => Rating) public ratings;
    mapping (bytes32 => bool) public blockings;


    function getUserByAddress(address _address) public view returns (User memory, bytes memory) {
        User memory user = users[_address];
        require(bytes(user.userName).length > 0, 'User does not exist');
        bytes memory extraData = user.profileData.getAttributes(_address);
        return (user, extraData);
    }

    function setStableCoinAddress(address _address) external onlyOwner {
        require(_address != address(0), 'Invalid address');
        stableCoinContract = _address;
    }

    function setChatsAddress(address _address) external onlyOwner {
        require(_address != address(0), 'Invalid address');
        chatsContract = _address;
    }

    function setDomainsAddress (address _address) external onlyOwner {
        domainsContract = _address;
    }

    function toggleBlocksEnabled() external onlyOwner returns (bool) {
        _blocksEnabled = !_blocksEnabled;
        return _blocksEnabled;
    }

    function toggleRatingsEnabled() external onlyOwner returns (bool) {
        _ratingsEnabled = !_ratingsEnabled;
        return _ratingsEnabled;
    }

    function registerUser(string memory _userName, string memory _domainName) external whenNotPaused {
        require(bytes(users[msg.sender].userName).length == 0, "User already exists");
        require(bytes(_userName).length >= 2 && bytes(_userName).length <= 32, 'Invalid username');
        Domains domains = Domains(domainsContract);
        address profileContractAddress = domains.getContractAddressByDomain(_domainName);
        IUserProfile profileContract = IUserProfile(profileContractAddress);
        string[] memory media;
        uint regDateTime = block.timestamp;

        users[msg.sender] = User(
            _userName,
            profileContract,
            _domainName,
            0, 0, 0, 0x0, 0, 0, 0, 0, media, regDateTime, 0, 0, 0
        );
        emit UserRegistered(_userName, _domainName, regDateTime);
    }

    function updateProfile(
        string memory _userName, string memory _domainName, uint _fee, string[] memory _media, bytes memory _extraData) external whenNotPaused {
        require(bytes(users[msg.sender].userName).length > 0, "User must exist to update");

        Domains domains = Domains(domainsContract);
        address profileContract = domains.getContractAddressByDomain(_domainName);
        IUserProfile userProfile = IUserProfile(profileContract);

        User storage user = users[msg.sender];
        require(bytes(_userName).length >= 2 && bytes(_userName).length <= 32, 'Invalid username');
        user.userName = _userName;
        user.fee = _fee;
        user.media = _media;

        userProfile.setAttributes(msg.sender, _extraData);

        emit UserProfileUpdated(_userName, _domainName, _fee, _media);
    }

    function updateStats(address _caller, address _callee, uint _chatStartDateTime, uint _chatEndDateTime) onlyBy(chatsContract) external whenNotPaused {
        User storage caller = users[_caller];
        User storage callee = users[_callee];
        caller.lastChatDateTime = _chatEndDateTime;
        callee.lastChatDateTime = _chatEndDateTime;
        caller.avgChatDuration = (caller.avgChatDuration * caller.cntChats + _chatEndDateTime - _chatStartDateTime) / (caller.cntChats + 1);
        callee.avgChatDuration = (callee.avgChatDuration * callee.cntChats + _chatEndDateTime - _chatStartDateTime) / (callee.cntChats + 1);
        caller.cntChats += 1;
        callee.cntChats += 1;
        emit UserStatsUpdate(_caller, caller.avgChatDuration, caller.cntChats, caller.lastChatDateTime);
        emit UserStatsUpdate(_callee, callee.avgChatDuration, callee.cntChats, callee.lastChatDateTime);
    }

    function setChatId(address _caller, address _callee, bytes32 _id) onlyBy(chatsContract) external whenNotPaused {
        users[_caller].currentChatId = _id;
        users[_callee].currentChatId = _id;
    }

    function getFee(address _address) external view returns (uint) {
        return users[_address].fee;
    }

    function deposit(uint _amount) external whenNotPaused nonReentrant {
        IERC20 token = IERC20(stableCoinContract);
        require(token.balanceOf(msg.sender) >= _amount, 'Not enought balance');
        users[msg.sender].depositBalance += _amount;
        emit UserDeposit(msg.sender, _amount, users[msg.sender].depositBalance);
        token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint _amount) external whenNotPaused nonReentrant {
        require(users[msg.sender].depositBalance - users[msg.sender].lockedAmount >= _amount, 'Not enough balance');
        users[msg.sender].depositBalance -= _amount;
        emit UserWithdrawal(msg.sender, _amount, users[msg.sender].depositBalance);
        IERC20 token = IERC20(stableCoinContract);
        token.safeTransfer(msg.sender, _amount);
    }

    function lockDeposit(address _address, uint _amount) onlyBy(chatsContract) external whenNotPaused {
        require(users[_address].depositBalance - users[_address].lockedAmount >= _amount, 'Not enough balance');
        users[_address].lockedAmount += _amount;
    }

    function unlockDeposit(address _address, uint _exclude) onlyBy (chatsContract) external whenNotPaused returns (uint) {
        uint lockedAmount = users[_address].lockedAmount;
        require(users[_address].lockedAmount >= _exclude, 'Not enough balance');
        users[_address].lockedAmount = _exclude;
        return lockedAmount - _exclude;
    }

    function pay(address _address, uint _amount, address _depositor) onlyBy(chatsContract) external whenNotPaused {
        require(users[_depositor].lockedAmount >= _amount, 'Insufficient locked amount');
        users[_depositor].lockedAmount -= _amount;
        users[_depositor].depositBalance -= _amount;
        return IERC20(stableCoinContract).safeTransfer(_address, _amount);
    }

    function callerCanCoverFees(address _caller, address _callee) public view returns (bool) {
        return (users[_caller].depositBalance - users[_caller].lockedAmount >= users[_callee].fee);
    }

    function addRating(address _address, uint _rating) ratingsEnabled external whenNotPaused {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _address));
        require(_rating == 1000 || _rating == 2000 || _rating == 3000 || _rating == 4000 || _rating == 5000, 'Invalid rating');
        require(ratings[hash].rating == 0, 'Duplicate rating');

        ratings[hash] = Rating(_address, _rating, users[msg.sender].lastRating, 0x0);

        if (users[msg.sender].firstRating == 0x0) {
            users[msg.sender].firstRating = hash;
        }
        ratings[users[msg.sender].lastRating].nextRating = hash;
        users[msg.sender].lastRating = hash;

        users[_address].avgRating = (users[_address].avgRating * users[_address].cntRating + _rating) / (users[_address].cntRating + 1);
        users[_address].cntRating++;
        emit RatingAdded(msg.sender, _address, block.timestamp, _rating, users[_address].cntRating, users[_address].avgRating);
    }

    function removeRating(address _address) ratingsEnabled external whenNotPaused {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _address));
        require(ratings[hash].rated != address(0), 'Invalid address');
        uint rating = ratings[hash].rating;

        // Fix linked list elements
        ratings[ratings[hash].nextRating].prevRating = ratings[hash].prevRating;
        ratings[ratings[hash].prevRating].nextRating = ratings[hash].nextRating;
        delete ratings[hash];

        // Fix user's ratings
        users[_address].avgRating = (users[_address].avgRating * users[_address].cntRating - rating) / Math.max(users[_address].cntRating - 1, 1);
        users[_address].cntRating--;

        emit RatingRemoved(msg.sender, _address, block.timestamp);
    }

    function getRatingsGiven(bytes32 _start, uint _length) ratingsEnabled external view returns (Rating[] memory) {
        Rating[] memory ratingsByUser = new Rating[](_length);
        bytes32 nextPage;
        if (_start == 0x0) {
            _start = users[msg.sender].firstRating;
        }
        Rating memory rating = ratings[_start];

        for (uint i = 0; i < _length; i++) {
            ratingsByUser[i] = rating;
            rating = ratings[rating.nextRating];
            nextPage = rating.nextRating;
            if (rating.rated == address(0)) break;
        }
        return ratingsByUser;
    }

    function isBlocked(address _blocker, address _blocked) blocksEnabled external view returns (bool) {
        return blockings[keccak256(abi.encodePacked(_blocker, _blocked))];
    }

    function isBlocked(address _blocker, address[] calldata _blocked) blocksEnabled external view returns (bool[] memory) {
        bool[] memory blockStatus = new bool[](_blocked.length);
        for (uint i = 0; i < _blocked.length; i++) {
            bytes32 hash = keccak256(abi.encodePacked(_blocker, _blocked[i]));
            blockStatus[i] = blockings[hash];
        }
        return blockStatus;
    }

    function blockUser(address _address) blocksEnabled external whenNotPaused returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _address));
        require (blockings[hash] != true, 'Already blocked');
        blockings[hash] = true;
        emit UserBlocked(msg.sender, _address);
        return hash;
    }

    function unblockUser(address _address) blocksEnabled external whenNotPaused returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _address));
        require(blockings[hash], 'Not blocked');
        delete blockings[hash];
        emit UserUnblocked(msg.sender, _address);
        return true;
    }

    function pause() external onlyOwner {
        return _pause();
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "IUserProfile.sol";

interface IUsers {
    struct User {
        string userName;
        IUserProfile profileData;
        string domainName;
        uint fee;
        uint depositBalance;
        uint lockedAmount;
        bytes32 currentChatId;
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
    function addRating(address _address, uint _rating) external;
    function blockUser(address _address) external returns (bytes32);
    function callerCanCoverFees(address _caller, address _callee) external view returns (bool);
    function deposit(uint _amount) external;
    function getFee (address _address) external returns (uint fee);
    function getRatingsGiven(bytes32 _start, uint _length) external view returns (Rating[] memory);
    function getUserByAddress (address _address) external view returns (User memory, bytes memory);
    function isBlocked(address _blocker, address _blocked) external view returns (bool);
    function isBlocked(address _blocker, address[] calldata _blocked) external view returns (bool[] memory);
    function lockDeposit(address _address, uint _amount) external;
    function pay(address _address, uint _amount, address _depositor) external;
    function removeRating(address _address) external;
    function setChatsAddress(address _address) external;
    function setChatId(address _caller, address _callee, bytes32 _id) external;
    function setStableCoinAddress(address _address) external;
    function toggleBlocksEnabled() external returns (bool);
    function toggleRatingsEnabled() external returns (bool);
    function unblockUser(address _address) external returns (bool);
    function unlockDeposit(address _address, uint exclude) external returns (uint);
    function registerUser(string memory _userName, string memory _domainName) external;
    function updateProfile(string memory _userName, string memory _domainName, uint _fee, string[] memory _media, bytes memory _extraData) external;
    function updateStats(address _caller, address _callee, uint _chatStartDateTime, uint _chatEndDateTime) external;
    function withdraw(uint _amount) external;
}

pragma solidity ^0.8.0;

interface IUserProfile {
    function setAttributes(address user, bytes calldata data) external;
    function getAttributes(address user) external view returns (bytes memory);
}

pragma solidity ^0.8.15;

import "Ownable.sol";

// TODO: Check contract not already deployed, domainName unique
// TODO: Write tests that use more than one domain

contract Domains is Ownable {
    mapping (string => address) private domainToProfileContract;

    function registerDomain(string memory _domainName, address _address) public onlyOwner() {
        domainToProfileContract[_domainName] = _address;
    }

    function getContractAddressByDomain(string memory _domainName) public view returns (address) {
        address contractAddress = domainToProfileContract[_domainName];
        require(contractAddress != address(0), "Domain name not registered");
        return contractAddress;
    }
}