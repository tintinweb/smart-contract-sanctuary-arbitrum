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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAccessControl } from './IAccessControl.sol';
import { AccessControlInternal } from './AccessControlInternal.sol';

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract AccessControl is IAccessControl, AccessControlInternal {
    /**
     * @inheritdoc IAccessControl
     */
    function grantRole(
        bytes32 role,
        address account
    ) external onlyRole(_getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool) {
        return _hasRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32) {
        return _getRoleAdmin(role);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function revokeRole(
        bytes32 role,
        address account
    ) external onlyRole(_getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function renounceRole(bytes32 role) external {
        _renounceRole(role);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function getRoleMember(
        bytes32 role,
        uint256 index
    ) external view returns (address) {
        return _getRoleMember(role, index);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256) {
        return _getRoleMemberCount(role);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { UintUtils } from '../../utils/UintUtils.sol';
import { IAccessControlInternal } from './IAccessControlInternal.sol';
import { AccessControlStorage } from './AccessControlStorage.sol';

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract AccessControlInternal is IAccessControlInternal {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UintUtils for uint256;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function _hasRole(
        bytes32 role,
        address account
    ) internal view virtual returns (bool) {
        return
            AccessControlStorage.layout().roles[role].members.contains(account);
    }

    /**
     * @notice revert if sender does not have given role
     * @param role role to query
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, msg.sender);
    }

    /**
     * @notice revert if given account does not have given role
     * @param role role to query
     * @param account to query
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        'AccessControl: account ',
                        account.toString(),
                        ' is missing role ',
                        uint256(role).toHexString(32)
                    )
                )
            );
        }
    }

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function _getRoleAdmin(
        bytes32 role
    ) internal view virtual returns (bytes32) {
        return AccessControlStorage.layout().roles[role].adminRole;
    }

    /**
     * @notice set role as admin role
     * @param role role to set
     * @param adminRole admin role to set
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = _getRoleAdmin(role);
        AccessControlStorage.layout().roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.add(account);
        emit RoleGranted(role, account, msg.sender);
    }

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.remove(account);
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function _renounceRole(bytes32 role) internal virtual {
        _revokeRole(role, msg.sender);
    }

    /**
     * @notice query role for member at given index
     * @param role role to query
     * @param index index to query
     */
    function _getRoleMember(
        bytes32 role,
        uint256 index
    ) internal view virtual returns (address) {
        return AccessControlStorage.layout().roles[role].members.at(index);
    }

    /**
     * @notice query role for member count
     * @param role role to query
     */
    function _getRoleMemberCount(
        bytes32 role
    ) internal view virtual returns (uint256) {
        return AccessControlStorage.layout().roles[role].members.length();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';

library AccessControlStorage {
    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.AccessControl');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAccessControlInternal } from './IAccessControlInternal.sol';

/**
 * @title AccessControl interface
 */
interface IAccessControl is IAccessControlInternal {
    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function grantRole(bytes32 role, address account) external;

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function renounceRole(bytes32 role) external;

    /**
     * @notice Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(
        bytes32 role,
        uint256 index
    ) external view returns (address);

    /**
     * @notice Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial AccessControl interface needed by internal functions
 */
interface IAccessControlInternal {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    function indexOf(
        AddressSet storage set,
        address value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(
        UintSet storage set,
        uint256 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return set._inner._values;
    }

    function toArray(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] storage values = set._inner._values;
        address[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function toArray(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] storage values = set._inner._values;
        uint256[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _indexOf(
        Set storage set,
        bytes32 value
    ) private view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            status = true;
        }
    }

    function _remove(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            status = true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IPausableInternal } from './IPausableInternal.sol';

interface IPausable is IPausableInternal {
    /**
     * @notice query whether contract is paused
     * @return status whether contract is paused
     */
    function paused() external view returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IPausableInternal {
    error Pausable__Paused();
    error Pausable__NotPaused();

    event Paused(address account);
    event Unpaused(address account);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IPausable } from './IPausable.sol';
import { PausableInternal } from './PausableInternal.sol';

/**
 * @title Pausable security control module.
 */
abstract contract Pausable is IPausable, PausableInternal {
    /**
     * @inheritdoc IPausable
     */
    function paused() external view virtual returns (bool status) {
        status = _paused();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IPausableInternal } from './IPausableInternal.sol';
import { PausableStorage } from './PausableStorage.sol';

/**
 * @title Internal functions for Pausable security control module.
 */
abstract contract PausableInternal is IPausableInternal {
    modifier whenNotPaused() {
        if (_paused()) revert Pausable__Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused()) revert Pausable__NotPaused();
        _;
    }

    /**
     * @notice query whether contract is paused
     * @return status whether contract is paused
     */
    function _paused() internal view virtual returns (bool status) {
        status = PausableStorage.layout().paused;
    }

    /**
     * @notice Triggers paused state, when contract is unpaused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage.layout().paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Triggers unpaused state, when contract is paused.
     */
    function _unpause() internal virtual whenPaused {
        delete PausableStorage.layout().paused;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library PausableStorage {
    struct Layout {
        bool paused;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Pausable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IReentrancyGuard {
    error ReentrancyGuard__ReentrantCall();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IReentrancyGuard } from './IReentrancyGuard.sol';
import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard is IReentrancyGuard {
    uint256 internal constant REENTRANCY_STATUS_LOCKED = 2;
    uint256 internal constant REENTRANCY_STATUS_UNLOCKED = 1;

    modifier nonReentrant() virtual {
        if (_isReentrancyGuardLocked()) revert ReentrancyGuard__ReentrantCall();
        _lockReentrancyGuard();
        _;
        _unlockReentrancyGuard();
    }

    /**
     * @notice returns true if the reentrancy guard is locked, false otherwise
     */
    function _isReentrancyGuardLocked() internal view virtual returns (bool) {
        return
            ReentrancyGuardStorage.layout().status == REENTRANCY_STATUS_LOCKED;
    }

    /**
     * @notice lock functions that use the nonReentrant modifier
     */
    function _lockReentrancyGuard() internal virtual {
        ReentrancyGuardStorage.layout().status = REENTRANCY_STATUS_LOCKED;
    }

    /**
     * @notice unlock functions that use the nonReentrant modifier
     */
    function _unlockReentrancyGuard() internal virtual {
        ReentrancyGuardStorage.layout().status = REENTRANCY_STATUS_UNLOCKED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { AccessControlInternal } from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";

import { LibAccessControl } from "../libraries/LibAccessControl.sol";
import { LibWhitelabel } from "../libraries/LibWhitelabel.sol";

abstract contract WhitelistInternal is AccessControlInternal {
    modifier onlyWhitelisted(address account, bytes32 productId) {
        LibWhitelabel.DiamondStorage storage ds = LibWhitelabel.diamondStorage();
        require(!ds.isWhitelistEnabled[productId] || _hasRole(LibAccessControl.WHITELISTED_ROLE, account), "Whitelist: caller is not whitelisted");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibAccessControl {
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 internal constant WHITELIST_ADMIN_ROLE = keccak256("WHITELIST_ADMIN_ROLE");
    bytes32 internal constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibWhitelabel {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("floki.whitelabel.diamond.storage");

    struct DiamondStorage {
        mapping(bytes32 => bool) isWhitelistEnabled; // bytes32 is productIdentifier generated using keccak256
    }

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import { LibDiamond } from "./libraries/LibDiamond.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";

contract Diamond {
    constructor(address _contractOwner, address _diamondCutFacet) payable {
        LibDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({ facetAddress: _diamondCutFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });
        LibDiamond.diamondCut(cut, address(0), "");
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondProxy {
    function implementation() external view returns (address);

    function setImplementation(address _implementation) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import { IPausable } from "@solidstate/contracts/security/pausable/Pausable.sol";

interface IPausableFacet is IPausable {
    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 public constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { IAccessControl } from "@solidstate/contracts/access/access_control/AccessControl.sol";
import { IReentrancyGuard } from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";

import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IDiamondProxy } from "../interfaces/IDiamondProxy.sol";
import { IPausableFacet, IPausable } from "../interfaces/IPausableFacet.sol";

library LibDiamondHelpers {
    function getAccessControlSelectors() internal pure returns (bytes4[] memory functionSelectors) {
        functionSelectors = new bytes4[](7);
        functionSelectors[0] = IAccessControl.hasRole.selector;
        functionSelectors[1] = IAccessControl.getRoleAdmin.selector;
        functionSelectors[2] = IAccessControl.grantRole.selector;
        functionSelectors[3] = IAccessControl.revokeRole.selector;
        functionSelectors[4] = IAccessControl.renounceRole.selector;
        functionSelectors[5] = IAccessControl.getRoleMember.selector;
        functionSelectors[6] = IAccessControl.getRoleMemberCount.selector;
    }

    function getPausableSelectors() internal pure returns (bytes4[] memory functionSelectors) {
        functionSelectors = new bytes4[](3);
        functionSelectors[0] = IPausable.paused.selector;
        functionSelectors[1] = IPausableFacet.pause.selector;
        functionSelectors[2] = IPausableFacet.unpause.selector;
    }

    function getDiamondLoupeSelectors() internal pure returns (bytes4[] memory functionSelectors) {
        functionSelectors = new bytes4[](4);
        functionSelectors[0] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[1] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facets.selector;
    }

    function getDiamondProxySelectors() internal pure returns (bytes4[] memory functionSelectors) {
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = IDiamondProxy.implementation.selector;
        functionSelectors[1] = IDiamondProxy.setImplementation.selector;
    }

    function getReentrancyGuardSelectors() internal pure returns (bytes4[] memory functionSelectors) {
        functionSelectors = new bytes4[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { AccessControlStorage } from "@solidstate/contracts/access/access_control/AccessControlStorage.sol";

import { IERC20, IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { ILaunchPadFactory, ILaunchPadCommon } from "../interfaces/ILaunchPadFactory.sol";
import { ILaunchPadPayment } from "../interfaces/ILaunchPadPayment.sol";
import { ILaunchPadPricing } from "../interfaces/ILaunchPadPricing.sol";
import { ILaunchPadProject } from "../interfaces/ILaunchPadProject.sol";
import { ILaunchPadProjectInit } from "../interfaces/ILaunchPadProjectInit.sol";
import { LibLaunchPadFactoryStorage } from "../libraries/LaunchPadFactoryStorage.sol";
import { LibLaunchPadProjectStorage } from "../libraries/LaunchPadProjectStorage.sol";
import { LibLaunchPadConsts } from "../libraries/LaunchPadConsts.sol";
import { IDiamondCut } from "../../common/diamonds/interfaces/IDiamondCut.sol";
import { LibDiamond } from "../../common/diamonds/libraries/LibDiamond.sol";
import { LibDiamondHelpers } from "../../common/diamonds/libraries/LibDiamondHelpers.sol";
import { Diamond } from "../../common/diamonds/Diamond.sol";
import { ITokenLauncherERC20, ITokenLauncherCommon } from "../../token-launcher/interfaces/ITokenLauncherERC20.sol";
import { ITokenLauncherLiquidityPoolFactory } from "../../token-launcher/interfaces/ITokenLauncherLiquidityPoolFactory.sol";
import { ITokenFiERC20 } from "../../token-launcher/interfaces/ITokenFiERC20.sol";
import { WhitelistInternal } from "../../common/admin/internal/WhitelistInternal.sol";

contract LaunchPadFactoryFacet is ILaunchPadFactory, WhitelistInternal {
    function addInvestorToLaunchPad(address investor) external override {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        // Can only be called by a launchpad contract
        require(ds.isLaunchPad[msg.sender], "LaunchPadFactoryFacet:addInvestorToLaunchPad: LaunchPad does not exist");
        ds.launchPadsByInvestor[investor].push(msg.sender);
    }

    function createLaunchPad(
        ILaunchPadCommon.CreateLaunchPadInput memory storeInput
    ) external payable override onlyWhitelisted(msg.sender, LibLaunchPadConsts.PRODUCT_ID) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();

        if (storeInput.launchPadType == LaunchPadType.FlokiPadCreatedBefore) {
            // create a TokenFiERC20 token by using TokenLauncherERC20
            // payment would be ignored because launchpad factory has a discount NFT
            address tokenAdress = ITokenLauncherERC20(ds.tokenLauncherERC20).createErc20(
                ITokenLauncherERC20.CreateErc20Input({
                    name: storeInput.createErc20Input.name,
                    symbol: storeInput.createErc20Input.symbol,
                    logo: storeInput.createErc20Input.logo,
                    decimals: storeInput.createErc20Input.decimals,
                    initialSupply: storeInput.launchPadInfo.fundTarget.hardCap + storeInput.createErc20Input.treasuryReserved,
                    maxSupply: storeInput.createErc20Input.maxSupply,
                    treasury: address(this),
                    owner: storeInput.createErc20Input.owner,
                    referrer: storeInput.referrer,
                    tokenStore: ds.tokenLauncherStore,
                    fees: ITokenLauncherERC20.Fees({
                        transferFee: ITokenLauncherERC20.FeeDetails({ percentage: 0, onlyOnSwaps: false }),
                        burn: ITokenLauncherERC20.FeeDetails({ percentage: 0, onlyOnSwaps: false }),
                        reflection: ITokenLauncherERC20.FeeDetails({ percentage: 0, onlyOnSwaps: false }),
                        buyback: ITokenLauncherERC20.FeeDetails({ percentage: 0, onlyOnSwaps: false })
                    }),
                    buybackHandler: ds.tokenLauncherBuybackHandler,
                    paymentMethod: ITokenLauncherCommon.PaymentMethod(uint256(storeInput.paymentMethod))
                })
            );
            storeInput.launchPadInfo.tokenAddress = tokenAdress;
        } else if (storeInput.launchPadType == LaunchPadType.FlokiPadCreatedAfter) {
            // create a TokenFiERC20 token by using TokenLauncherERC20 after ICO by the launchpad owner
            // payment would be ignored because launchpad factory has a discount NFT
            require(storeInput.createErc20Input.owner != address(0), "LaunchPadFactory::createLaunchPad(): owner cannot be Address Zero ");
            require(
                storeInput.createErc20Input.maxSupply >= storeInput.launchPadInfo.fundTarget.hardCap,
                "LaunchPadFactory::createLaunchPad(): maxSupply cannot be smaller than launchPad hardCap"
            );
            storeInput.launchPadInfo.tokenAddress = address(0);
        } else {
            revert("LaunchPadFactory: Invalid launchPadType");
        }

        // First let's calculate the price
        uint256 usdPrice = ILaunchPadPricing(address(this)).getPrice(msg.sender, storeInput.launchPadType);
        // Now let's process the payment
        ILaunchPadPayment.ProcessPaymentInput memory paymentInput = ILaunchPadPayment.ProcessPaymentInput({
            referrer: storeInput.referrer,
            usdPrice: usdPrice,
            user: msg.sender,
            paymentMethod: storeInput.paymentMethod
        });
        ILaunchPadPayment(address(this)).processPayment{ value: msg.value }(paymentInput);

        // Create the new LaunchPad
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        LibDiamond.FacetAddressAndPosition memory diamondCutFacet = diamondStorage.selectorToFacetAndPosition[IDiamondCut.diamondCut.selector];
        address launchPad = address(new Diamond(address(this), diamondCutFacet.facetAddress));

        _prepareLaunchPadDiamond(launchPad, storeInput);

        // Transfer token to the launchpad and treasury address
        if (storeInput.launchPadType == LaunchPadType.FlokiPadCreatedBefore) {
            IERC20(storeInput.launchPadInfo.tokenAddress).transfer(address(launchPad), storeInput.launchPadInfo.fundTarget.hardCap);
            if (storeInput.createErc20Input.treasuryReserved > 0) {
                IERC20(storeInput.launchPadInfo.tokenAddress).transfer(storeInput.createErc20Input.owner, storeInput.createErc20Input.treasuryReserved);
            }
        }

        // Log new launchPad into store
        _addLaunchPad(storeInput, launchPad, usdPrice);
    }

    function createTokenAfterICO(address launchPad) external payable override onlyLaunchPadOwner(launchPad) {
        require(
            ILaunchPadProject(launchPad).getLaunchPadInfo().tokenAddress == address(0),
            "LaunchPadFactory:createTokenAfterICO: Token address is already set"
        );

        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        require(ds.launchPadOwner[launchPad] != address(0), "LaunchPadFactory:createTokenAfterICO: LaunchPad does not exist");

        CreateErc20Input memory createErc20Input = ds.tokenInfoByLaunchPadAddress[launchPad];

        // create a TokenFiERC20 token by using TokenLauncherERC20
        // payment would be ignored because launchpad factory has a discount NFT
        address tokenAddress = ITokenLauncherERC20(ds.tokenLauncherERC20).createErc20{ value: msg.value }(
            ITokenLauncherERC20.CreateErc20Input({
                name: createErc20Input.name,
                symbol: createErc20Input.symbol,
                logo: createErc20Input.logo,
                decimals: createErc20Input.decimals,
                initialSupply: ILaunchPadProject(launchPad).totalTokensSold() + createErc20Input.treasuryReserved,
                maxSupply: createErc20Input.maxSupply,
                treasury: address(this),
                owner: address(this),
                referrer: address(0),
                tokenStore: ds.tokenLauncherStore,
                fees: ITokenLauncherERC20.Fees({
                    transferFee: ITokenLauncherERC20.FeeDetails({ percentage: 0, onlyOnSwaps: false }),
                    burn: ITokenLauncherERC20.FeeDetails({ percentage: 0, onlyOnSwaps: false }),
                    reflection: ITokenLauncherERC20.FeeDetails({ percentage: 0, onlyOnSwaps: false }),
                    buyback: ITokenLauncherERC20.FeeDetails({ percentage: 0, onlyOnSwaps: false })
                }),
                buybackHandler: ds.tokenLauncherBuybackHandler,
                paymentMethod: ITokenLauncherCommon.PaymentMethod(0)
            })
        );
        ILaunchPadProject(launchPad).setTokenAddress(tokenAddress);
        ITokenFiERC20(tokenAddress).updateTreasury(createErc20Input.owner);
        IAccessControl(tokenAddress).grantRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, createErc20Input.owner);
        IAccessControl(tokenAddress).renounceRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, address(this));

        // Transfer the totalTokensSold() amount to the launchpad
        IERC20(tokenAddress).transfer(launchPad, ILaunchPadProject(launchPad).totalTokensSold());
        // Transfer the treasury amount to the treasury
        if (createErc20Input.treasuryReserved > 0) {
            IERC20(tokenAddress).transfer(createErc20Input.owner, createErc20Input.treasuryReserved);
        }
    }

    function setExistingTokenAfterICO(address launchPad, address tokenAddress, uint256 amount) external override onlyLaunchPadOwner(launchPad) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        require(ds.launchPadOwner[launchPad] != address(0), "LaunchPadFactory:setExistingTokenAfterICO: LaunchPad does not exist");
        require(
            ILaunchPadProject(launchPad).getLaunchPadInfo().tokenAddress == address(0),
            "LaunchPadFactory:setExistingTokenAfterICO: Token address is already set"
        );

        ILaunchPadProject(launchPad).setTokenAddress(tokenAddress);

        // Transfer tokens from the user to this
        uint256 initialBalance = IERC20(tokenAddress).balanceOf(launchPad);
        IERC20(tokenAddress).transferFrom(msg.sender, launchPad, amount);
        uint256 receivedTokens = IERC20(tokenAddress).balanceOf(launchPad) - initialBalance;
        require(
            receivedTokens >= ILaunchPadProject(launchPad).totalTokensSold(),
            "LaunchPadFactory:setExistingTokenAfterICO: Token has tax, please exempt launchpad address"
        );
    }

    function setExistingTokenAfterTransfer(address launchPad, address tokenAddress) external override onlyLaunchPadOwner(launchPad) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        require(ds.launchPadOwner[launchPad] != address(0), "LaunchPadFactory:setExistingTokenAfterTransfer: LaunchPad does not exist");
        require(
            ILaunchPadProject(launchPad).getLaunchPadInfo().tokenAddress == address(0),
            "LaunchPadFactory:setExistingTokenAfterTransfer: Token address is already set"
        );
        ILaunchPadProject(launchPad).setTokenAddress(tokenAddress);

        // Check if the launchpad has received at least the total tokens sold
        uint256 currentBalance = IERC20(tokenAddress).balanceOf(launchPad);
        require(
            currentBalance >= ILaunchPadProject(launchPad).totalTokensSold(),
            "LaunchPadFactory:setExistingTokenAfterTransfer: Launchpad has not received tokens yet"
        );
    }

    function createV2LiquidityPool(address launchPad) external payable override onlyLaunchPadOwner(launchPad) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        require(ds.launchPadOwner[launchPad] != address(0), "LaunchPadFactory:createV2LiquidityPool: LaunchPad does not exist");

        ILaunchPadCommon.LaunchPadInfo memory launchPadInfo = ILaunchPadProject(launchPad).getLaunchPadInfo();
        require(block.timestamp > launchPadInfo.startTimestamp + launchPadInfo.duration, "Sale is still ongoing");
        require(
            ILaunchPadProject(launchPad).getLaunchPadInfo().tokenAddress != address(0),
            "LaunchPadFactory:addV2Liquidity: Token address is 0 - token does not exist"
        );
        require(launchPadInfo.idoInfo.enabled == true, "LaunchPad:addV2Liquidity: IDO is not enabled");

        uint256 tokenDecimals = IERC20Metadata(launchPadInfo.tokenAddress).decimals();
        ITokenLauncherLiquidityPoolFactory.CreateV2Input memory createV2Input = ITokenLauncherLiquidityPoolFactory.CreateV2Input({
            owner: launchPadInfo.owner,
            treasury: launchPadInfo.owner,
            liquidityPoolDetails: ITokenLauncherLiquidityPoolFactory.LiquidityPoolDetails({
                sourceToken: launchPadInfo.tokenAddress,
                pairedToken: launchPadInfo.idoInfo.pairToken,
                amountSourceToken: launchPadInfo.idoInfo.amountToList,
                amountPairedToken: (launchPadInfo.idoInfo.price * launchPadInfo.idoInfo.amountToList) / (10 ** tokenDecimals),
                routerAddress: launchPadInfo.idoInfo.dexRouter
            }),
            lockLPDetails: ITokenLauncherLiquidityPoolFactory.LockLPDetails({
                lockLPTokenPercentage: 0,
                unlockTimestamp: 0,
                beneficiary: launchPadInfo.owner,
                isVesting: false
            }),
            buybackDetails: ITokenLauncherLiquidityPoolFactory.BuyBackDetails({
                pairToken: launchPadInfo.idoInfo.pairToken,
                router: launchPadInfo.idoInfo.dexRouter,
                liquidityBasisPoints: 0,
                priceImpactBasisPoints: 0
            })
        });

        ITokenLauncherERC20(ds.tokenLauncherERC20).createV2LiquidityPool{ value: msg.value }(createV2Input);
    }

    function updateLaunchPadOwner(address launchPadAddress, address newOwner) external override onlyLaunchPadOwner(launchPadAddress) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();

        address owner = ds.launchPadOwner[launchPadAddress];
        require(owner != newOwner, "LaunchPadStore: Same owner");
        require(newOwner != address(0), "LaunchPadStore: New owner cannot be 0");
        address[] storage launchPads = ds.launchPadsByOwner[owner];

        bool _launchPadExists = false;
        for (uint256 i = 0; i < ds.launchPadsByOwner[owner].length; i++) {
            if (ds.launchPadsByOwner[owner][i] == launchPadAddress) {
                ds.launchPadsByOwner[owner][i] = ds.launchPadsByOwner[owner][launchPads.length - 1];
                ds.launchPadsByOwner[owner].pop();
                _launchPadExists = true;
                break;
            }
        }
        require(_launchPadExists == true, "LaunchPadStore: LaunchPad does not exist");

        ds.launchPadsByOwner[newOwner].push(launchPadAddress);
        ds.launchPadOwner[launchPadAddress] = newOwner;
        emit LibLaunchPadFactoryStorage.LaunchPadOwnerUpdated(ds.currentBlockLaunchPadOwnerUpdated, owner, newOwner);
        ds.currentBlockLaunchPadOwnerUpdated = block.number;
    }

    function _addLaunchPad(ILaunchPadCommon.CreateLaunchPadInput memory input, address launchPad, uint256 usdPrice) private {
        require(input.launchPadInfo.owner != address(0), "LaunchPadFactory: Owner cannot be 0");
        ILaunchPadFactory.StoreLaunchPadInput memory storeInput = ILaunchPadFactory.StoreLaunchPadInput({
            launchPadType: input.launchPadType,
            launchPadAddress: launchPad,
            owner: input.launchPadInfo.owner,
            referrer: input.referrer,
            usdPrice: usdPrice
        });

        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();

        ds.launchPadsByOwner[storeInput.owner].push(storeInput.launchPadAddress);
        ds.launchPads.push(storeInput.launchPadAddress);
        ds.isLaunchPad[storeInput.launchPadAddress] = true;
        ds.launchPadOwner[storeInput.launchPadAddress] = storeInput.owner;
        ds.tokenInfoByLaunchPadAddress[storeInput.launchPadAddress] = input.createErc20Input;
        ds.currentBlockLaunchPadCreated = block.number;
        emit LibLaunchPadFactoryStorage.LaunchPadCreated(ds.currentBlockLaunchPadCreated, storeInput.launchPadType, storeInput.owner, storeInput);
    }

    function _prepareLaunchPadDiamond(address launchPad, ILaunchPadCommon.CreateLaunchPadInput memory input) private {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](5);

        // Add LaunchPadProjectFacet
        bytes4[] memory functionSelectors = LibLaunchPadFactoryStorage.getLaunchPadProjectSelectors();

        cut[0] = IDiamondCut.FacetCut({ facetAddress: ds.launchPadProjectFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });

        // Add AccessControlFacet
        functionSelectors = LibDiamondHelpers.getAccessControlSelectors();
        cut[1] = IDiamondCut.FacetCut({ facetAddress: ds.accessControlFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });

        // Add PausableFacet
        functionSelectors = LibDiamondHelpers.getPausableSelectors();
        cut[2] = IDiamondCut.FacetCut({ facetAddress: ds.pausableFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });

        // Add DiamondLoupeFacet
        functionSelectors = LibDiamondHelpers.getDiamondLoupeSelectors();
        cut[3] = IDiamondCut.FacetCut({ facetAddress: ds.loupeFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });

        // Add DiamondProxy
        functionSelectors = LibDiamondHelpers.getDiamondProxySelectors();
        cut[4] = IDiamondCut.FacetCut({ facetAddress: ds.proxyFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });

        // Add Facets to LaunchPad Diamond and initialize it
        bytes memory _calldata = abi.encodeCall(ILaunchPadProjectInit.init, input);
        IDiamondCut(launchPad).diamondCut(cut, ds.launchPadProjectDiamondInit, _calldata);
    }

    modifier onlyAdmin() {
        require(
            IAccessControl(address(this)).hasRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, msg.sender),
            "LaunchPadFactory: Only admin can call this function"
        );
        _;
    }

    modifier onlyLaunchPadOwner(address launchPad) {
        require(
            IAccessControl(launchPad).hasRole(LibLaunchPadProjectStorage.LAUNCHPAD_OWNER_ROLE, msg.sender),
            "LaunchPadFactory: Only project owner can call this function"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ILaunchPadCommon {
    enum LaunchPadType {
        FlokiPadCreatedBefore,
        FlokiPadCreatedAfter
    }

    enum PaymentMethod {
        NATIVE,
        USD,
        TOKENFI
    }

    struct IdoInfo {
        bool enabled;
        address dexRouter;
        address pairToken;
        uint256 price;
        uint256 amountToList;
    }

    struct RefundInfo {
        uint256 penaltyFeePercent;
        uint256 expireDuration;
    }

    struct FundTarget {
        uint256 softCap;
        uint256 hardCap;
    }

    struct ReleaseSchedule {
        uint256 timestamp;
        uint256 percent;
    }

    struct ReleaseScheduleV2 {
        uint256 timestamp;
        uint256 percent;
        bool isVesting;
    }

    struct CreateErc20Input {
        string name;
        string symbol;
        string logo;
        uint8 decimals;
        uint256 maxSupply;
        address owner;
        uint256 treasuryReserved;
    }

    struct LaunchPadInfo {
        address owner;
        address tokenAddress;
        address paymentTokenAddress;
        uint256 price;
        FundTarget fundTarget;
        uint256 maxInvestPerWallet;
        uint256 startTimestamp;
        uint256 duration;
        uint256 tokenCreationDeadline;
        RefundInfo refundInfo;
        IdoInfo idoInfo;
    }

    struct CreateLaunchPadInput {
        LaunchPadType launchPadType;
        LaunchPadInfo launchPadInfo;
        ReleaseScheduleV2[] releaseSchedule;
        CreateErc20Input createErc20Input;
        address referrer;
        bool isSuperchargerEnabled;
        PaymentMethod paymentMethod;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";
import { IDiamondCut } from "../../common/diamonds/interfaces/IDiamondCut.sol";

interface ILaunchPadFactory is ILaunchPadCommon {
    struct StoreLaunchPadInput {
        ILaunchPadCommon.LaunchPadType launchPadType;
        address launchPadAddress;
        address owner;
        address referrer;
        uint256 usdPrice;
    }

    function addInvestorToLaunchPad(address investor) external;

    function createLaunchPad(ILaunchPadCommon.CreateLaunchPadInput memory input) external payable;

    function createTokenAfterICO(address launchPadAddress) external payable;

    function setExistingTokenAfterICO(address launchPad, address tokenAddress, uint256 amount) external;

    function setExistingTokenAfterTransfer(address launchPad, address tokenAddress) external;

    function createV2LiquidityPool(address launchPadAddress) external payable;

    function updateLaunchPadOwner(address tokenAddress, address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";

interface ILaunchPadPayment is ILaunchPadCommon {
    struct ProcessPaymentInput {
        address referrer;
        uint256 usdPrice;
        address user;
        PaymentMethod paymentMethod;
    }

    struct ProcessPaymentOutput {
        PaymentMethod paymentMethod;
        uint256 paymentAmount;
        uint256 burnedAmount;
        uint256 treasuryShare;
    }

    function getRouterAddress() external view returns (address);

    function getTokenFiToken() external view returns (address);

    function getTreasury() external view returns (address);

    function getUsdToken() external view returns (address);

    function processPayment(ProcessPaymentInput memory params) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";

interface ILaunchPadPricing is ILaunchPadCommon {
    function addDiscountNfts(address[] memory newDiscountNFTs, uint256[] memory discountBasisPoints) external;

    function getDiscountNfts() external view returns (address[] memory);

    function getDiscountPercentageForNft(address nft) external view returns (uint256);

    function getFeePercentage() external view returns (uint256);

    function getPrice(address user, LaunchPadType launchPadType) external view returns (uint256); // returns usd value includes the decimals (6)

    function isDiscountNft(address nft) external view returns (bool);

    function removeDiscountNfts(address[] memory discountNFTs) external;

    function setDeployLaunchPadPrice(uint256 newPrice, LaunchPadType launchPadType) external;

    function setFeePercentage(uint256 newFeePercentage) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";

interface ILaunchPadProject {
    struct PurchasedInfo {
        uint256 purchasedTokenAmount;
        uint256 claimedTokenAmount;
        uint256 paidTokenAmount;
    }

    struct BuyTokenInput {
        uint256 tokenAmount;
        uint256 tier;
        uint256 nonce;
        uint256 deadline;
        bytes signature;
    }

    function buyTokens(uint256 tokenAmount) external payable;

    function buyTokensWithSupercharger(BuyTokenInput memory input) external payable;

    function checkSignature(address wallet, uint256 tier, uint256 nonce, uint256 deadline, bytes memory signature) external view;

    function claimTokens() external;

    function getAllInvestors() external view returns (address[] memory);

    function getCurrentTier() external view returns (uint256);

    function getFeeShare() external view returns (uint256);

    function getHardCapPerTier(uint256 tier) external view returns (uint256);

    function getInvestorAddressByIndex(uint256 index) external view returns (address);

    function getInvestorsLength() external view returns (uint256);

    function getLaunchPadAddress() external view returns (address);

    function getLaunchPadInfo() external view returns (ILaunchPadCommon.LaunchPadInfo memory);

    function getMaxInvestPerWalletPerTier(uint256 tier) external view returns (uint256);

    function getNextNonce(address user) external view returns (uint256);

    function getProjectOwnerRole() external view returns (bytes32);

    function getPurchasedInfoByUser(address user) external view returns (PurchasedInfo memory);

    function getReleasedTokensPercentage() external view returns (uint256);

    function getReleaseSchedule() external view returns (ILaunchPadCommon.ReleaseScheduleV2[] memory);

    function getTokensAvailableToBeClaimed(address user) external view returns (uint256);

    function getTokenCreationDeadline() external view returns (uint256);

    function getTotalRaised() external view returns (uint256);

    function isSuperchargerEnabled() external view returns (bool);

    function recoverSigner(bytes32 message, bytes memory signature) external view returns (address);

    function refund(uint256 tokenAmount) external;

    function refundOnSoftCapFailure() external;

    function refundOnTokenCreationExpired(uint256 tokenAmount) external;

    function setSupercharger(bool isSuperchargerEnabled) external;

    function setTokenAddress(address tokenAddress) external;

    function tokenDecimals() external view returns (uint256);

    function totalTokensClaimed() external view returns (uint256);

    function totalTokensSold() external view returns (uint256);

    function withdrawFees() external;

    function withdrawTokens(address tokenAddress) external;

    function withdrawTokensToRecipient(address tokenAddress, address recipient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";

interface ILaunchPadProjectInit {
    function init(ILaunchPadCommon.CreateLaunchPadInput memory input) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibLaunchPadConsts {
    bytes32 internal constant PRODUCT_ID = keccak256("tokenfi.launchpad");
    uint256 internal constant BASIS_POINTS = 10_000;
    uint256 internal constant REFERRER_BASIS_POINTS = 2_500;
    uint256 internal constant BURN_BASIS_POINTS = 5_000;
    address internal constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "../interfaces/ILaunchPadCommon.sol";
import { ILaunchPadFactory } from "../interfaces/ILaunchPadFactory.sol";
import { ILaunchPadProject } from "../interfaces/ILaunchPadProject.sol";

library LibLaunchPadFactoryStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("tokenfi.launchpad.factory.diamond.storage");

    struct DiamondStorage {
        address[] launchPads;
        mapping(address => address[]) launchPadsByOwner;
        mapping(address => address[]) launchPadsByInvestor;
        mapping(address => address) launchPadOwner;
        mapping(address => bool) isLaunchPad;
        mapping(address => ILaunchPadFactory.CreateErc20Input) tokenInfoByLaunchPadAddress;
        uint256 currentBlockLaunchPadCreated;
        uint256 currentBlockLaunchPadOwnerUpdated;
        address tokenLauncherERC20;
        address tokenLauncherStore;
        address tokenLauncherBuybackHandler;
        address launchPadProjectFacet;
        address accessControlFacet;
        address pausableFacet;
        address loupeFacet;
        address proxyFacet;
        address launchPadProjectDiamondInit;
        address signerAddress;
        uint256 maxTokenCreationDeadline;
        uint256[] superChargerMultiplierByTier;
        uint256[] superChargerHeadstartByTier;
        uint256[] superChargerTokensPercByTier;
    }

    event LaunchPadCreated(
        uint256 indexed previousBlock,
        ILaunchPadCommon.LaunchPadType indexed launchPadType,
        address indexed owner,
        ILaunchPadFactory.StoreLaunchPadInput launchPad
    );
    event LaunchPadOwnerUpdated(uint256 indexed previousBlock, address owner, address newOwner);
    event MaxTokenCreationDeadlineUpdated(uint256 indexed previousMaxTokenCreationDeadline, uint256 newMaxTokenCreationDeadline);
    event LaunchpadRemoved(address indexed launchPadAddress, address indexed owner);
    event SignerAddressUpdated(address indexed previousSignerAddress, address indexed newSignerAddress);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    function getLaunchPadProjectSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory functionSelectors = new bytes4[](32);
        functionSelectors[0] = ILaunchPadProject.buyTokens.selector;
        functionSelectors[1] = ILaunchPadProject.buyTokensWithSupercharger.selector;
        functionSelectors[2] = ILaunchPadProject.checkSignature.selector;
        functionSelectors[3] = ILaunchPadProject.claimTokens.selector;
        functionSelectors[4] = ILaunchPadProject.getAllInvestors.selector;
        functionSelectors[5] = ILaunchPadProject.getCurrentTier.selector;
        functionSelectors[6] = ILaunchPadProject.getFeeShare.selector;
        functionSelectors[7] = ILaunchPadProject.getHardCapPerTier.selector;
        functionSelectors[8] = ILaunchPadProject.getInvestorAddressByIndex.selector;
        functionSelectors[9] = ILaunchPadProject.getInvestorsLength.selector;
        functionSelectors[10] = ILaunchPadProject.getLaunchPadAddress.selector;
        functionSelectors[11] = ILaunchPadProject.getLaunchPadInfo.selector;
        functionSelectors[12] = ILaunchPadProject.getMaxInvestPerWalletPerTier.selector;
        functionSelectors[13] = ILaunchPadProject.getProjectOwnerRole.selector;
        functionSelectors[14] = ILaunchPadProject.getPurchasedInfoByUser.selector;
        functionSelectors[15] = ILaunchPadProject.getReleasedTokensPercentage.selector;
        functionSelectors[16] = ILaunchPadProject.getReleaseSchedule.selector;
        functionSelectors[17] = ILaunchPadProject.getTokensAvailableToBeClaimed.selector;
        functionSelectors[18] = ILaunchPadProject.getTokenCreationDeadline.selector;
        functionSelectors[19] = ILaunchPadProject.getTotalRaised.selector;
        functionSelectors[20] = ILaunchPadProject.isSuperchargerEnabled.selector;
        functionSelectors[21] = ILaunchPadProject.recoverSigner.selector;
        functionSelectors[22] = ILaunchPadProject.refund.selector;
        functionSelectors[23] = ILaunchPadProject.refundOnSoftCapFailure.selector;
        functionSelectors[24] = ILaunchPadProject.refundOnTokenCreationExpired.selector;
        functionSelectors[25] = ILaunchPadProject.setTokenAddress.selector;
        functionSelectors[26] = ILaunchPadProject.tokenDecimals.selector;
        functionSelectors[27] = ILaunchPadProject.totalTokensClaimed.selector;
        functionSelectors[28] = ILaunchPadProject.totalTokensSold.selector;
        functionSelectors[29] = ILaunchPadProject.withdrawFees.selector;
        functionSelectors[30] = ILaunchPadProject.withdrawTokens.selector;
        functionSelectors[31] = ILaunchPadProject.withdrawTokensToRecipient.selector;

        return functionSelectors;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "../interfaces/ILaunchPadProject.sol";
import { ILaunchPadProject } from "../interfaces/ILaunchPadProject.sol";

/// @notice storage for LaunchPads created by users

library LibLaunchPadProjectStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("tokenfi.launchpad.project.diamond.storage");
    bytes32 internal constant LAUNCHPAD_OWNER_ROLE = keccak256("LAUNCHPAD_OWNER_ROLE");
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    struct DiamondStorage {
        ILaunchPadCommon.LaunchPadInfo launchPadInfo;
        address launchPadFactory;
        uint256 totalTokensSold;
        uint256 totalTokensClaimed;
        uint256 feePercentage; // in basis points 1e4
        bool feeShareCollected;
        bool isSuperchargerEnabled;
        ILaunchPadCommon.ReleaseSchedule[] releaseSchedule;
        ILaunchPadCommon.ReleaseScheduleV2[] releaseScheduleV2;
        mapping(address => ILaunchPadProject.PurchasedInfo) purchasedInfoByUser;
        address[] investors;
        mapping(address => uint256[]) buyTokenNonces;
    }

    event TokensPurchased(address indexed buyer, uint256 amount);
    event TokensRefunded(address indexed buyer, uint256 amount);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ITokenLauncherERC20 } from "./ITokenLauncherERC20.sol";
import { ITokenLauncherLiquidityPoolFactory } from "./ITokenLauncherLiquidityPoolFactory.sol";

interface ITokenFiERC20 {
    function addExchangePool(address pool) external;
    function addExemptAddress(address account) external;
    function excludeAccount(address account) external;
    function includeAccount(address account) external;
    function isExchangePool(address pool) external view returns (bool);
    function isExcludedFromReflectionRewards(address account) external view returns (bool);
    function isExemptedFromTax(address account) external view returns (bool);
    function mint(address to, uint256 amount) external;
    function reflect(uint256 tAmount) external;
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256);
    function removeExchangePool(address pool) external;
    function removeExemptAddress(address account) external;
    function setBuybackDetails(ITokenLauncherLiquidityPoolFactory.BuyBackDetails memory _buybackDetails) external;
    function tokenFromReflection(uint256 rAmount) external view returns (uint256);
    function totalFees() external view returns (uint256);
    function updateFees(ITokenLauncherERC20.Fees memory _fees) external;
    function updateTokenLauncher(address _newTokenLauncher) external;
    function updateTreasury(address _newTreasury) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ITokenLauncherCommon {
    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }

    enum PaymentMethod {
        NATIVE,
        USD,
        FLOKI
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ITokenLauncherCommon } from "./ITokenLauncherCommon.sol";
import { ITokenLauncherLiquidityPoolFactory } from "./ITokenLauncherLiquidityPoolFactory.sol";

interface ITokenLauncherERC20 is ITokenLauncherCommon {
    struct FeeDetails {
        uint256 percentage;
        bool onlyOnSwaps;
    }

    struct Fees {
        FeeDetails transferFee;
        FeeDetails burn;
        FeeDetails reflection;
        FeeDetails buyback;
    }

    struct CreateErc20Input {
        string name;
        string symbol;
        string logo;
        uint8 decimals;
        uint256 initialSupply;
        uint256 maxSupply;
        address treasury;
        address owner;
        address referrer;
        address tokenStore;
        Fees fees;
        address buybackHandler;
        PaymentMethod paymentMethod;
    }

    function tokenLauncherStore() external returns (address);

    function liquidityPoolFactory() external returns (address);

    function buybackHandler() external returns (address);

    function createErc20(CreateErc20Input memory input) external payable returns (address);

    function createV2LiquidityPool(ITokenLauncherLiquidityPoolFactory.CreateV2Input memory input) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ITokenLauncherLiquidityPoolFactory {
    struct LiquidityPoolDetails {
        address sourceToken;
        address pairedToken;
        uint256 amountSourceToken;
        uint256 amountPairedToken;
        address routerAddress;
    }

    struct LockLPDetails {
        uint256 lockLPTokenPercentage;
        uint256 unlockTimestamp;
        address beneficiary;
        bool isVesting;
    }

    struct BuyBackDetails {
        address pairToken;
        address router;
        uint256 liquidityBasisPoints;
        uint256 priceImpactBasisPoints;
    }

    struct CreateV2Input {
        address owner;
        address treasury;
        LiquidityPoolDetails liquidityPoolDetails;
        LockLPDetails lockLPDetails;
        BuyBackDetails buybackDetails;
    }

    struct CreateV2Output {
        address liquidityPoolToken;
        uint256 liquidity;
    }

    function createV2LiquidityPool(CreateV2Input memory input) external payable returns (CreateV2Output memory);
}