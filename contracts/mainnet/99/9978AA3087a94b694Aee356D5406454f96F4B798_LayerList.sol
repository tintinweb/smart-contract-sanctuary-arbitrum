// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LayerList
 * @dev Registry for DeFi Smart Account authorized users.
 */
interface AccountInterface {
    function isAuth(address _user) external view returns (bool);
}

/**
 * @title DSMath
 * @dev Library for basic arithmetic operations with overflow and underflow checks.
 */
contract DSMath {

    /**
     * @dev Adds two numbers, reverts on overflow.
     * @param x First operand.
     * @param y Second operand.
     * @return z Result of addition.
     */
    function add(uint64 x, uint64 y) internal pure returns (uint64 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    /**
     * @dev Subtracts two numbers, reverts on underflow.
     * @param x First operand.
     * @param y Second operand.
     * @return z Result of subtraction.
     */
    function sub(uint64 x, uint64 y) internal pure returns (uint64 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

}

/**
 * @title Variables
 * @dev Contract to manage and store variables related to LayerList.
 */
contract Variables is DSMath {

    // Address of the LayerIndex contract.
    address public immutable layerIndex;

    constructor (address _layerIndex) {
        layerIndex = _layerIndex;
    }

    // Total number of Smart Accounts.
    uint64 public accounts;
    // Mapping from Smart Account address to its ID.
    mapping (address => uint64) public accountID;
    // Mapping from Smart Account ID to its address.
    mapping (uint64 => address) public accountAddr;

    // Mapping from user address to its linked Smart Accounts.
    mapping (address => UserLink) public userLink;
    // Linked list of Smart Accounts associated with a user.
    mapping (address => mapping(uint64 => UserList)) public userList;

    struct UserLink {
        uint64 first;
        uint64 last;
        uint64 count;
    }
    struct UserList {
        uint64 prev;
        uint64 next;
    }

    // Mapping from Smart Account ID to its linked owners.
    mapping (uint64 => AccountLink) public accountLink;
    // Linked list of owners associated with a Smart Account.
    mapping (uint64 => mapping (address => AccountList)) public accountList;

    struct AccountLink {
        address first;
        address last;
        uint64 count;
    }
    struct AccountList {
        address prev;
        address next;
    }

}

/**
 * @title Configure
 * @dev Contract for configuring and managing the LayerList.
 */
contract Configure is Variables {

    constructor (address _layerIndex) Variables(_layerIndex) {}

    /**
     * @dev Add a Smart Account to the linked list of a user.
     * @param _owner Address of the user.
     * @param _account ID of the Smart Account.
     */
    function addAccount(address _owner, uint64 _account) internal {
        if (userLink[_owner].last != 0) {
            userList[_owner][_account].prev = userLink[_owner].last;
            userList[_owner][userLink[_owner].last].next = _account;
        }
        if (userLink[_owner].first == 0) userLink[_owner].first = _account;
        userLink[_owner].last = _account;
        userLink[_owner].count = add(userLink[_owner].count, 1);
    }

    /**
     * @dev Remove a Smart Account from the linked list of a user.
     * @param _owner Address of the user.
     * @param _account ID of the Smart Account.
     */
    function removeAccount(address _owner, uint64 _account) internal {
        uint64 _prev = userList[_owner][_account].prev;
        uint64 _next = userList[_owner][_account].next;
        if (_prev != 0) userList[_owner][_prev].next = _next;
        if (_next != 0) userList[_owner][_next].prev = _prev;
        if (_prev == 0) userLink[_owner].first = _next;
        if (_next == 0) userLink[_owner].last = _prev;
        userLink[_owner].count = sub(userLink[_owner].count, 1);
        delete userList[_owner][_account];
    }

    /**
     * @dev Add a user to the linked list of a Smart Account.
     * @param _owner Address of the user.
     * @param _account ID of the Smart Account.
     */
    function addUser(address _owner, uint64 _account) internal {
        if (accountLink[_account].last != address(0)) {
            accountList[_account][_owner].prev = accountLink[_account].last;
            accountList[_account][accountLink[_account].last].next = _owner;
        }
        if (accountLink[_account].first == address(0)) accountLink[_account].first = _owner;
        accountLink[_account].last = _owner;
        accountLink[_account].count = add(accountLink[_account].count, 1);
    }

    /**
     * @dev Remove a user from the linked list of a Smart Account.
     * @param _owner Address of the user.
     * @param _account ID of the Smart Account.
     */
    function removeUser(address _owner, uint64 _account) internal {
        address _prev = accountList[_account][_owner].prev;
        address _next = accountList[_account][_owner].next;
        if (_prev != address(0)) accountList[_account][_prev].next = _next;
        if (_next != address(0)) accountList[_account][_next].prev = _prev;
        if (_prev == address(0)) accountLink[_account].first = _next;
        if (_next == address(0)) accountLink[_account].last = _prev;
        accountLink[_account].count = sub(accountLink[_account].count, 1);
        delete accountList[_account][_owner];
    }

}

/**
 * @title LayerList
 * @dev Main contract for managing and interacting with LayerList.
 */
contract LayerList is Configure {
    constructor (address _layerIndex) public Configure(_layerIndex) {}

    /**
     * @dev Authorize a Smart Account for a user.
     * @param _owner Address of the user.
     */
    function addAuth(address _owner) external {
        require(accountID[msg.sender] != 0, "not-account");
        require(AccountInterface(msg.sender).isAuth(_owner), "not-owner");
        addAccount(_owner, accountID[msg.sender]);
        addUser(_owner, accountID[msg.sender]);
    }

    /**
     * @dev Deauthorize a Smart Account for a user.
     * @param _owner Address of the user.
     */
    function removeAuth(address _owner) external {
        require(accountID[msg.sender] != 0, "not-account");
        require(!AccountInterface(msg.sender).isAuth(_owner), "already-owner");
        removeAccount(_owner, accountID[msg.sender]);
        removeUser(_owner, accountID[msg.sender]);
    }

    /**
     * @dev Initialize the configuration for a Smart Account.
     * @param _account Address of the Smart Account.
     */
    function init(address  _account) external {
        require(msg.sender == layerIndex, "not-index");
        accounts++;
        accountID[_account] = accounts;
        accountAddr[accounts] = _account;
    }

}