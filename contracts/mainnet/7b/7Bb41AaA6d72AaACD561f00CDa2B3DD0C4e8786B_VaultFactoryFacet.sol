// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

import { IERC165 } from './IERC165.sol';

/**
 * @title ERC1155 transfer receiver interface
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @notice validate receipt of ERC1155 transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param id token ID received
     * @param value quantity of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice validate receipt of ERC1155 batch transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param ids token IDs received
     * @param values quantities of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 is IERC165Internal {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC165 interface registration interface
 */
interface IERC165Internal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibCommonConsts {
    uint256 internal constant BASIS_POINTS = 10_000;
    address internal constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /**
        INNER_STRUCT is used for storing inner struct in mappings within diamond storage
     */
    bytes32 internal constant INNER_STRUCT = keccak256("floki.common.consts.inner.struct");
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
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                // solhint-disable-next-line no-inline-assembly
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
        // solhint-disable-next-line no-inline-assembly
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { IAccessControl } from "@solidstate/contracts/access/access_control/AccessControl.sol";

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

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IVaultKey is IERC721Enumerable {
    function mintKey(address to, address vault) external;

    function lastMintedKeyId(address to) external view returns (uint256);

    event VaultKeyMinted(uint256 previousBlock, address indexed to, uint256 indexed tokenId, address indexed vault);
    event VaultKeyTransfer(uint256 previousBlock, address from, address indexed to, uint256 indexed tokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { AccessControlStorage } from "@solidstate/contracts/access/access_control/AccessControlStorage.sol";

import { WhitelistInternal } from "../../common/admin/internal/WhitelistInternal.sol";
import { LibCommonConsts } from "../../common/admin/libraries/LibCommonConsts.sol";

import { IVaultFactory } from "../interfaces/IVaultFactoryV2.sol";
import { IPaymentModule } from "../interfaces/IPaymentModule.sol";
import { ILockerCommon } from "../interfaces/ILockerCommon.sol";
import { IVaultCommon } from "../interfaces/vault/IVaultCommon.sol";
import { IVaultDiamondInit } from "../interfaces/IVaultDiamondInit.sol";
import { LibVaultFactoryStorage } from "../libraries/LibVaultFactoryStorage.sol";
import { LibLockerConsts } from "../libraries/LibLockerConsts.sol";
import { LibVaultFacetsStorage } from "../libraries/LibVaultFacetsStorage.sol";

import { IDiamondCut } from "../../common/diamonds/interfaces/IDiamondCut.sol";
import { LibDiamond } from "../../common/diamonds/libraries/LibDiamond.sol";
import { Diamond } from "../../common/diamonds/Diamond.sol";
import { LibDiamondHelpers } from "../../common/diamonds/libraries/LibDiamondHelpers.sol";
import { IVaultKey } from "../../common/interfaces/IVaultKey.sol";

contract VaultFactoryFacet is IVaultFactory, WhitelistInternal {
    function setMaxTokensPerVault(uint256 newMax) external onlyAdmin {
        LibVaultFactoryStorage.DiamondStorage storage ds = LibVaultFactoryStorage.diamondStorage();
        uint256 oldMax = ds.maxTokensPerVault;
        ds.maxTokensPerVault = newMax;
        emit ILockerCommon.MaxTokensUpdated(oldMax, newMax);
    }

    function createVault(ILockerCommon.CreateVaultInput calldata input) external payable override onlyWhitelisted(msg.sender, LibLockerConsts.PRODUCT_ID) {
        LibVaultFactoryStorage.DiamondStorage storage ds = LibVaultFactoryStorage.diamondStorage();
        require(input.unlockTimestamp >= block.timestamp, "VaultFactory:createVault:UNLOCK_IN_PAST");
        require(
            input.fungibleTokenDeposits.length > 0 || input.nonFungibleTokenDeposits.length > 0 || input.multiTokenDeposits.length > 0,
            "VaultFactory:createVault:NO_DEPOSITS"
        );
        require(
            input.fungibleTokenDeposits.length + input.nonFungibleTokenDeposits.length + input.multiTokenDeposits.length < ds.maxTokensPerVault,
            "VaultFactory:createVault:MAX_DEPOSITS_EXCEEDED"
        );
        require(msg.sender != input.referrer, "VaultFactory:createVault:SELF_REFERRAL");
        require(input.beneficiary != input.referrer, "VaultFactory:createVault:REFERRER_IS_BENEFICIARY");
        for (uint256 i = 0; i < input.fungibleTokenDeposits.length; i++) {
            require(input.fungibleTokenDeposits[i].amount > 0, "VaultFactory:createVault:ZERO_DEPOSIT");
        }
        for (uint256 i = 0; i < input.multiTokenDeposits.length; i++) {
            require(input.multiTokenDeposits[i].amount > 0, "VaultFactory:createVault:ZERO_DEPOSIT");
        }
        if (input.isVesting) {
            require(input.nonFungibleTokenDeposits.length == 0 && input.multiTokenDeposits.length == 0, "VaultFactory:createVault:ONLY_FUNGIBLE_VESTING");
        }

        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        LibDiamond.FacetAddressAndPosition memory diamondCutFacet = diamondStorage.selectorToFacetAndPosition[IDiamondCut.diamondCut.selector];
        address vault = address(new Diamond(address(this), diamondCutFacet.facetAddress));

        _prepareVaultDiamond(vault, input);

        uint256 keyId = 0;
        if (input.shouldMintKey) {
            IVaultKey(ds.vaultKey).mintKey(input.beneficiary, vault);
            keyId = IVaultKey(ds.vaultKey).lastMintedKeyId(input.beneficiary);
            IVaultCommon(vault).setMintedKey(keyId);
            ds.vaultByKey[keyId] = vault;
        }

        IPaymentModule(address(this)).processPaymentForLocker{ value: msg.value }(
            IPaymentModule.ProcessPaymentParams({
                vault: vault,
                user: msg.sender,
                referrer: input.referrer,
                fungibleTokenDeposits: input.fungibleTokenDeposits,
                nonFungibleTokenDeposits: input.nonFungibleTokenDeposits,
                multiTokenDeposits: input.multiTokenDeposits,
                isVesting: input.isVesting
            })
        );

        _notifyVaultCreated(input, vault, keyId);
    }

    function burn(ILockerCommon.BurnInput calldata input) external payable override onlyWhitelisted(msg.sender, LibLockerConsts.PRODUCT_ID) {
        require(
            input.fungibleTokenDeposits.length > 0 || input.nonFungibleTokenDeposits.length > 0 || input.multiTokenDeposits.length > 0,
            "VaultFactory:createVault:NO_DEPOSITS"
        );
        LibVaultFactoryStorage.DiamondStorage storage ds = LibVaultFactoryStorage.diamondStorage();
        require(
            input.fungibleTokenDeposits.length + input.nonFungibleTokenDeposits.length + input.multiTokenDeposits.length < ds.maxTokensPerVault,
            "VaultFactory:createVault:MAX_DEPOSITS_EXCEEDED"
        );
        require(msg.sender != input.referrer, "VaultFactory:createVault:SELF_REFERRAL");
        for (uint256 i = 0; i < input.fungibleTokenDeposits.length; i++) {
            require(input.fungibleTokenDeposits[i].amount > 0, "VaultFactory:createVault:ZERO_DEPOSIT");
        }
        for (uint256 i = 0; i < input.multiTokenDeposits.length; i++) {
            require(input.multiTokenDeposits[i].amount > 0, "VaultFactory:createVault:ZERO_DEPOSIT");
        }

        IPaymentModule(address(this)).processPaymentForLocker{ value: msg.value }(
            IPaymentModule.ProcessPaymentParams({
                vault: LibCommonConsts.BURN_ADDRESS,
                user: msg.sender,
                referrer: input.referrer,
                fungibleTokenDeposits: input.fungibleTokenDeposits,
                nonFungibleTokenDeposits: input.nonFungibleTokenDeposits,
                multiTokenDeposits: input.multiTokenDeposits,
                isVesting: false
            })
        );

        emit ILockerCommon.TokensBurned(
            ds.vaultBurnedLastBlock,
            msg.sender,
            input.referrer,
            input.fungibleTokenDeposits,
            input.nonFungibleTokenDeposits,
            input.multiTokenDeposits
        );
        ds.vaultBurnedLastBlock = block.number;
    }

    function _prepareVaultDiamond(address vault, ILockerCommon.CreateVaultInput memory input) internal {
        LibVaultFacetsStorage.DiamondStorage storage ds = LibVaultFacetsStorage.diamondStorage();

        IDiamondCut.FacetCut[] memory cut;
        bytes4[] memory functionSelectors;

        // Add FungibleVault or FungibleVestingVault
        if (input.fungibleTokenDeposits.length > 0) {
            cut = new IDiamondCut.FacetCut[](1);
            if (input.isVesting) {
                // Add FungibleVestingVault
                functionSelectors = LibVaultFacetsStorage.getFungibleVestingVaultSelectors();
                cut[0] = IDiamondCut.FacetCut({
                    facetAddress: ds.fungibleVestingVaultFacet,
                    action: IDiamondCut.FacetCutAction.Add,
                    functionSelectors: functionSelectors
                });
            } else {
                // Add FungibleVault
                functionSelectors = LibVaultFacetsStorage.getFungibleVaultSelectors();
                cut[0] = IDiamondCut.FacetCut({
                    facetAddress: ds.fungibleVaultFacet,
                    action: IDiamondCut.FacetCutAction.Add,
                    functionSelectors: functionSelectors
                });
            }
            IDiamondCut(vault).diamondCut(cut, address(0), "");
        }

        // Add NftVault
        if (input.nonFungibleTokenDeposits.length > 0) {
            cut = new IDiamondCut.FacetCut[](1);
            functionSelectors = LibVaultFacetsStorage.getNftVaultSelectors();
            cut[0] = IDiamondCut.FacetCut({ facetAddress: ds.nftVaultFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });
            IDiamondCut(vault).diamondCut(cut, address(0), "");
        }

        // Add MultiTokenVault
        if (input.multiTokenDeposits.length > 0) {
            cut = new IDiamondCut.FacetCut[](1);
            functionSelectors = LibVaultFacetsStorage.getMultiTokenVaultSelectors();
            cut[0] = IDiamondCut.FacetCut({
                facetAddress: ds.multiTokenVaultFacet,
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            });
            IDiamondCut(vault).diamondCut(cut, address(0), "");
        }

        cut = new IDiamondCut.FacetCut[](5);
        // Add VaultCommon
        functionSelectors = LibVaultFacetsStorage.getVaultCommonSelectors();
        cut[0] = IDiamondCut.FacetCut({ facetAddress: ds.vaultCommonFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });

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

        // cut common facets
        IDiamondCut(vault).diamondCut(cut, address(0), "");

        // Initialize Diamond
        cut = new IDiamondCut.FacetCut[](0);
        bytes memory _calldata = abi.encodeCall(IVaultDiamondInit.init, input);
        IDiamondCut(vault).diamondCut(cut, ds.vaultDiamondInit, _calldata);
    }

    function _notifyVaultCreated(ILockerCommon.CreateVaultInput memory input, address vault, uint256 keyId) internal {
        LibVaultFactoryStorage.DiamondStorage storage ds = LibVaultFactoryStorage.diamondStorage();
        ds.vaultStatus[vault] = ILockerCommon.VaultStatus.Locked;

        emit ILockerCommon.VaultCreated(
            ds.vaultCreatedLastBlock,
            vault,
            keyId,
            msg.sender,
            input.beneficiary,
            input.referrer,
            input.unlockTimestamp,
            input.fungibleTokenDeposits,
            input.nonFungibleTokenDeposits,
            input.multiTokenDeposits,
            input.isVesting
        );
        ds.vaultCreatedLastBlock = block.number;
    }

    function notifyUnlock(bool isCompletelyUnlocked) external override {
        LibVaultFactoryStorage.DiamondStorage storage ds = LibVaultFactoryStorage.diamondStorage();
        require(ds.vaultStatus[msg.sender] == ILockerCommon.VaultStatus.Locked, "VaultFactory:notifyUnlock:ALREADY_FULL_UNLOCKED");

        if (isCompletelyUnlocked) {
            ds.vaultStatus[msg.sender] = ILockerCommon.VaultStatus.Unlocked;
        }

        emit ILockerCommon.VaultUnlocked(ds.vaultUnlockedLastBlock, msg.sender, block.timestamp, isCompletelyUnlocked);
        ds.vaultUnlockedLastBlock = block.number;
    }

    function lockExtended(uint256 oldUnlockTimestamp, uint256 newUnlockTimestamp) external override {
        LibVaultFactoryStorage.DiamondStorage storage ds = LibVaultFactoryStorage.diamondStorage();
        require(ds.vaultStatus[msg.sender] == ILockerCommon.VaultStatus.Locked, "VaultFactory:lockExtended:ALREADY_FULL_UNLOCKED");
        emit ILockerCommon.VaultLockExtended(ds.vaultExtendedLastBlock, msg.sender, oldUnlockTimestamp, newUnlockTimestamp);
        ds.vaultExtendedLastBlock = block.number;
    }

    function mintKey(address vaultAddress) external {
        address beneficiary = IVaultCommon(vaultAddress).getBeneficiary();
        require(msg.sender == beneficiary, "VaultDeployer: Only beneficiary can mint key");
        LibVaultFactoryStorage.DiamondStorage storage ds = LibVaultFactoryStorage.diamondStorage();
        IVaultKey(ds.vaultKey).mintKey(beneficiary, vaultAddress);
        IVaultCommon(vaultAddress).setMintedKey(IVaultKey(ds.vaultKey).lastMintedKeyId(beneficiary));
    }

    modifier onlyAdmin() {
        require(_hasRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, msg.sender), "VaultFactory: Only admin can call this function");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ILockerCommon {
    struct FungibleTokenDeposit {
        address tokenAddress;
        uint256 amount;
        bool isLP;
    }

    struct NonFungibleTokenDeposit {
        address tokenAddress;
        uint256 tokenId;
    }

    struct MultiTokenDeposit {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
    }

    struct V3LPData {
        address tokenAddress;
        address token0;
        address token1;
        uint128 liquidityToRemove;
        uint24 fee;
    }

    enum VaultStatus {
        Inactive,
        Locked,
        Unlocked
    }

    struct CreateVaultInput {
        address beneficiary;
        uint256 unlockTimestamp;
        address referrer;
        ILockerCommon.FungibleTokenDeposit[] fungibleTokenDeposits;
        ILockerCommon.NonFungibleTokenDeposit[] nonFungibleTokenDeposits;
        ILockerCommon.MultiTokenDeposit[] multiTokenDeposits;
        bool isVesting;
        bool shouldMintKey;
    }

    struct BurnInput {
        address referrer;
        ILockerCommon.FungibleTokenDeposit[] fungibleTokenDeposits;
        ILockerCommon.NonFungibleTokenDeposit[] nonFungibleTokenDeposits;
        ILockerCommon.MultiTokenDeposit[] multiTokenDeposits;
    }

    event MaxTokensUpdated(uint256 indexed oldMax, uint256 indexed newMax);
    event VaultUnlocked(uint256 previousBlock, address indexed vault, uint256 timestamp, bool isCompletelyUnlocked);

    event VaultCreated(
        uint256 previousBlock,
        address indexed vault,
        uint256 key,
        address benefactor,
        address indexed beneficiary,
        address indexed referrer,
        uint256 unlockTimestamp,
        ILockerCommon.FungibleTokenDeposit[] fungibleTokenDeposits,
        ILockerCommon.NonFungibleTokenDeposit[] nonFungibleTokenDeposits,
        ILockerCommon.MultiTokenDeposit[] multiTokenDeposits,
        bool isVesting
    );

    event TokensBurned(
        uint256 indexed previousBlock,
        address indexed benefactor,
        address indexed referrer,
        ILockerCommon.FungibleTokenDeposit[] fungibleTokenDeposits,
        ILockerCommon.NonFungibleTokenDeposit[] nonFungibleTokenDeposits,
        ILockerCommon.MultiTokenDeposit[] multiTokenDeposits
    );

    event VaultLockExtended(uint256 indexed previousBlock, address indexed vault, uint256 oldUnlockTimestamp, uint256 newUnlockTimestamp);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILockerCommon } from "./ILockerCommon.sol";

interface IPaymentModule {
    struct PaymentHolder {
        address tokenAddress;
        uint256 amount;
        uint256 payment;
    }

    struct ProcessPaymentParams {
        address vault;
        address user;
        address referrer;
        ILockerCommon.FungibleTokenDeposit[] fungibleTokenDeposits;
        ILockerCommon.NonFungibleTokenDeposit[] nonFungibleTokenDeposits;
        ILockerCommon.MultiTokenDeposit[] multiTokenDeposits;
        bool isVesting;
    }

    function convertNativeFeeToUsd() external view returns (bool);

    function processPaymentForLocker(ProcessPaymentParams memory params) external payable;

    function setConvertNativeFeeToUsd(bool convert) external;

    function setPriceOracleManager(address newPriceOracleManager) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILockerCommon } from "../interfaces/ILockerCommon.sol";

interface IVaultDiamondInit {
    function init(ILockerCommon.CreateVaultInput memory _input) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILockerCommon } from "./ILockerCommon.sol";

interface IVaultFactory {
    function createVault(ILockerCommon.CreateVaultInput calldata input) external payable;

    function burn(ILockerCommon.BurnInput calldata input) external payable;

    function notifyUnlock(bool isCompletelyUnlocked) external;

    function lockExtended(uint256 oldUnlockTimestamp, uint256 newUnlockTimestamp) external;

    function mintKey(address vaultAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IFungibleVault {
    function partialFungibleTokenUnlock(address _tokenAddress, uint256 _tokenAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IFungibleVestingVault {
    function getTokenAvailability(address tokenAddress) external view returns (uint256);
    function partialVest(address _tokenAddress) external;
    function vest() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IMultiTokenVault {
    function partialMultiTokenUnlock(address _tokenAddress, uint256 _tokenId, uint256 _tokenAmount, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface INftVault {
    function collectV3PositionFees(address tokenAddress, uint256 tokenId) external;

    function reinvestV3PositionFees(address tokenAddress, uint256 tokenId, uint256 amount0Min, uint256 amount1Min) external;

    function partialNonFungibleTokenUnlock(address _tokenAddress, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { IERC721Receiver } from "@solidstate/contracts/interfaces/IERC721Receiver.sol";
import { IERC1155Receiver } from "@solidstate/contracts/interfaces/IERC1155Receiver.sol";

interface IVaultCommon is IERC721Receiver, IERC1155Receiver {
    function extendLock(uint256 newUnlockTimestamp) external;

    function getBeneficiary() external view returns (address);

    function setMintedKey(uint256 keyId) external;

    function unlock(bytes memory erc1155TransferData) external;

    function vaultKeyId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibLockerConsts {
    bytes32 internal constant PRODUCT_ID = keccak256("flokifi.locker");
    uint256 internal constant BURN_BASIS_POINTS = 2_500; // 25%
    uint256 internal constant REFERRER_BASIS_POINTS = 2_500; // 25%

    bytes32 internal constant TOKEN_SWAPPER_ADMIN_ROLE = keccak256("TOKEN_SWAPPER_ADMIN_ROLE");
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { IFungibleVault } from "../interfaces/vault/IFungibleVault.sol";
import { IFungibleVestingVault } from "../interfaces/vault/IFungibleVestingVault.sol";
import { IMultiTokenVault } from "../interfaces/vault/IMultiTokenVault.sol";
import { INftVault } from "../interfaces/vault/INftVault.sol";
import { IVaultCommon, IERC721Receiver, IERC1155Receiver } from "../interfaces/vault/IVaultCommon.sol";

library LibVaultFacetsStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("flokifi.locker.vaultfacets.diamond.storage");

    struct DiamondStorage {
        // facets to be plugged into vault diamonds
        address fungibleVaultFacet;
        address fungibleVestingVaultFacet;
        address multiTokenVaultFacet;
        address nftVaultFacet;
        address vaultCommonFacet;
        address accessControlFacet;
        address pausableFacet;
        address loupeFacet;
        address proxyFacet;
        address vaultDiamondInit;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    function getVaultCommonSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory functionSelectors = new bytes4[](8);
        functionSelectors[0] = IVaultCommon.getBeneficiary.selector;
        functionSelectors[1] = IVaultCommon.extendLock.selector;
        functionSelectors[2] = IVaultCommon.unlock.selector;
        functionSelectors[3] = IVaultCommon.setMintedKey.selector;
        functionSelectors[4] = IVaultCommon.vaultKeyId.selector;
        functionSelectors[5] = IERC721Receiver.onERC721Received.selector;
        functionSelectors[6] = IERC1155Receiver.onERC1155Received.selector;
        functionSelectors[7] = IERC1155Receiver.onERC1155BatchReceived.selector;
        return functionSelectors;
    }

    function getFungibleVaultSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IFungibleVault.partialFungibleTokenUnlock.selector;
        return functionSelectors;
    }

    function getFungibleVestingVaultSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory functionSelectors = new bytes4[](3);
        functionSelectors[0] = IFungibleVestingVault.getTokenAvailability.selector;
        functionSelectors[2] = IFungibleVestingVault.partialVest.selector;
        functionSelectors[3] = IFungibleVestingVault.vest.selector;
        return functionSelectors;
    }

    function getMultiTokenVaultSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IMultiTokenVault.partialMultiTokenUnlock.selector;
        return functionSelectors;
    }

    function getNftVaultSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory functionSelectors = new bytes4[](3);
        functionSelectors[0] = INftVault.collectV3PositionFees.selector;
        functionSelectors[1] = INftVault.reinvestV3PositionFees.selector;
        functionSelectors[2] = INftVault.partialNonFungibleTokenUnlock.selector;
        return functionSelectors;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILockerCommon } from "../interfaces/ILockerCommon.sol";

library LibVaultFactoryStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("flokifi.locker.factory.diamond.storage");

    struct DiamondStorage {
        mapping(uint256 => address) vaultByKey;
        mapping(address => ILockerCommon.VaultStatus) vaultStatus;
        address vaultKey;
        uint256 maxTokensPerVault;
        uint256 vaultUnlockedLastBlock;
        uint256 vaultCreatedLastBlock;
        uint256 vaultExtendedLastBlock;
        uint256 vaultBurnedLastBlock;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }
}