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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// Abstract contract that implements access check functions
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../../interfaces/admin/IEntity.sol";
import "../../interfaces/access/IDAOAuthority.sol";

abstract contract DAOAccessControlled is Context {

    /* ========== EVENTS ========== */

    event AuthorityUpdated(IDAOAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IDAOAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IDAOAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAuthority() {
        require(address(authority) == _msgSender(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyGovernor() {
        require(authority.governor() == _msgSender(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(authority.policy() == _msgSender(), UNAUTHORIZED);
        _;
    }

    modifier onlyAdmin() {
        require(authority.admin() == _msgSender(), UNAUTHORIZED);
        _;
    }

    modifier onlyEntityAdmin(address _entity) {
        require(IEntity(_entity).getEntityAdminDetails(_msgSender()).isActive, UNAUTHORIZED);
        _;
    }

    modifier onlyBartender(address _entity) {
        require(IEntity(_entity).getBartenderDetails(_msgSender()).isActive, UNAUTHORIZED);
        _;
    }
         
    /* ========== GOV ONLY ========== */
    
    function setAuthority(IDAOAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    /* ========= ERC2771 ============ */
    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == authority.forwarder();
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    modifier onlyForwarder() {
        // this modifier must check msg.sender directly (not through _msgSender()!)
        require(isTrustedForwarder(msg.sender), UNAUTHORIZED);
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Constants {
    uint16 internal constant MIN_NAME_LENGTH = 3;
    uint16 internal constant MAX_NAME_LENGTH = 35;
    uint16 internal constant MAX_STATUS_LENGTH = 70;
    uint16 internal constant MAX_URI_LENGTH = 6000;
}

// SPDX-License-Identifier: MIT

// Source:
// https://github.com/ensdomains/ens-contracts/blob/master/contracts/ethregistrar/StringUtils.sol

pragma solidity >=0.8.4;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}

/***************************************************************************************************
// This contract defines a User of the DAO eco-system
// The users can be different people who interact with the dao contracts through their
// respective end-user applications(Eg: A patron, bar-tender, bar-admin, etc.)
// Once the user registers on the app, it should create a profile for the user on the blockchain
// using this contract
***************************************************************************************************/
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../../interfaces/user/IUser.sol";
import "../access/DAOAccessControlled.sol";
import "../libraries/StringUtils.sol";
import "../libraries/Constants.sol";

contract User is IUser, DAOAccessControlled {
    using Counters for Counters.Counter;

    // An incremental unique Id that identifies a user
    Counters.Counter private _userIds;

    // A list of all registered users
    address[] public allUsers;

    // Protocol-wide banlist
    mapping(address => bool) public bannedUsers;

    // User wallet address => User Attributes
    // This maps unique user Ids to users details
    mapping(address => UserAttributes) public userAttributes;

    // Mapping contains all users followed by a particular one
    mapping(address => mapping(address => bool)) public following;

    // Mapping contains all users which are following a particular one
    mapping(address => mapping(address => bool)) public followers;

    constructor(address _authority) DAOAccessControlled(IDAOAuthority(_authority)) {
        _userIds.increment(); // Start from 1 as id == 0 is a check for existence
    }

    /**
     * @notice              Registers the caller as a new user. Only application calls must be accepted.
     * @param   _name       User name
     * @param   _avatarURI  User avatar URI
     * @return  _           User ID
     */
    function register(string memory _name, string memory _avatarURI) external onlyForwarder returns (uint256) {
        return _createUser(_name, _avatarURI, _msgSender());
    }

    // Allows a user to set their display name
    function changeName(string memory _name) external {
        require(userAttributes[_msgSender()].id != 0, "NON EXISTENT");
        uint256 len = StringUtils.strlen(_name);
        require(len >= Constants.MIN_NAME_LENGTH && len <= Constants.MAX_NAME_LENGTH, "Name length out of range");
        
        userAttributes[_msgSender()].name = _name;
        emit NameChanged(_msgSender(), _name);
    }

    // Allows a user to set their avatar
    function changeAvatar(string memory _avatarURI) external {
        require(userAttributes[_msgSender()].id != 0, "NON EXISTENT");
        require(StringUtils.strlen(_avatarURI) <= Constants.MAX_URI_LENGTH, "URI too long");
        
        userAttributes[_msgSender()].avatarURI = _avatarURI;
        emit AvatarChanged(_msgSender(), _avatarURI);
    }

    // Allows a user to set their text status
    function setStatus(string memory _status) external {
        require(userAttributes[_msgSender()].id != 0, "NON EXISTENT");
        require(StringUtils.strlen(_status) <= Constants.MAX_STATUS_LENGTH, "Status message too long");

        userAttributes[_msgSender()].status = _status;
        emit StatusSet(_msgSender(), _status);
    }

    /**
     * @notice          Puts a user on ban list
     * @param   _user   A user to ban
     */
    function ban(address _user) external onlyPolicy {
        require(!bannedUsers[_user], "Already banned");
   
        bannedUsers[_user] = true;
        emit Banned(_user);
    }

    /**
     * @notice          Lifts user ban
     * @param   _user   A user to lift the ban
     */
    function liftBan(address _user) external onlyPolicy {
        require(bannedUsers[_user], "Not banned");
        
        bannedUsers[_user] = false;        
        emit BanLifted(_user);
    }

    /**
     * @notice                  Adds a user to a list of followed by the caller
     * @param   _userToFollow   A user to follow
     */
    function follow(address _userToFollow) external {
        require(userAttributes[_msgSender()].id != 0 && userAttributes[_userToFollow].id != 0, "NON EXISTENT");
        require(!bannedUsers[_msgSender()], "Banned user");
        require(_msgSender() != _userToFollow, "Cannot follow yourself");
        require(!following[_msgSender()][_userToFollow], "Already following");

        following[_msgSender()][_userToFollow] = true;
        followers[_userToFollow][_msgSender()] = true;
        emit Followed(_msgSender(), _userToFollow);
    }

    /**
     * @notice                  Removes a user from a list of followed by the caller
     * @param   _followedUser   A user to unfollow
     */
    function unfollow(address _followedUser) external {
        require(userAttributes[_msgSender()].id != 0 && userAttributes[_followedUser].id != 0, "NON EXISTENT");
        require(!bannedUsers[_msgSender()], "Banned user");
        require(_msgSender() != _followedUser, "Cannot unfollow yourself");
        require(following[_msgSender()][_followedUser], "Not following user");

        following[_msgSender()][_followedUser] = false;
        followers[_followedUser][_msgSender()] = false;
        emit Unfollowed(_msgSender(), _followedUser);
    }

    /**
     * @notice          Returns a list of followers for the specified user
     * @param   _user   A target user
     */
    function getFollowers(address _user) external view returns(UserAttributes[] memory _followers) {
        require(userAttributes[_user].id != 0, "NON EXISTENT");

        uint256 count;
        for (uint256 i = 0; i < allUsers.length; i++) {
            if (!bannedUsers[allUsers[i]] && followers[_user][allUsers[i]]) {
                count++;
            }
        }

        _followers = new UserAttributes[](count);
        uint256 idx;
        for (uint256 i = 0; i < allUsers.length; i++) {
            if (!bannedUsers[allUsers[i]] && followers[_user][allUsers[i]]) {
                _followers[idx] = userAttributes[allUsers[i]];
                idx++;
            }
        }
    }

    /**
     * @notice          Returns a list of users the specified user follows
     * @param   _user   A target user
     */
    function getFollowing(address _user) external view returns(UserAttributes[] memory _following) {
        require(userAttributes[_user].id != 0, "NON EXISTENT");

        uint256 count;
        for (uint256 i = 0; i < allUsers.length; i++) {
            if (!bannedUsers[allUsers[i]] && following[_user][allUsers[i]]) {
                count++;
            }
        }

        _following = new UserAttributes[](count);
        uint256 idx;
        for (uint256 i = 0; i < allUsers.length; i++) {
            if (!bannedUsers[allUsers[i]] && following[_user][allUsers[i]]) {
                _following[idx] = userAttributes[allUsers[i]];
                idx++;
            }
        }
    }

    function getAllUsers(bool _includeBanned) external view returns(UserAttributes[] memory _users) {
        if (_includeBanned) {
            _users = new UserAttributes[](allUsers.length);
            for (uint256 i = 0; i < allUsers.length; i++) {
                _users[i] = userAttributes[allUsers[i]];
            }
        } else {
            uint count;
            for (uint256 i = 0; i < allUsers.length; i++) {
                if (!bannedUsers[allUsers[i]]) {
                    count++;
                }
            }

            _users = new UserAttributes[](count);
            uint256 idx;
            for (uint256 i = 0; i < allUsers.length; i++) {
                if (!bannedUsers[allUsers[i]] ) {
                    _users[idx] = userAttributes[allUsers[i]];
                    idx++;
                }
            }
        }
    }

    /**
     * @notice      Returns a list of banned users
     */
    function getBannedUsers() external view returns(UserAttributes[] memory _users) {
        uint count;
        for (uint256 i = 0; i < allUsers.length; i++) {
            if (bannedUsers[allUsers[i]]) {
                count++;
            }
        }

        _users = new UserAttributes[](count);
        uint256 idx;
        for (uint256 i = 0; i < allUsers.length; i++) {
            if (bannedUsers[allUsers[i]] ) {
                _users[idx] = userAttributes[allUsers[i]];
                idx++;
            }
        }  
    }

    /****************************************************************************************
    // Creates a user with the given name, avatar and wallet Address
    // Newly created users are added to a list and stored in this contracts storage
    // A mapping maps each user ID to their detais
    // The application can use the list and mapping to get relevant details about the user
    ****************************************************************************************/
    function _createUser(
        string memory _name, 
        string memory _avatarURI,
        address _walletAddress
    ) internal returns (uint256 userId_) {
        require(_walletAddress != address(0), "Wallet address needed");
        require(userAttributes[_walletAddress].id == 0, "User already exists");
        uint256 len = StringUtils.strlen(_name);
        require(len >= Constants.MIN_NAME_LENGTH && len <= Constants.MAX_NAME_LENGTH, "Name length out of range");
        require(StringUtils.strlen(_avatarURI) <= Constants.MAX_URI_LENGTH, "URI too long");

        // Assign a unique ID to the new user to be created
        userId_ = _userIds.current();
        
        // Set details for the user and add them to the mapping
        userAttributes[_walletAddress] = UserAttributes({
            wallet: _walletAddress,
            id: userId_,
            name: _name,
            avatarURI: _avatarURI,
            status: ""
        });

        // Add the new user to list of users
        allUsers.push(_walletAddress);

        // Increment ID for next user
        _userIds.increment();

        // Emit an event for user creation with details
        emit UserCreated(_walletAddress, userId_, _name, _avatarURI);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IDAOAuthority {

    /*********** EVENTS *************/
    event ChangedGovernor(address);
    event ChangedPolicy(address);
    event ChangedAdmin(address);
    event ChangedForwarder(address);

    function governor() external returns(address);
    function policy() external returns(address);
    function admin() external returns(address);
    function forwarder() external view returns(address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/location/ILocationBased.sol";

interface IEntity is ILocationBased {

    /* ========== EVENTS ========== */
    event EntityToggled(address _entity, bool _status);
    event EntityUpdated(address _entity, Area _area, string _dataURI, address _walletAddress);
    event EntityAdminGranted(address _entity, address _entAdmin);
    event BartenderGranted(address _entity, address _bartender);
    event EntityAdminToggled(address _entity, address _entAdmin, bool _status);
    event BartenderToggled(address _entity, address _bartender, bool _status);
    event CollectibleAdded(address _entity, address _collectible);

    event CollectibleWhitelisted(address indexed _entity, address indexed _collectible, uint256 indexed _chainId);
    event CollectibleDelisted(address indexed _entity, address indexed _collectible, uint256 indexed _chainId);

    struct Operator {
        uint256 id;
        string dataURI;
        bool isActive;
    }

    struct BlacklistDetails {
        // Timestamp after which the patron should be removed from blacklist
        uint256 end; 
    }

    struct ContractDetails {
        // Contract address
        address source;

        // ChainId where the contract deployed
        uint256 chainId;
    }

    function updateEntity(
        Area memory _area,
        string memory _dataURI,
        address _walletAddress
    ) external;

    function toggleEntity() external returns(bool _status);

    function addCollectibleToEntity(address _collectible) external;

    function addEntityAdmin(address _entAdmin, string memory _dataURI) external;

    function addBartender(address _bartender, string memory _dataURI) external;

    function toggleEntityAdmin(address _entAdmin) external returns(bool _status);

    function toggleBartender(address _bartender) external returns(bool _status);

    function getEntityAdminDetails(address _entAdmin) external view returns(Operator memory);

    function getBartenderDetails(address _bartender) external view returns(Operator memory);

    function addPatronToBlacklist(address _patron, uint256 _end) external;

    function removePatronFromBlacklist(address _patron) external;

    function whitelistedCollectibles(uint256 index) external view returns(address, uint256);

    function whitelistCollectible(address _source, uint256 _chainId) external;

    function delistCollectible(address _source, uint256 _chainId) external;

    function getWhitelistedCollectibles() external view returns (ContractDetails[] memory);

    function getLocationDetails() external view returns(string[] memory, uint256);

    function getAllEntityAdmins() external view returns(address[] memory);

    function getAllBartenders() external view returns(address[] memory);

    function getAllCollectibles() external view returns(address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ILocationBased {

    struct Area {
        // Area Co-ordinates.
        // For circular area, points[] length = 1 and radius > 0
        // For arbitrary area, points[] length > 1 and radius = 0
        // For arbitrary areas UI should connect the points with a
        // straight line in the same sequence as specified in the points array
        string[] points; // Each element in this array should be specified in "lat,long" format
        uint256 radius; // Unit: Meters. 2 decimals(5000 = 50 meters)
    }
    
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IUser {

    /* ========== EVENTS ========== */
    event UserCreated(address indexed _user, uint256 indexed _userId, string _name, string _avatarURI);

    event NameChanged(address indexed _user, string _name);
    event AvatarChanged(address indexed _user, string _avatarURI);
    event StatusSet(address indexed _user, string _status);
 
    event Followed(address indexed _user, address indexed _followedUser);
    event Unfollowed(address indexed _user, address indexed _unfollwedUser);

    event Banned(address indexed _user);
    event BanLifted(address indexed _user);

    struct UserAttributes {
        address wallet;
        uint256 id;
        string name;
        string avatarURI;
        string status;
    }

    function register(string memory _name, string memory _avatarURI) external returns (uint256);

    function changeName(string memory _name) external;

    function changeAvatar(string memory _avatarURI) external;

    function setStatus(string memory _status) external;

    function follow(address _userToFollow) external;

    function unfollow(address _followedUser) external;

    function getFollowers(address _user) external view returns(UserAttributes[] memory _followers);
    
    function getFollowing(address _user) external view returns(UserAttributes[] memory _following);
    
    function getAllUsers(bool _includeBanned) external view returns(UserAttributes[] memory _users);

    function getBannedUsers() external view returns(UserAttributes[] memory _users);
}