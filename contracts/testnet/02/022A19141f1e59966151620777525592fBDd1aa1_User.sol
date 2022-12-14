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

/***************************************************************************************************
// This contract defines a User of the DAO eco-system
// The users can be different people who interact with the dao contracts through their
// respective end-user applications(Eg: A patron, bar-tender, bar-admin, etc.)
// Once the user registers on the app, it should create a profile for the user on the blockchain
// using this contract
***************************************************************************************************/
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/user/IUser.sol";
import "../access/DAOAccessControlled.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract User is IUser, DAOAccessControlled {
    
    using Counters for Counters.Counter;

    // An incremental unique Id that identifies a user
    Counters.Counter private _userIds;

    // A list of all registered users
    address[] public allUsers;

    // User wallet address => User Attributes
    // This maps unique user Ids to users details
    mapping(address => UserAttributes) public userAttributes;

    // Mapping to check if given two users are friends
    // address => address => bool
    mapping(address => mapping(address => bool)) public areFriends;

    constructor(address _authority) DAOAccessControlled(IDAOAuthority(_authority)) {
        _userIds.increment(); // Start from 1 as id == 0 is a check for existence
    }

    /****************************************************************************************
    // Creates a user with the given name, avatar and wallet Address
    // Newly created users are added to a list and stored in this contracts storage
    // A mapping maps each user ID to their detais
    // The application can use the list and mapping to get relevant details about the user
    ****************************************************************************************/
    function createUser(
        string memory _name, 
        string memory _avatar,
        address _walletAddress
    ) external onlyForwarder returns (uint256 newUserId) {

        // A non-zero wallet address is mandatory
        require(_walletAddress != address(0), "Wallet address needed");

        // to avoid duplicate user
        require(userAttributes[_walletAddress].id == 0, "User already exists");

        // A non-empty user name is required
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")), "Name cannot be empty string");
        
        // Assign a unique ID to the new user to be created
        newUserId = _userIds.current();
        
        // Set details for the user and add them to the mapping
        userAttributes[_walletAddress] = UserAttributes({
            id: newUserId,
            name: _name,
            avatar: _avatar,
            status: ""
        });

        // Add the new user to list of users
        allUsers.push(_walletAddress);

        // Increment ID for next user
        _userIds.increment();

        // Emit an event for user creation with details
        emit UserCreated(_name, _avatar, _walletAddress);
    }

    // Allows a user to set their display name
    function setName(address _walletAddress, string memory _name) external onlyForwarder {
        require(userAttributes[_walletAddress].id != 0, "NON EXISTENT");
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")), "Name cannot be empty string");
        
        userAttributes[_walletAddress].name = _name;

        emit NameSet(_walletAddress, _name);
    }

    // Allows a user to set their avatar
    function setAvatar(address _walletAddress, string memory _avatar) external onlyForwarder {
        require(userAttributes[_walletAddress].id != 0, "NON EXISTENT");
        userAttributes[_walletAddress].avatar = _avatar;
        emit AvatarSet(_walletAddress, _avatar);
    }

    // Allows a user to set their text status
    function setStatus(address _walletAddress, string memory _status) external onlyForwarder {
        require(userAttributes[_walletAddress].id != 0, "NON EXISTENT");
        userAttributes[_walletAddress].status = _status;
        emit StatusSet(_walletAddress, _status);
    }

    // Adds friend for a user
    function addFriend(address _walletAddress, address _friend) external onlyForwarder {
        require(userAttributes[_walletAddress].id != 0, "NON EXISTENT");
        require(userAttributes[_friend].id != 0, "NON EXISTENT");
        areFriends[_walletAddress][_friend] = true;
        areFriends[_friend][_walletAddress] = true;
        emit AddedFriend(_walletAddress, _friend);
        emit AddedFriend(_friend, _walletAddress);
    }

    // Removes friend for a user
    function removeFriend(address _walletAddress, address _friend) external onlyForwarder {
        require(userAttributes[_walletAddress].id != 0, "NON EXISTENT");
        require(userAttributes[_friend].id != 0, "NON EXISTENT");
        areFriends[_walletAddress][_friend] = false;
        areFriends[_friend][_walletAddress] = false;
        emit RemovedFriend(_walletAddress, _friend);
        emit RemovedFriend(_friend, _walletAddress);
    }

    // Get friends for a user
    function friendList(address _walletAddress) public view returns(address[] memory _friends) {
        require(userAttributes[_walletAddress].id != 0, "NON EXISTENT");

        for(uint256 i = 0; i < allUsers.length; i++) {
            if(areFriends[_walletAddress][allUsers[i]]) {
                _friends[i] = allUsers[i];
            }
        }
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

    function getLocationDetails() external view returns(string[] memory, uint256);
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
    event UserCreated(string _name, string _avatar, address _walletAddress);
    event NameSet(address _walletAddress, string _name);
    event AvatarSet(address _walletAddress, string _avatar);
    event StatusSet(address _walletAddress, string _status);
    event AddedFriend(address, address);
    event RemovedFriend(address, address);

    struct UserAttributes {
        uint256 id;
        string name;
        string avatar; // IPFS Link
        string status; // Text Status 
    }

    function createUser(
        string memory _name, 
        string memory _avatar, 
        address _walletAddress
    ) external returns (uint256 newUserId);

    function setName(address _walletAddress, string memory _name) external;

    function setAvatar(address _walletAddress, string memory _avatar) external;

    function setStatus(address _walletAddress, string memory _status) external;

    function addFriend(address _walletAddress, address _friend) external;

    function removeFriend(address _walletAddress, address _friend) external;

    function friendList(address _walletAddress) external view returns(address[] memory _friends);
}