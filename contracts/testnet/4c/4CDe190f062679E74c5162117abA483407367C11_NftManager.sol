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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IPermissions.sol";
import "../lib/TWStrings.sol";

/**
 *  @title   Permissions
 *  @dev     This contracts provides extending-contracts with role-based access control mechanisms
 */
contract Permissions is IPermissions {
    /// @dev Map from keccak256 hash of a role => a map from address => whether address has role.
    mapping(bytes32 => mapping(address => bool)) private _hasRole;

    /// @dev Map from keccak256 hash of a role to role admin. See {getRoleAdmin}.
    mapping(bytes32 => bytes32) private _getRoleAdmin;

    /// @dev Default admin role for all roles. Only accounts with this role can grant/revoke other roles.
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /// @dev Modifier that checks if an account has the specified role; reverts otherwise.
    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    /**
     *  @notice         Checks whether an account has a particular role.
     *  @dev            Returns `true` if `account` has been granted `role`.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account for which the role is being checked.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _hasRole[role][account];
    }

    /**
     *  @notice         Checks whether an account has a particular role;
     *                  role restrictions can be swtiched on and off.
     *
     *  @dev            Returns `true` if `account` has been granted `role`.
     *                  Role restrictions can be swtiched on and off:
     *                      - If address(0) has ROLE, then the ROLE restrictions
     *                        don't apply.
     *                      - If address(0) does not have ROLE, then the ROLE
     *                        restrictions will apply.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account for which the role is being checked.
     */
    function hasRoleWithSwitch(bytes32 role, address account) public view returns (bool) {
        if (!_hasRole[role][address(0)]) {
            return _hasRole[role][account];
        }

        return true;
    }

    /**
     *  @notice         Returns the admin role that controls the specified role.
     *  @dev            See {grantRole} and {revokeRole}.
     *                  To change a role's admin, use {_setRoleAdmin}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function getRoleAdmin(bytes32 role) external view override returns (bytes32) {
        return _getRoleAdmin[role];
    }

    /**
     *  @notice         Grants a role to an account, if not previously granted.
     *  @dev            Caller must have admin role for the `role`.
     *                  Emits {RoleGranted Event}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account to which the role is being granted.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        _checkRole(_getRoleAdmin[role], msg.sender);
        if (_hasRole[role][account]) {
            revert("Can only grant to non holders");
        }
        _setupRole(role, account);
    }

    /**
     *  @notice         Revokes role from an account.
     *  @dev            Caller must have admin role for the `role`.
     *                  Emits {RoleRevoked Event}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account from which the role is being revoked.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        _checkRole(_getRoleAdmin[role], msg.sender);
        _revokeRole(role, account);
    }

    /**
     *  @notice         Revokes role from the account.
     *  @dev            Caller must have the `role`, with caller being the same as `account`.
     *                  Emits {RoleRevoked Event}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account from which the role is being revoked.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        if (msg.sender != account) {
            revert("Can only renounce for self");
        }
        _revokeRole(role, account);
    }

    /// @dev Sets `adminRole` as `role`'s admin role.
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = _getRoleAdmin[role];
        _getRoleAdmin[role] = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /// @dev Sets up `role` for `account`
    function _setupRole(bytes32 role, address account) internal virtual {
        _hasRole[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    /// @dev Revokes `role` from `account`
    function _revokeRole(bytes32 role, address account) internal virtual {
        _checkRole(role, account);
        delete _hasRole[role][account];
        emit RoleRevoked(role, account, msg.sender);
    }

    /// @dev Checks `role` for `account`. Reverts with a message including the required role.
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole[role][account]) {
            revert(
                string(
                    abi.encodePacked(
                        "Permissions: account ",
                        TWStrings.toHexString(uint160(account), 20),
                        " is missing role ",
                        TWStrings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /// @dev Checks `role` for `account`. Reverts with a message including the required role.
    function _checkRoleWithSwitch(bytes32 role, address account) internal view virtual {
        if (!hasRoleWithSwitch(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "Permissions: account ",
                        TWStrings.toHexString(uint160(account), 20),
                        " is missing role ",
                        TWStrings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IPermissionsEnumerable.sol";
import "./Permissions.sol";

/**
 *  @title   PermissionsEnumerable
 *  @dev     This contracts provides extending-contracts with role-based access control mechanisms.
 *           Also provides interfaces to view all members with a given role, and total count of members.
 */
contract PermissionsEnumerable is IPermissionsEnumerable, Permissions {
    /**
     *  @notice A data structure to store data of members for a given role.
     *
     *  @param index    Current index in the list of accounts that have a role.
     *  @param members  map from index => address of account that has a role
     *  @param indexOf  map from address => index which the account has.
     */
    struct RoleMembers {
        uint256 index;
        mapping(uint256 => address) members;
        mapping(address => uint256) indexOf;
    }

    /// @dev map from keccak256 hash of a role to its members' data. See {RoleMembers}.
    mapping(bytes32 => RoleMembers) private roleMembers;

    /**
     *  @notice         Returns the role-member from a list of members for a role,
     *                  at a given index.
     *  @dev            Returns `member` who has `role`, at `index` of role-members list.
     *                  See struct {RoleMembers}, and mapping {roleMembers}
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param index    Index in list of current members for the role.
     *
     *  @return member  Address of account that has `role`
     */
    function getRoleMember(bytes32 role, uint256 index) external view override returns (address member) {
        uint256 currentIndex = roleMembers[role].index;
        uint256 check;

        for (uint256 i = 0; i < currentIndex; i += 1) {
            if (roleMembers[role].members[i] != address(0)) {
                if (check == index) {
                    member = roleMembers[role].members[i];
                    return member;
                }
                check += 1;
            } else if (hasRole(role, address(0)) && i == roleMembers[role].indexOf[address(0)]) {
                check += 1;
            }
        }
    }

    /**
     *  @notice         Returns total number of accounts that have a role.
     *  @dev            Returns `count` of accounts that have `role`.
     *                  See struct {RoleMembers}, and mapping {roleMembers}
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *
     *  @return count   Total number of accounts that have `role`
     */
    function getRoleMemberCount(bytes32 role) external view override returns (uint256 count) {
        uint256 currentIndex = roleMembers[role].index;

        for (uint256 i = 0; i < currentIndex; i += 1) {
            if (roleMembers[role].members[i] != address(0)) {
                count += 1;
            }
        }
        if (hasRole(role, address(0))) {
            count += 1;
        }
    }

    /// @dev Revokes `role` from `account`, and removes `account` from {roleMembers}
    ///      See {_removeMember}
    function _revokeRole(bytes32 role, address account) internal override {
        super._revokeRole(role, account);
        _removeMember(role, account);
    }

    /// @dev Grants `role` to `account`, and adds `account` to {roleMembers}
    ///      See {_addMember}
    function _setupRole(bytes32 role, address account) internal override {
        super._setupRole(role, account);
        _addMember(role, account);
    }

    /// @dev adds `account` to {roleMembers}, for `role`
    function _addMember(bytes32 role, address account) internal {
        uint256 idx = roleMembers[role].index;
        roleMembers[role].index += 1;

        roleMembers[role].members[idx] = account;
        roleMembers[role].indexOf[account] = idx;
    }

    /// @dev removes `account` from {roleMembers}, for `role`
    function _removeMember(bytes32 role, address account) internal {
        uint256 idx = roleMembers[role].indexOf[account];

        delete roleMembers[role].members[idx];
        delete roleMembers[role].indexOf[account];
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IPermissions {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./IPermissions.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IPermissionsEnumerable is IPermissions {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * [forum post](https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296)
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 * @dev String operations.
 */
library TWStrings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author munji - [email protected]

interface IPachi721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import {PermissionsEnumerable} from "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import {NFTStatus, ItemEffects, MatingStatus} from "./StatusStructs.sol";
import {IPachi721} from "./IPachi721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @author munji - [email protected]
contract NftManager is PermissionsEnumerable {
    /** 
        NFTManager is a extension of Pachi721

        Purpose of this contract
            - store status of NFTs
            - manage it
     */

    /** =================================================================================================
        constructor & admin functions
        =================================================================================================
      */

    constructor(
        address _pachi721,
        address _pachiToken
    ) PermissionsEnumerable() {
        pachi721 = IPachi721(_pachi721);
        // should grant nftRole to NFTManager
        pachiToken = IERC20(_pachiToken);
    }

    function grantGameRole(
        address _game
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(GAME_ROLE, _game);
    }

    function grantBankRole(
        address _bank
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(BANK_ROLE, _bank);
    }

    function grantNftRole(address _nft) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(NFT_ROLE, _nft);
    }

    function setPachi721(
        address _pachi721
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        pachi721 = IPachi721(_pachi721);
    }

    function setPachiTokenAddress(
        address _pachiToken
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        pachiToken = IERC20(_pachiToken);
    }

    /** =================================================================================================
        Setup
        =================================================================================================
     */
    IPachi721 public pachi721;
    bytes32 public constant GAME_ROLE = keccak256("GAME_ROLE");
    bytes32 public constant BANK_ROLE = keccak256("BANK_ROLE");
    bytes32 public constant NFT_ROLE = keccak256("NFT_ROLE");
    uint256 public constant DIVISOR = 10000;
    IERC20 public pachiToken;

    mapping(uint256 => NFTStatus) public nftStatus; //tokenId => NFTStatus
    mapping(string => ItemEffects) public itemEffects; //itemName => ItemEffects
    mapping(address => uint256) public addressToSupporter; //user => tokenId

    event NFTStatusInitialized(
        uint256 indexed tokenId,
        uint256 generation,
        bool isMale,
        uint256[2] parents,
        uint256 timestamp
    );

    modifier nftExists(uint256 tokenId) {
        require(pachi721.ownerOf(tokenId) != address(0), "NFT does not exist");
        require(nftStatus[tokenId].level > 0, "NFT level is 0");
        _;
    }

    /** =================================================================================================
        Items
        =================================================================================================
     */

    event ItemPurchased(
        address indexed user,
        uint256 indexed tokenId,
        string itemName
    );

    function registerItem(
        string memory _itemName,
        uint256 _jackpotBoost,
        uint256 _divdendsPoint,
        uint8 _exp,
        uint8 _lovePoint,
        string memory _skin,
        uint256 _price
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            itemEffects[_itemName].exp == 0 &&
                itemEffects[_itemName].jackpotBoost == 0 &&
                itemEffects[_itemName].divdendsPoint == 0 &&
                itemEffects[_itemName].lovePoint == 0 &&
                bytes(itemEffects[_itemName].skin).length == 0 &&
                itemEffects[_itemName].price == 0,
            "item already registered"
        );

        itemEffects[_itemName] = ItemEffects(
            _jackpotBoost,
            _divdendsPoint,
            _exp,
            _lovePoint,
            _skin,
            _price
        );
    }

    function purchaseItem(
        string memory _itemName,
        uint256 tokenId
    ) external nftExists(tokenId) {
        require(
            itemEffects[_itemName].exp > 0 ||
                itemEffects[_itemName].jackpotBoost > 0 ||
                itemEffects[_itemName].divdendsPoint > 0 ||
                itemEffects[_itemName].lovePoint > 0 ||
                bytes(itemEffects[_itemName].skin).length > 0 ||
                itemEffects[_itemName].price > 0,
            "item not registered"
        );

        // item shouldn't be purchased twice
        string[] memory items = nftStatus[tokenId].items;
        for (uint256 i = 0; i < items.length; i++) {
            require(
                keccak256(abi.encodePacked(items[i])) !=
                    keccak256(abi.encodePacked(_itemName)),
                "item already purchased"
            );
        }

        pachiToken.transferFrom(
            msg.sender,
            address(0),
            itemEffects[_itemName].price
        );

        if (itemEffects[_itemName].exp > 0) {
            _updateExpAndLevel(tokenId, itemEffects[_itemName].exp);
        }

        if (itemEffects[_itemName].jackpotBoost > 0) {
            nftStatus[tokenId].jackpotBoost += itemEffects[_itemName]
                .jackpotBoost;
        }

        if (itemEffects[_itemName].divdendsPoint > 0) {
            nftStatus[tokenId].divdendsPoint += itemEffects[_itemName]
                .divdendsPoint;
        }

        if (itemEffects[_itemName].lovePoint > 0) {
            nftStatus[tokenId].lovePoint += itemEffects[_itemName].lovePoint;
        }

        if (bytes(itemEffects[_itemName].skin).length > 0) {
            nftStatus[tokenId].availableSkins.push(itemEffects[_itemName].skin);
        }

        emit ItemPurchased(msg.sender, tokenId, _itemName);
    }

    /** =================================================================================================
        internal status management
        =================================================================================================
     */

    function _updateExpAndLevel(
        uint256 tokenId,
        uint8 exp
    ) internal nftExists(tokenId) {
        nftStatus[tokenId].exp += exp;
        if (nftStatus[tokenId].exp >= 100) {
            nftStatus[tokenId].exp -= 100;
            nftStatus[tokenId].level += 1;
            nftStatus[tokenId].jackpotBoost += 10;
            nftStatus[tokenId].divdendsPoint += 1;
        }
    }

    function _updateLovePoint(
        uint256 tokenId,
        uint8 lovePoint
    ) internal nftExists(tokenId) {
        nftStatus[tokenId].lovePoint += lovePoint;
        if (nftStatus[tokenId].lovePoint >= 100) {
            nftStatus[tokenId].lovePoint = 100;
        }
    }

    function _defaultNftStatus() internal pure returns (NFTStatus memory) {
        return
            NFTStatus({
                generation: uint256(0),
                isMale: false,
                matches: new bool[](0),
                parents: [uint256(0), uint256(0)],
                childs: new uint256[](0),
                level: uint256(1),
                jackpotBoost: uint256(10),
                divdendsPoint: uint256(0),
                exp: 0,
                lovePoint: 0,
                items: new string[](0),
                availableSkins: new string[](0),
                isMating: false,
                isSupporter: false,
                isPending: false
            });
    }

    /** =================================================================================================
        Status management - Direct call 
        =================================================================================================
     */

    function setAsSupporter(uint256 tokenId) external nftExists(tokenId) {
        require(pachi721.ownerOf(tokenId) == msg.sender, "not owner");
        require(
            nftStatus[tokenId].isSupporter == false,
            "already set as partner"
        );

        uint256 prevSupporter = addressToSupporter[msg.sender];
        if (prevSupporter > 0) {
            nftStatus[prevSupporter].isSupporter = false;
            nftStatus[prevSupporter].lovePoint -= 10;
        }

        nftStatus[tokenId].isSupporter = true;
        nftStatus[tokenId].lovePoint += 10;
    }

    /** =================================================================================================
        State management - NFT (Initial state)
        =================================================================================================
     */

    function initiateNFTStatus(
        uint256 tokenId,
        uint256 generation,
        bool isMale,
        uint256[2] memory parents
    ) external onlyRole(NFT_ROLE) {
        require(nftStatus[tokenId].level == 0, "already initialized");

        nftStatus[tokenId] = _defaultNftStatus();
        nftStatus[tokenId].generation = generation;
        nftStatus[tokenId].isMale = isMale;
        nftStatus[tokenId].parents = parents;

        emit NFTStatusInitialized(
            tokenId,
            generation,
            isMale,
            parents,
            block.timestamp
        );
    }

    function isNftTransferable(uint256 tokenId) external view returns (bool) {
        return
            nftStatus[tokenId].isMating == false &&
            nftStatus[tokenId].isSupporter == false &&
            nftStatus[tokenId].isPending == false;
    }

    /** =================================================================================================
        State management - Game
        =================================================================================================
     */

    function updatePendingStatus(
        uint256 tokenId,
        bool isPending
    ) external onlyRole(GAME_ROLE) nftExists(tokenId) {
        nftStatus[tokenId].isPending = isPending;
    }

    function writeMatchResult(
        uint256 tokenId,
        bool matchResult
    ) external onlyRole(GAME_ROLE) nftExists(tokenId) {
        nftStatus[tokenId].matches.push(matchResult);
    }

    /** =================================================================================================
        State management - Bank
        =================================================================================================
     */

    function updateNFTStatus(
        uint256 tokenId,
        uint8 exp,
        uint8 lovePoint
    ) external onlyRole(BANK_ROLE) nftExists(tokenId) {
        if (exp > 0) {
            _updateExpAndLevel(tokenId, exp);
        }
        if (lovePoint > 0) {
            _updateLovePoint(tokenId, lovePoint);
        }
    }

    /** =================================================================================================
        Getter
        =================================================================================================
     */

    function getLevel(
        uint256 tokenId
    ) external view nftExists(tokenId) returns (uint256) {
        return nftStatus[tokenId].level;
    }
}

/** =================================================================================================
        Mating 
        =================================================================================================
     */

// uint256 matingId = 0;
// mapping(uint256 => MatingStatus) public matingStatus;
// mapping(address => uint256[]) public addressToMatingIds;

// function initiateMating(
//     uint256[2] memory tokenIds,
//     uint256 timedelta
// ) external {
//     require(
//         ownerOf(tokenIds[0]) == _msgSender() &&
//             ownerOf(tokenIds[1]) == _msgSender(),
//         "not owner"
//     );
//     require(
//         nftStatus[tokenIds[0]].isMating == false &&
//             nftStatus[tokenIds[1]].isMating == false,
//         "already mating"
//     );

//     // require(nftStatus[tokenId].lovePoint >= 50, "not enough love point");

//     // nftStatus[tokenId].isMating = true;
//     // nftStatus[tokenId].lovePoint -= 50;

//     matingId += 1;
//     matingStatus[matingId] = MatingStatus({
//         tokenIds: tokenIds,
//         startTime: block.timestamp,
//         endTime: block.timestamp + timedelta,
//         birthed: false
//     });

//     addressToMatingIds[_msgSender()].push(matingId);

//     // emit MatingInitiated(_msgSender(), matingId, tokenIds);
// }

// function finalizeMating(uint256 _matingId) external {
//     require(matingStatus[_matingId].endTime <= block.timestamp, "not yet");
//     require(matingStatus[_matingId].birthed == false, "already birthed");

//     uint256[2] memory tokenIds = matingStatus[_matingId].tokenIds;
//     require(
//         ownerOf(tokenIds[0]) == _msgSender() &&
//             ownerOf(tokenIds[1]) == _msgSender(),
//         "not owner"
//     );

//     nftStatus[tokenIds[0]].isMating = false;
//     nftStatus[tokenIds[1]].isMating = false;

//     matingStatus[_matingId].birthed = true;

//     /**
//         should integrate mintWithSignature features
//      */

//     // uint256 tokenId = nextTokenIdToMint();
//     // _safeMint(_msgSender(), tokenId, "");
//     // nftStatus[tokenId] = _defaultNftStatus();
//     // nftStatus[tokenId].generation = nftStatus[tokenIds[0]].generation + 1;

//     // nftStatus[tokenId].parents = tokenIds;
//     // nftStatus[tokenIds[0]].childs.push(tokenId);
//     // nftStatus[tokenIds[1]].childs.push(tokenId);

//     // emit MatingFinalized(_msgSender(), _matingId, tokenId);
// }

//SPDX-License-Identifier: UNLICENSED
//Copyright (C) 2023 munji - All Rights Reserved

pragma solidity 0.8.17;

struct NFTStatus {
    uint256 generation;
    // bloodline Chaos, Titan, Poseidon, Heroic
    // breedType Ascendend, Legendary, Evolution, Mythic, Elite, Popular
    bool[] matches; // 0 - lose 1 - win
    bool isMale;
    uint256[2] parents;
    uint256[] childs;
    uint256 level;
    uint256 jackpotBoost;
    uint256 divdendsPoint;
    uint8 exp;
    uint8 lovePoint;
    string[] items;
    string[] availableSkins;
    bool isMating;
    bool isSupporter;
    bool isPending;
}

struct ItemEffects {
    uint256 jackpotBoost;
    uint256 divdendsPoint;
    uint8 exp;
    uint8 lovePoint;
    string skin;
    uint256 price;
}

struct MatingStatus {
    uint256[2] tokenIds;
    // uint256 price;
    uint256 startTime;
    uint256 endTime;
    bool birthed;
}