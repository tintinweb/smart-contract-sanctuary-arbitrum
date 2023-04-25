// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

import "Address.sol";
import "Ownable.sol";
import "AccessControl.sol";
import "Interfaces.sol";

/**
 * @author Heisenberg
 * @title Tournament Manager
 * @notice The contract which manages the Tournaments
 */
// ITournamentLeaderboard,
contract TournamentLeaderboard is Ownable, AccessControl {
    mapping(uint256 => ITournamentLeaderboard.TournamentLeaderBoard)
        public leaderboard;

    mapping(bytes32 => ITournamentLeaderboard.Rank) public tournmanetRanks;
    mapping(address => mapping(uint256 => bytes32)) public userTournamentRank;
    mapping(uint256 => mapping(address => uint256))
        public tournamentUserTicketCount;

    bytes32 public constant OPTION_ISSUER = keccak256("OPTION_ISSUER");
    bytes32 public constant TOURNAMENT_MANAGER =
        keccak256("TOURNAMENT_MANAGER");
    ITournamentManager public tournamentManager;

    event UpdateUserRank(address user, uint256 tournamentId, bytes32 id);
    event ClaimReward(address user, uint256 tournamentId, uint256 reward);
    event SetTournamentManager(address tournamentManager);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setTournamentManager(
        address _tournamentManager
    ) external onlyOwner {
        tournamentManager = ITournamentManager(_tournamentManager);
        emit SetTournamentManager(_tournamentManager);
    }

    /************************************************
     *  READ FUNCTIONS
     ***********************************************/

    function getMid(
        bytes32 start,
        bytes32 end,
        uint256 tournamentId
    ) public view returns (bytes32) {
        bytes32 slow = start;
        bytes32 fast = start;

        while (fast != end) {
            fast = tournmanetRanks[fast].next;
            if (fast != end) {
                slow = tournmanetRanks[slow].next;
                fast = tournmanetRanks[fast].next;
            }
        }
        return slow;
    }

    function getLeaderboardConfig(
        uint256 tournamentId
    )
        external
        view
        returns (ITournamentLeaderboard.TournamentLeaderBoard memory)
    {
        return leaderboard[tournamentId];
    }

    function getTournamentLeaderboard(
        uint256 tournamentId,
        bytes32 startRankIndex,
        uint256 offset
    ) external view returns (ITournamentLeaderboard.Rank[] memory) {
        bytes32 cursor = startRankIndex == bytes32(0)
            ? leaderboard[tournamentId].rankFirst
            : startRankIndex;
        ITournamentLeaderboard.Rank[]
            memory _leaderboard = new ITournamentLeaderboard.Rank[](offset);
        uint256 index;
        while (cursor != bytes32(0) && index < offset) {
            _leaderboard[index] = tournmanetRanks[cursor];
            cursor = tournmanetRanks[cursor].next;
            index++;
        }
        return _leaderboard;
    }

    function getSortedPreviousRankIndex(
        address user,
        uint256 tournamentId,
        int256 newUserScore
    ) public view returns (bytes32 previousIndex) {
        ITournamentLeaderboard.TournamentLeaderBoard
            storage tournament = leaderboard[tournamentId];

        if (
            (tournament.rankFirst == 0) ||
            tournmanetRanks[tournament.rankFirst].score <= newUserScore
        ) {
            return 0;
        } else if (tournmanetRanks[tournament.rankLast].score > newUserScore) {
            return tournament.rankLast;
        } else {
            // Get index from binary search
            bytes32 low = tournament.rankFirst;
            bytes32 high = tournament.rankLast;

            while (tournmanetRanks[low].next != high) {
                bytes32 mid = getMid(low, high, tournamentId);

                // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
                // because Math.average rounds down (it does integer division with truncation).
                if (tournmanetRanks[mid].score < newUserScore) {
                    high = mid;
                } else {
                    low = mid;
                }
            }

            return low;
        }
    }

    function getScore(
        address user,
        uint256 tournamentId
    ) public view returns (int256 score) {
        ITournamentManager.TournamentMeta memory tournament = tournamentManager
            .getTournamentMeta(tournamentId);

        uint256 playTokenMintAmount = (tournament.playTokenMintAmount);
        int256 playTokensBought = int256(
            tournamentUserTicketCount[tournamentId][user] * playTokenMintAmount
        );
        score =
            ((int256(tournamentManager.balanceOf(user, tournamentId)) -
                playTokensBought) * 1e5) /
            playTokensBought;
    }

    function getUserReward(
        address user,
        uint256 tournamentId
    ) public view returns (uint256 reward, bytes32 rankIndex) {
        ITournamentLeaderboard.TournamentLeaderBoard
            memory tournamentLeaderboard = leaderboard[tournamentId];
        rankIndex = tournamentLeaderboard.rankFirst;
        uint256 rewardPool = tournamentManager.tournamentRewardPools(
            tournamentId
        );
        for (
            uint256 rank = 0;
            rank < tournamentLeaderboard.totalWinners;
            rank++
        ) {
            if (tournmanetRanks[rankIndex].user == user) {
                reward =
                    (rewardPool *
                        tournamentLeaderboard.rewardPercentages[rank]) /
                    100e2;
                break;
            } else {
                rankIndex = tournmanetRanks[rankIndex].next;
            }
        }
    }

    function getWinners(
        uint256 tournamentId,
        uint256 totalWinners
    ) external view returns (address[] memory winners) {
        ITournamentLeaderboard.TournamentLeaderBoard
            memory tournamentLeaderboard = leaderboard[tournamentId];
        bytes32 rankIndex = tournamentLeaderboard.rankFirst;
        winners = new address[](totalWinners);
        for (uint256 i = 0; i < totalWinners; i++) {
            winners[i] = tournmanetRanks[rankIndex].user;
            rankIndex = tournmanetRanks[rankIndex].next;
        }
    }

    /************************************************
     *  WRITE FUNCTIONS
     ***********************************************/

    function createTournamentLeaderboard(
        uint256 tournamentId,
        ITournamentLeaderboard.TournamentLeaderBoard calldata _leaderboard
    ) external onlyRole(TOURNAMENT_MANAGER) {
        leaderboard[tournamentId] = _leaderboard;
    }

    function updateUserRank(
        address user,
        uint256 tournamentId
    ) external onlyRole(OPTION_ISSUER) {
        ITournamentLeaderboard.TournamentLeaderBoard
            storage tournament = leaderboard[tournamentId];
        ITournamentManager.TournamentMeta
            memory tournamentMeta = tournamentManager.getTournamentMeta(0);
        require(!tournamentMeta.isClosed, "Tournament is closed");
        int256 score = getScore(user, tournamentId);
        bytes32 id = keccak256(abi.encode(user, tournamentId));
        // Reset the Node
        if (tournmanetRanks[id].exists) {
            if (tournament.rankFirst == id) {
                tournament.rankFirst = tournmanetRanks[id].next;
            } else if (tournament.rankLast == id) {
                tournament.rankLast = tournmanetRanks[id].previous;
                tournmanetRanks[tournmanetRanks[id].previous].next = 0;
            } else {
                tournmanetRanks[tournmanetRanks[id].previous]
                    .next = tournmanetRanks[id].next;
                tournmanetRanks[tournmanetRanks[id].next]
                    .previous = tournmanetRanks[id].previous;
            }
        }
        // Get previous index through binary search
        bytes32 previousIndex = getSortedPreviousRankIndex(
            user,
            tournamentId,
            score
        );
        ITournamentLeaderboard.Rank memory newRank;
        if (previousIndex == 0) {
            if (tournmanetRanks[tournament.rankFirst].exists) {
                tournmanetRanks[tournament.rankFirst].previous = id;
            }
            newRank = ITournamentLeaderboard.Rank(
                tournament.rankFirst,
                0,
                user,
                score,
                false,
                true
            );
            tournament.rankFirst = id;
        } else {
            ITournamentLeaderboard.Rank storage previousRank = tournmanetRanks[
                previousIndex
            ];
            newRank = ITournamentLeaderboard.Rank(
                previousRank.next,
                previousIndex,
                user,
                score,
                false,
                true
            );
            tournmanetRanks[previousRank.next].previous = id;
            previousRank.next = id;
        }
        if (previousIndex == tournament.rankLast) {
            tournament.rankLast = id;
        }
        tournmanetRanks[id] = newRank;
        userTournamentRank[user][tournamentId] = id;
        emit UpdateUserRank(user, tournamentId, id);
    }

    function claimReward(uint256 tournamentId) external {
        ITournamentManager.TournamentMeta memory tournament = tournamentManager
            .getTournamentMeta(tournamentId);
        require(msg.sender != address(0), "Invalid address");
        require(
            tournament.isClosed,
            "Can't claim rewards before tournament ends"
        );
        address user = msg.sender;
        (uint256 reward, bytes32 rankIndex) = getUserReward(user, tournamentId);
        require(!tournmanetRanks[rankIndex].hasClaimed, "Already claimed");
        if (reward > 0) {
            IERC20 rewardToken = tournament.rewardToken;

            require(
                rewardToken.balanceOf(address(this)) >= reward,
                "Insufficient balance to distribute rewards"
            );

            tournmanetRanks[rankIndex].hasClaimed = true;
            rewardToken.transfer(user, reward);

            emit ClaimReward(user, tournamentId, reward);
        }
    }

    function updateLeaderboard(
        uint256 tournamentId,
        uint256 rake,
        address user
    ) external onlyRole(TOURNAMENT_MANAGER) {
        if (tournamentUserTicketCount[tournamentId][user] == 0) {
            leaderboard[tournamentId].userCount++;
        }
        tournamentUserTicketCount[tournamentId][user]++;

        leaderboard[tournamentId].totalBuyins++;
        leaderboard[tournamentId].rakeCollected += rake;
    }

    function emergencyWithdraw(uint256 tournamentId) public onlyOwner {
        ITournamentManager.TournamentMeta memory tournament = tournamentManager
            .getTournamentMeta(tournamentId);
        require(tournament.isClosed, "Tournament is not closed");
        IERC20 rewardToken = tournament.rewardToken;
        uint256 rewardPool = tournamentManager.tournamentRewardPools(
            tournamentId
        );
        rewardToken.transfer(msg.sender, rewardPool);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
import "IERC20.sol";

interface IBufferRouter {
    struct QueuedTrade {
        uint256 queueId;
        uint256 userQueueIndex;
        address user;
        uint256 totalFee;
        uint256 period;
        bool isAbove;
        address targetContract;
        uint256 expectedStrike;
        uint256 slippage;
        uint256 queuedTime;
        bool isQueued;
        uint256 traderNFTId;
        uint256 tournamentId;
    }
    struct Trade {
        uint256 queueId;
        uint256 price;
    }
    struct OpenTradeParams {
        uint256 queueId;
        uint256 timestamp;
        uint256 price;
        bytes signature;
    }
    struct CloseTradeParams {
        uint256 optionId;
        address targetContract;
        uint256 expiryTimestamp;
        uint256 priceAtExpiry;
        bytes signature;
    }
    event OpenTrade(
        address indexed account,
        uint256 queueId,
        uint256 tournamentId,
        uint256 optionId
    );
    event CancelTrade(
        address indexed account,
        uint256 queueId,
        uint256 tournamentId,
        string reason
    );
    event FailUnlock(uint256 optionId, string reason);
    event FailResolve(uint256 queueId, string reason);
    event InitiateTrade(
        address indexed account,
        uint256 queueId,
        uint256 tournamentId,
        uint256 queuedTime
    );
    event RegisterContract(address indexed targetContract, bool isRegistered);
}

interface IBufferBinaryOptions {
    event Create(
        address indexed account,
        uint256 indexed id,
        uint256 indexed tournamentId,
        uint256 settlementFee,
        uint256 totalFee
    );

    event Exercise(
        address indexed account,
        uint256 indexed id,
        uint256 indexed tournamentId,
        uint256 profit,
        uint256 priceAtExpiration
    );
    event Expire(
        uint256 indexed id,
        uint256 indexed tournamentId,
        uint256 loss,
        uint256 priceAtExpiration
    );
    event Pause(bool isPaused);
    event CreateContract(
        address indexed targetContract,
        address config,
        string assetPair
    );

    function createFromRouter(
        OptionParams calldata optionParams,
        uint256 queuedTime
    ) external returns (uint256 optionID);

    function getAmount(
        OptionParams calldata optionParams
    ) external returns (uint256 amount);

    function runInitialChecks(
        uint256 slippage,
        uint256 period,
        uint256 totalFee
    ) external view;

    function isStrikeValid(
        uint256 slippage,
        uint256 strike,
        uint256 expectedStrike
    ) external view returns (bool);

    function config() external view returns (IOptionsConfig);

    function assetPair() external view returns (string calldata);

    function fees(
        uint256 amount,
        address user,
        bool isAbove,
        uint256 traderNFTId
    )
        external
        view
        returns (uint256 total, uint256 settlementFee, uint256 premium);

    enum State {
        Inactive,
        Active,
        Exercised,
        Expired
    }

    enum AssetCategory {
        Forex,
        Crypto,
        Commodities
    }
    struct OptionExpiryData {
        uint256 optionId;
        uint256 priceAtExpiration;
    }

    struct Option {
        State state;
        uint256 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 premium;
        uint256 expiration;
        bool isAbove;
        uint256 totalFee;
        uint256 createdAt;
    }
    struct OptionParams {
        uint256 strike;
        uint256 amount;
        uint256 period;
        bool isAbove;
        uint256 totalFee;
        address user;
        uint256 traderNFTId;
        uint256 tournamentId;
    }

    function options(
        uint256 optionId
    )
        external
        view
        returns (
            State state,
            uint256 strike,
            uint256 amount,
            uint256 lockedAmount,
            uint256 premium,
            uint256 expiration,
            bool isAbove,
            uint256 totalFee,
            uint256 createdAt
        );

    function unlock(uint256 optionID, uint256 priceAtExpiration) external;
}

interface IOptionsConfig {
    struct Window {
        uint8 startHour;
        uint8 startMinute;
        uint8 endHour;
        uint8 endMinute;
    }

    event UpdateMarketTime();
    event UpdateMaxPeriod(uint32 value);
    event UpdateMinPeriod(uint32 value);

    event UpdateSettlementFeeDisbursalContract(address value);
    event UpdatetraderNFTContract(address value);
    event UpdateAssetUtilizationLimit(uint16 value);
    event UpdateMinFee(uint256 value);
    event UpdateMaxFee(uint256 value);

    function traderNFTContract() external view returns (address);

    function settlementFeeDisbursalContract() external view returns (address);

    function marketTimes(
        uint8
    ) external view returns (uint8, uint8, uint8, uint8);

    function maxPeriod() external view returns (uint32);

    function minPeriod() external view returns (uint32);

    function minFee() external view returns (uint256);

    function maxFee() external view returns (uint256);
}

interface ITraderNFT {
    function tokenOwner(uint256 id) external view returns (address user);

    function tokenTierMappings(uint256 id) external view returns (uint8 tier);

    event UpdateTiers(uint256[] tokenIds, uint8[] tiers, uint256[] batchIds);
}

interface IFakeTraderNFT {
    function tokenOwner(uint256 id) external view returns (address user);

    function tokenTierMappings(uint256 id) external view returns (uint8 tier);

    event UpdateNftBasePrice(uint256 nftBasePrice);
    event UpdateMaxNFTMintLimits(uint256 maxNFTMintLimit);
    event UpdateBaseURI(string baseURI);
    event Claim(address indexed account, uint256 claimTokenId);
    event Mint(address indexed account, uint256 tokenId, uint8 tier);
}

interface IBufferOptionsForReader is IBufferBinaryOptions {
    function baseSettlementFeePercentageForAbove()
        external
        view
        returns (uint16);

    function baseSettlementFeePercentageForBelow()
        external
        view
        returns (uint16);

    function stepSize() external view returns (uint16);

    function _getSettlementFeeDiscount(
        address user,
        uint256 traderNFTId
    ) external view returns (uint8 maxStep);
}

interface ITournamentManager {
    enum TournamentType {
        Type1,
        Type2,
        Type3
    }

    struct TournamentMeta {
        string name;
        uint256 start;
        uint256 close;
        uint256 ticketCost;
        uint256 playTokenMintAmount;
        bool isClosed;
        bool isVerified;
        bool tradingStarted;
        bool shouldRefundTickets;
        TournamentType tournamentType;
        IERC20 buyinToken;
        IERC20 rewardToken;
        address creator;
    }
    struct TournamentConditions {
        uint256 maxBuyinsPerWallet;
        uint256 minParticipants;
        uint256 maxParticipants;
        uint256 guaranteedWinningAmount;
        uint256 startPriceMoney;
        uint256 rakePercent;
    }

    struct Tournament {
        TournamentMeta tournamentMeta;
        TournamentConditions tournamentConditions;
    }

    event UpdateUserRank(address user, uint256 tournamentId, bytes32 id);
    event BuyTournamentTokens(
        address user,
        uint256 tournamentId,
        uint256 playTokens
    );
    event ClaimReward(address user, uint256 tournamentId, uint256 reward);
    event CreateTournament(uint256 tournamentId, string name);
    event AddUnderlyingAsset(string[] assets);
    event VerifyTournament(uint256 tournamentId);
    event CloseTournament(uint256 tournamentId, string reason);
    event StartTournament(uint256 tournamentId);
    event EndTournament(uint256 tournamentId);

    function bulkFetchTournaments(
        uint256[] memory tournamentIds
    ) external view returns (Tournament[] memory bulkTournaments);

    function mint(
        address user,
        uint256 tournamentId,
        uint256 tokensToMint
    ) external;

    function burn(
        address user,
        uint256 tournamentId,
        uint256 tokensToBurn
    ) external;

    function decimals() external view returns (uint8);

    function balanceOf(
        address user,
        uint256 tournamentId
    ) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function isTradingAllowed(
        string memory symbol,
        uint256 tournamentId,
        uint256 expiration
    ) external view;

    function getTournamentMeta(
        uint256 tournamentId
    ) external view returns (TournamentMeta memory);

    function tournamentRewardPools(
        uint256 tournamentId
    ) external view returns (uint256);

    function leaderboard() external view returns (ITournamentLeaderboard);
}

interface ITournamentLeaderboard {
    struct TournamentLeaderBoard {
        bytes32 rankFirst;
        bytes32 rankLast;
        uint256 userCount;
        uint256 totalBuyins;
        uint256 rakeCollected;
        uint256 totalWinners;
        uint256[] rewardPercentages;
    }
    struct Rank {
        bytes32 next;
        bytes32 previous;
        address user;
        int256 score;
        bool hasClaimed;
        bool exists;
    }

    function updateLeaderboard(
        uint256 tournamentId,
        uint256 rake,
        address user
    ) external;

    function tournamentUsers(
        uint256 tournamentId
    ) external view returns (address[] memory);

    function tournamentUserTicketCount(
        uint256 tournamentId,
        address user
    ) external view returns (uint256 ticketCount);

    function getLeaderboardConfig(
        uint256 tournamentId
    ) external view returns (TournamentLeaderBoard memory);

    function getMid(
        bytes32 start,
        bytes32 end,
        uint256 tournamentId
    ) external view returns (bytes32);

    function getSortedPreviousRankIndex(
        address user,
        uint256 tournamentId,
        uint256 newUserScore
    ) external view returns (bytes32 previousIndex);

    function getScore(
        address user,
        uint256 tournamentId
    ) external view returns (uint256 score);

    function getUserReward(
        address user,
        uint256 tournamentId
    ) external view returns (uint256 reward);

    function getWinners(
        uint256 tournamentId,
        uint256 totalWinners
    ) external view returns (address[] memory winners);

    function updateUserRank(address user, uint256 tournamentId) external;

    function createTournamentLeaderboard(
        uint256 tournamentId,
        ITournamentLeaderboard.TournamentLeaderBoard calldata _leaderboard
    ) external;

    function getTournamentUsers(
        uint256 tournamentId
    ) external view returns (address[] memory);
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