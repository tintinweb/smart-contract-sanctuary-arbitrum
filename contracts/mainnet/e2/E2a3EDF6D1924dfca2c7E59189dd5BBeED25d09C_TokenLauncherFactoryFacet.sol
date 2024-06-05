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
import { IERC1155Internal } from './IERC1155Internal.sol';

/**
 * @title ERC1155 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-1155
 */
interface IERC1155 is IERC1155Internal, IERC165 {
    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    /**
     * @notice query the balances of given tokens held by given addresses
     * @param accounts addresss to query
     * @param ids tokens to query
     * @return token balances
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    /**
     * @notice grant approval to or revoke approval from given operator to spend held tokens
     * @param operator address whose approval status to update
     * @param status whether operator should be considered approved
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice transfer tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice transfer batch of tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to transfer
     * @param data data payload
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155 interface needed by internal functions
 */
interface IERC1155Internal {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
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

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(
        address holder,
        address spender
    ) external view returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { IERC721Internal } from './IERC721Internal.sol';

/**
 * @title ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
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

import { IERC1155Internal } from '../../../interfaces/IERC1155Internal.sol';

/**
 * @title ERC1155 base interface
 */
interface IERC1155BaseInternal is IERC1155Internal {
    error ERC1155Base__ArrayLengthMismatch();
    error ERC1155Base__BalanceQueryZeroAddress();
    error ERC1155Base__NotOwnerOrApproved();
    error ERC1155Base__SelfApproval();
    error ERC1155Base__BurnExceedsBalance();
    error ERC1155Base__BurnFromZeroAddress();
    error ERC1155Base__ERC1155ReceiverRejected();
    error ERC1155Base__ERC1155ReceiverNotImplemented();
    error ERC1155Base__MintToZeroAddress();
    error ERC1155Base__TransferExceedsBalance();
    error ERC1155Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155BaseInternal } from '../base/IERC1155BaseInternal.sol';

/**
 * @title ERC1155 enumerable and aggregate function interface
 */
interface IERC1155Enumerable is IERC1155BaseInternal {
    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function totalHolders(uint256 id) external view returns (uint256);

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function accountsByToken(
        uint256 id
    ) external view returns (address[] memory);

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function tokensByAccount(
        address account
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';

/**
 * @title ERC1155Metadata interface
 */
interface IERC1155Metadata is IERC1155MetadataInternal {
    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function uri(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155Metadata interface needed by internal functions
 */
interface IERC1155MetadataInternal {
    event URI(string value, uint256 indexed tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from '../../../interfaces/IERC20Internal.sol';

/**
 * @title ERC20 base interface
 */
interface IERC20BaseInternal is IERC20Internal {
    error ERC20Base__ApproveFromZeroAddress();
    error ERC20Base__ApproveToZeroAddress();
    error ERC20Base__BurnExceedsBalance();
    error ERC20Base__BurnFromZeroAddress();
    error ERC20Base__InsufficientAllowance();
    error ERC20Base__MintToZeroAddress();
    error ERC20Base__TransferExceedsBalance();
    error ERC20Base__TransferFromZeroAddress();
    error ERC20Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20ExtendedInternal } from './IERC20ExtendedInternal.sol';

/**
 * @title ERC20 extended interface
 */
interface IERC20Extended is IERC20ExtendedInternal {
    /**
     * @notice increase spend amount granted to spender
     * @param spender address whose allowance to increase
     * @param amount quantity by which to increase allowance
     * @return success status (always true; otherwise function will revert)
     */
    function increaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice decrease spend amount granted to spender
     * @param spender address whose allowance to decrease
     * @param amount quantity by which to decrease allowance
     * @return success status (always true; otherwise function will revert)
     */
    function decreaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20BaseInternal } from '../base/IERC20BaseInternal.sol';

/**
 * @title ERC20 extended internal interface
 */
interface IERC20ExtendedInternal is IERC20BaseInternal {
    error ERC20Extended__ExcessiveAllowance();
    error ERC20Extended__InsufficientAllowance();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20MetadataInternal } from './IERC20MetadataInternal.sol';

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata is IERC20MetadataInternal {
    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC20 metadata internal interface
 */
interface IERC20MetadataInternal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC2612Internal } from './IERC2612Internal.sol';

/**
 * @title ERC2612 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 is IERC2612Internal {
    /**
     * @notice return the EIP-712 domain separator unique to contract and chain
     * @return domainSeparator domain separator
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 domainSeparator);

    /**
     * @notice get the current ERC2612 nonce for the given address
     * @return current nonce
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice approve spender to transfer tokens held by owner via signature
     * @dev this function may be vulnerable to approval replay attacks
     * @param owner holder of tokens and signer of permit
     * @param spender beneficiary of approval
     * @param amount quantity of tokens to approve
     * @param v secp256k1 'v' value
     * @param r secp256k1 'r' value
     * @param s secp256k1 's' value
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC2612Internal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Internal } from '../../../interfaces/IERC721Internal.sol';

/**
 * @title ERC721 base interface
 */
interface IERC721BaseInternal is IERC721Internal {
    error ERC721Base__NotOwnerOrApproved();
    error ERC721Base__SelfApproval();
    error ERC721Base__BalanceQueryZeroAddress();
    error ERC721Base__ERC721ReceiverNotImplemented();
    error ERC721Base__InvalidOwner();
    error ERC721Base__MintToZeroAddress();
    error ERC721Base__NonExistentToken();
    error ERC721Base__NotTokenOwner();
    error ERC721Base__TokenAlreadyMinted();
    error ERC721Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC721Enumerable {
    /**
     * @notice get total token supply
     * @return total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice get token of given owner at given internal storage index
     * @param owner token holder to query
     * @param index position in owner's token list to query
     * @return tokenId id of retrieved token
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId);

    /**
     * @notice get token at given internal storage index
     * @param index position in global token list to query
     * @return tokenId id of retrieved token
     */
    function tokenByIndex(
        uint256 index
    ) external view returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721MetadataInternal } from './IERC721MetadataInternal.sol';

/**
 * @title ERC721Metadata interface
 */
interface IERC721Metadata is IERC721MetadataInternal {
    /**
     * @notice get token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721BaseInternal } from '../base/IERC721BaseInternal.sol';

/**
 * @title ERC721Metadata internal interface
 */
interface IERC721MetadataInternal is IERC721BaseInternal {
    error ERC721Metadata__NonExistentToken();
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

import { IPaymentModule } from "./IPaymentModule.sol";

interface ICrossPaymentModule {
    struct CrossPaymentSignatureInput {
        address payer;
        uint256 sourceChainId;
        uint256 paymentIndex;
        bytes signature;
    }

    struct ProcessCrossPaymentOutput {
        bytes32 platformId;
        uint32[] services;
        uint32[] serviceAmounts;
        address spender;
        uint256 destinationChainId;
        address payer;
        uint256 sourceChainId;
        uint256 paymentIndex;
    }

    function updateSignerAddress(address newSignerAddress) external;
    function processCrossPayment(
        IPaymentModule.ProcessPaymentInput memory paymentInput,
        address spender,
        uint256 destinationChainId
    ) external payable returns (uint256);
    function spendCrossPaymentSignature(address spender, ProcessCrossPaymentOutput memory output, bytes memory signature) external;
    function getSignerAddress() external view returns (address);
    function getCrossPaymentOutputByIndex(uint256 paymentIndex) external view returns (ProcessCrossPaymentOutput memory);
    function prefixedMessage(bytes32 hash) external pure returns (bytes32);
    function getHashedMessage(ProcessCrossPaymentOutput memory output) external pure returns (bytes32);
    function recoverSigner(bytes32 message, bytes memory signature) external pure returns (address);
    function checkSignature(ProcessCrossPaymentOutput memory output, bytes memory signature) external view;
    function getChainID() external view returns (uint256);

    /** EVENTS */
    event CrossPaymentProcessed(uint256 indexed previousBlock, uint256 indexed paymentIndex);
    event CrossPaymentSignatureSpent(uint256 indexed previousBlock, uint256 indexed sourceChainId, uint256 indexed paymentIndex);
    event SignerAddressUpdated(address indexed oldSigner, address indexed newSigner);

    /** ERRORS */
    error ProcessCrossPaymentError(string errorMessage);
    error CheckSignatureError(string errorMessage);
    error ProcessCrossPaymentSignatureError(string errorMessage);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IPaymentModule {
    enum PaymentMethod {
        NATIVE,
        USD,
        ALTCOIN
    }

    enum PaymentType {
        NATIVE,
        GIFT,
        CROSSCHAIN
    }

    struct AcceptedToken {
        string name;
        PaymentMethod tokenType;
        address token;
        address router;
        bool isV2Router;
        uint256 slippageTolerance;
    }

    struct ProcessPaymentInput {
        bytes32 platformId;
        uint32[] services;
        uint32[] serviceAmounts;
        address referrer;
        address user;
        address tokenAddress;
    }

    struct ProcessPaymentOutput {
        ProcessPaymentInput processPaymentInput;
        uint256 usdPrice;
        uint256 paymentAmount;
        uint256 burnedAmount;
        uint256 treasuryShare;
        uint256 referrerShare;
    }

    struct ProcessCrossPaymentOutput {
        bytes32 platformId;
        uint32[] services;
        uint32[] serviceAmounts;
        address payer;
        address spender;
        uint256 sourceChainId;
        uint256 destinationChainId;
    }

    // solhint-disable-next-line func-name-mixedcase
    function PAYMENT_PROCESSOR_ROLE() external pure returns (bytes32);
    function adminWithdraw(address tokenAddress, uint256 amount, address treasury) external;
    function setUsdToken(address newUsdToken) external;
    function setRouterAddress(address newRouter) external;
    function addAcceptedToken(AcceptedToken memory acceptedToken) external;
    function removeAcceptedToken(address tokenAddress) external;
    function updateAcceptedToken(AcceptedToken memory acceptedToken) external;
    function setV3PoolFeeForTokenNative(address token, uint24 poolFee) external;
    function getUsdToken() external view returns (address);
    function processPayment(ProcessPaymentInput memory params) external payable returns (uint256);
    function getPaymentByIndex(uint256 paymentIndex) external view returns (ProcessPaymentOutput memory);
    function getQuoteTokenPrice(address token0, address token1) external view returns (uint256 price);
    function getV3PoolFeeForTokenWithNative(address token) external view returns (uint24);
    function isV2Router() external view returns (bool);
    function getRouterAddress() external view returns (address);
    function getAcceptedTokenByAddress(address tokenAddress) external view returns (AcceptedToken memory);
    function getAcceptedTokens() external view returns (address[] memory);

    /** EVENTS */
    event TokenBurned(uint256 indexed tokenBurnedLastBlock, address indexed tokenAddress, uint256 amount);
    event PaymentProcessed(uint256 indexed previousBlock, uint256 indexed paymentIndex);
    event TreasuryAddressUpdated(address indexed oldTreasury, address indexed newTreasury);

    /** ERRORS */
    error ProcessPaymentError(string errorMessage);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
interface IPlatformModule {
    struct Service {
        string name;
        uint256 usdPrice;
    }

    struct Platform {
        string name;
        bytes32 id;
        address owner;
        address treasury;
        uint256 referrerBasisPoints;
        address burnToken;
        uint256 burnBasisPoints;
        bool isDiscountEnabled;
        Service[] services;
    }

    // solhint-disable-next-line func-name-mixedcase
    function PLATFORM_MANAGER_ROLE() external pure returns (bytes32);

    function getPlatformCount() external view returns (uint256);

    function getPlatformIds() external view returns (bytes32[] memory);

    function getPlatformIdByIndex(uint256 index) external view returns (bytes32);

    function getPlatformById(bytes32 platformId) external view returns (IPlatformModule.Platform memory);

    function addPlatform(IPlatformModule.Platform memory platform) external;

    function removePlatform(uint256 index) external;

    function updatePlatform(IPlatformModule.Platform memory platform) external;

    function addPlatformService(bytes32 platformId, IPlatformModule.Service memory service) external;

    function removePlatformService(bytes32 platformId, uint256 serviceId) external;

    function updatePlatformService(bytes32 platformId, uint256 serviceId, IPlatformModule.Service memory service) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibPaymentModuleConsts {
    bytes32 internal constant PAYMENT_PROCESSOR_ROLE = keccak256("PAYMENT_PROCESSOR_ROLE");
    bytes32 internal constant PLATFORM_MANAGER_ROLE = keccak256("PLATFORM_MANAGER_ROLE");
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

import { IAccessControl } from "@solidstate/contracts/access/access_control/IAccessControl.sol";

import { ITokenLauncherFactory } from "../interfaces/ITokenLauncherFactory.sol";
import { ITokenFiErc20 } from "../interfaces/ITokenFiErc20.sol";
import { ITokenFiErc20Init } from "../interfaces/ITokenFiErc20Init.sol";
import { ITokenFiErc721 } from "../interfaces/ITokenFiErc721.sol";
import { ITokenFiErc721Init } from "../interfaces/ITokenFiErc721Init.sol";
import { ITokenFiErc1155 } from "../interfaces/ITokenFiErc1155.sol";
import { ITokenFiErc1155Init } from "../interfaces/ITokenFiErc1155Init.sol";
import { LibTokenLauncherFactoryStorage } from "../libraries/LibTokenLauncherFactoryStorage.sol";
import { LibTokenLauncherConsts } from "../libraries/LibTokenLauncherConsts.sol";
import { IPaymentModule } from "../../common/admin/interfaces/IPaymentModule.sol";
import { ICrossPaymentModule } from "../../common/admin/interfaces/ICrossPaymentModule.sol";
import { IPlatformModule } from "../../common/admin/interfaces/IPlatformModule.sol";
import { LibPaymentModuleConsts } from "../../common/admin/libraries/LibPaymentModuleConsts.sol";
import { IDiamondCut } from "../../common/diamonds/interfaces/IDiamondCut.sol";
import { LibDiamond } from "../../common/diamonds/libraries/LibDiamond.sol";
import { LibDiamondHelpers } from "../../common/diamonds/libraries/LibDiamondHelpers.sol";
import { Diamond } from "../../common/diamonds/Diamond.sol";
import { IDiamondProxy } from "../../common/diamonds/interfaces/IDiamondProxy.sol";

contract TokenLauncherFactoryFacet is ITokenLauncherFactory {
    // solhint-disable-next-line function-max-lines
    function createErc20(CreateErc20Input memory input) external payable override returns (address tokenAddress) {
        uint256 paymentIndex = _processPayment(TokenType.ERC20, input.referrer, input.paymentToken);
        tokenAddress = _createErc20(input, paymentIndex);
    }

    function createErc20WithPaymentSignature(
        CreateErc20Input memory input,
        ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput
    ) external override returns (address tokenAddress) {
        _spendCrossPaymentSignature(TokenType.ERC20, crossPaymentSignatureInput);
        tokenAddress = _createErc20(input, crossPaymentSignatureInput.paymentIndex);
    }

    function _createErc20(CreateErc20Input memory input, uint256 paymentIndex) private returns (address tokenAddress) {
        LibTokenLauncherFactoryStorage.DiamondStorage storage ds = LibTokenLauncherFactoryStorage.diamondStorage();

        // Now let's create a diamond
        tokenAddress = _createTokenDiamond();

        _prepareTokenFiErc20Diamond(tokenAddress, input.tokenInfo);

        // set TokenFiErc20Implementation for etherscan
        IDiamondProxy(tokenAddress).setImplementation(ds.tokenFiErc20Implementation);

        ITokenFiErc20 token = ITokenFiErc20(tokenAddress);

        // set metadata
        token.setName(input.tokenInfo.name);
        token.setSymbol(input.tokenInfo.symbol);
        token.setDecimals(input.tokenInfo.decimals);

        // mint initial supply to treasury if it's not a reflection token
        if (input.tokenInfo.initialSupply > 0) {
            token.mint(input.tokenInfo.treasury, input.tokenInfo.initialSupply);
        }

        // exempt this address as a liquidity factory
        token.addExemptAddress(address(this));
        // exempt the buybackHandler to avoid recursive transfer
        token.addExemptAddress(ds.buybackHandler);

        // set buybackHandler
        token.setBuybackHandler(ds.buybackHandler);
        // grant BUYBACK_CALLER_ROLE to the tokenFiErc20
        IAccessControl(ds.buybackHandler).grantRole(LibTokenLauncherConsts.BUYBACK_CALLER_ROLE, tokenAddress);

        // Log new token into store
        StoreTokenInput memory storeInput = StoreTokenInput({
            tokenAddress: tokenAddress,
            owner: input.tokenInfo.owner,
            referrer: input.referrer,
            paymentIndex: paymentIndex,
            tokenType: TokenType.ERC20
        });
        _addToken(storeInput);
    }

    function createErc721(CreateErc721Input memory input) external payable override returns (address tokenAddress) {
        uint256 paymentIndex = _processPayment(TokenType.ERC721, input.referrer, input.paymentToken);
        tokenAddress = _createErc721(input, paymentIndex);
    }

    function createErc721WithPaymentSignature(
        CreateErc721Input memory input,
        ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput
    ) external override returns (address tokenAddress) {
        _spendCrossPaymentSignature(TokenType.ERC721, crossPaymentSignatureInput);
        tokenAddress = _createErc721(input, crossPaymentSignatureInput.paymentIndex);
    }

    function _createErc721(CreateErc721Input memory input, uint256 paymentIndex) private returns (address tokenAddress) {
        // Now let's create a diamond
        tokenAddress = _createTokenDiamond();

        _prepareTokenFiErc721Diamond(tokenAddress, input.tokenInfo);

        // set TokenFiErc721Implementation for etherscan
        LibTokenLauncherFactoryStorage.DiamondStorage storage ds = LibTokenLauncherFactoryStorage.diamondStorage();
        IDiamondProxy(tokenAddress).setImplementation(ds.tokenFiErc721Implementation);

        // add a new payment platform for the mint payment of the created token
        IPlatformModule.Service[] memory services = new IPlatformModule.Service[](1);
        services[0] = IPlatformModule.Service({ name: "ERC721 Mint", usdPrice: input.publicMintPaymentInfo.usdPrice });
        IPlatformModule.Platform memory platform = IPlatformModule.Platform({
            name: input.tokenInfo.name,
            id: keccak256(abi.encodePacked(tokenAddress)),
            owner: input.tokenInfo.owner,
            treasury: input.publicMintPaymentInfo.treasury,
            referrerBasisPoints: input.publicMintPaymentInfo.referrerBasisPoints,
            burnToken: IPlatformModule(address(this)).getPlatformById(LibTokenLauncherConsts.PRODUCT_ID).burnToken,
            burnBasisPoints: input.publicMintPaymentInfo.burnBasisPoints,
            isDiscountEnabled: false,
            services: services
        });
        IPlatformModule(address(this)).addPlatform(platform);

        // set TokenInfo
        ITokenFiErc721(tokenAddress).setTokenInfo(input.tokenInfo);

        // grant PAYMENT_PROCESSOR_ROLE to the created Token
        IAccessControl(address(this)).grantRole(LibPaymentModuleConsts.PAYMENT_PROCESSOR_ROLE, tokenAddress);

        // Log new token into store
        StoreTokenInput memory storeInput = StoreTokenInput({
            tokenAddress: tokenAddress,
            owner: input.tokenInfo.owner,
            referrer: input.referrer,
            paymentIndex: paymentIndex,
            tokenType: TokenType.ERC721
        });
        _addToken(storeInput);
    }

    function createErc1155(CreateErc1155Input memory input) external payable override returns (address tokenAddress) {
        uint256 paymentIndex = _processPayment(TokenType.ERC1155, input.referrer, input.paymentToken);
        tokenAddress = _createErc1155(input, paymentIndex);
    }

    function createErc1155WithPaymentSignature(
        CreateErc1155Input memory input,
        ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput
    ) external override returns (address tokenAddress) {
        _spendCrossPaymentSignature(TokenType.ERC1155, crossPaymentSignatureInput);
        tokenAddress = _createErc1155(input, crossPaymentSignatureInput.paymentIndex);
    }

    function _createErc1155(CreateErc1155Input memory input, uint256 paymentIndex) private returns (address tokenAddress) {
        // Now let's create a diamond
        tokenAddress = _createTokenDiamond();

        _prepareTokenFiErc1155Diamond(tokenAddress, input.tokenInfo);

        // set TokenFiErc1155Implementation for etherscan
        LibTokenLauncherFactoryStorage.DiamondStorage storage ds = LibTokenLauncherFactoryStorage.diamondStorage();
        IDiamondProxy(tokenAddress).setImplementation(ds.tokenFiErc1155Implementation);

        // add a new payment platform for the mint payment of the created token
        IPlatformModule.Service[] memory services;
        IPlatformModule.Platform memory platform = IPlatformModule.Platform({
            name: input.tokenInfo.name,
            id: keccak256(abi.encodePacked(tokenAddress)),
            owner: tokenAddress,
            treasury: input.publicMintPaymentInfo.treasury,
            referrerBasisPoints: input.publicMintPaymentInfo.referrerBasisPoints,
            burnToken: IPlatformModule(address(this)).getPlatformById(LibTokenLauncherConsts.PRODUCT_ID).burnToken,
            burnBasisPoints: input.publicMintPaymentInfo.burnBasisPoints,
            isDiscountEnabled: false,
            services: services
        });
        IPlatformModule(address(this)).addPlatform(platform);

        // grant PAYMENT_PROCESSOR_ROLE to the created Token
        IAccessControl(address(this)).grantRole(LibPaymentModuleConsts.PAYMENT_PROCESSOR_ROLE, tokenAddress);

        //create initial tokens
        for (uint256 i = 0; i < input.initialTokens.length; i++) {
            ITokenFiErc1155(tokenAddress).createToken(input.initialTokens[i]);
        }

        // Log new token into store
        StoreTokenInput memory storeInput = StoreTokenInput({
            tokenAddress: tokenAddress,
            owner: input.tokenInfo.owner,
            referrer: input.referrer,
            paymentIndex: paymentIndex,
            tokenType: TokenType.ERC1155
        });
        _addToken(storeInput);
    }

    function _spendCrossPaymentSignature(TokenType tokenType, ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput) private {
        // Now let's process the payment
        uint32[] memory services = new uint32[](1);
        services[0] = uint32(tokenType);
        uint32[] memory serviceAmounts = new uint32[](1);
        serviceAmounts[0] = 1;

        ICrossPaymentModule.ProcessCrossPaymentOutput memory processCrossPaymentOutput = ICrossPaymentModule.ProcessCrossPaymentOutput({
            platformId: LibTokenLauncherConsts.PRODUCT_ID,
            services: services,
            serviceAmounts: serviceAmounts,
            spender: msg.sender,
            destinationChainId: ICrossPaymentModule(address(this)).getChainID(),
            payer: crossPaymentSignatureInput.payer,
            sourceChainId: crossPaymentSignatureInput.sourceChainId,
            paymentIndex: crossPaymentSignatureInput.paymentIndex
        });
        ICrossPaymentModule(address(this)).spendCrossPaymentSignature(msg.sender, processCrossPaymentOutput, crossPaymentSignatureInput.signature);
    }

    function _processPayment(TokenType tokenType, address referrer, address paymentToken) private returns (uint256 paymentIndex) {
        // Now let's process the payment
        uint32[] memory services = new uint32[](1);
        services[0] = uint32(tokenType);
        uint32[] memory serviceAmounts = new uint32[](1);
        serviceAmounts[0] = 1;
        IPaymentModule.ProcessPaymentInput memory paymentInput = IPaymentModule.ProcessPaymentInput({
            platformId: LibTokenLauncherConsts.PRODUCT_ID,
            services: services,
            serviceAmounts: serviceAmounts,
            referrer: referrer,
            user: msg.sender,
            tokenAddress: paymentToken
        });
        paymentIndex = IPaymentModule(address(this)).processPayment{ value: msg.value }(paymentInput);
    }

    function _createTokenDiamond() private returns (address tokenAddress) {
        // Create the new Diamond
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        LibDiamond.FacetAddressAndPosition memory diamondCutFacet = diamondStorage.selectorToFacetAndPosition[IDiamondCut.diamondCut.selector];
        tokenAddress = address(new Diamond(address(this), diamondCutFacet.facetAddress));
    }

    function _prepareCommonFacetCuts() private view returns (IDiamondCut.FacetCut[] memory commonFacetCuts) {
        LibTokenLauncherFactoryStorage.DiamondStorage storage ds = LibTokenLauncherFactoryStorage.diamondStorage();

        commonFacetCuts = new IDiamondCut.FacetCut[](5);

        // Add AccessControlFacet
        bytes4[] memory functionSelectors = LibDiamondHelpers.getAccessControlSelectors();
        commonFacetCuts[1] = IDiamondCut.FacetCut({
            facetAddress: ds.accessControlFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        // Add PausableFacet
        functionSelectors = LibDiamondHelpers.getPausableSelectors();
        commonFacetCuts[2] = IDiamondCut.FacetCut({
            facetAddress: ds.pausableFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        // Add DiamondLoupeFacet
        functionSelectors = LibDiamondHelpers.getDiamondLoupeSelectors();
        commonFacetCuts[3] = IDiamondCut.FacetCut({
            facetAddress: ds.loupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        // Add DiamondProxy
        functionSelectors = LibDiamondHelpers.getDiamondProxySelectors();
        commonFacetCuts[4] = IDiamondCut.FacetCut({
            facetAddress: ds.proxyFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
    }

    function _prepareTokenFiErc20Diamond(address tokenFiErc20, ITokenFiErc20.TokenInfo memory input) private {
        LibTokenLauncherFactoryStorage.DiamondStorage storage ds = LibTokenLauncherFactoryStorage.diamondStorage();

        IDiamondCut.FacetCut[] memory cut = _prepareCommonFacetCuts();

        // Add TokenFiErc20Facet
        bytes4[] memory functionSelectors = LibTokenLauncherFactoryStorage.getTokenFiErc20FunctionSelectors();
        cut[0] = IDiamondCut.FacetCut({ facetAddress: ds.tokenFiErc20Facet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });

        // Add Facets to TokenFiErc20 Diamond and initialize it
        bytes memory _calldata = abi.encodeCall(ITokenFiErc20Init.init, input);
        IDiamondCut(tokenFiErc20).diamondCut(cut, ds.tokenFiErc20DiamondInit, _calldata);
    }

    function _prepareTokenFiErc721Diamond(address tokenFiErc721, ITokenFiErc721.TokenInfo memory input) private {
        LibTokenLauncherFactoryStorage.DiamondStorage storage ds = LibTokenLauncherFactoryStorage.diamondStorage();

        IDiamondCut.FacetCut[] memory cut = _prepareCommonFacetCuts();

        // Add TokenFiErc721Facet
        bytes4[] memory functionSelectors = LibTokenLauncherFactoryStorage.getTokenFiErc721FunctionSelectors();

        cut[0] = IDiamondCut.FacetCut({ facetAddress: ds.tokenFiErc721Facet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });

        // Add Facets to TokenFiErc721 Diamond and initialize it
        bytes memory _calldata = abi.encodeCall(ITokenFiErc721Init.init, input);
        IDiamondCut(tokenFiErc721).diamondCut(cut, ds.tokenFiErc721DiamondInit, _calldata);
    }

    function _prepareTokenFiErc1155Diamond(address tokenFiErc1155, ITokenFiErc1155.TokenInfo memory input) private {
        LibTokenLauncherFactoryStorage.DiamondStorage storage ds = LibTokenLauncherFactoryStorage.diamondStorage();

        IDiamondCut.FacetCut[] memory cut = _prepareCommonFacetCuts();

        // Add TokenFiErc1155Facet
        bytes4[] memory functionSelectors = LibTokenLauncherFactoryStorage.getTokenFiErc1155FunctionSelectors();

        cut[0] = IDiamondCut.FacetCut({ facetAddress: ds.tokenFiErc1155Facet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });

        // Add Facets to TokenFiErc1155 Diamond and initialize it
        bytes memory _calldata = abi.encodeCall(ITokenFiErc1155Init.init, input);
        IDiamondCut(tokenFiErc1155).diamondCut(cut, ds.tokenFiErc1155DiamondInit, _calldata);
    }

    function _addToken(StoreTokenInput memory input) private {
        LibTokenLauncherFactoryStorage.DiamondStorage storage ds = LibTokenLauncherFactoryStorage.diamondStorage();

        ds.tokensByOwnerByType[input.tokenType][input.owner].push(input.tokenAddress);
        ds.tokenOwnerByToken[input.tokenAddress] = input.owner;
        ds.tokensByType[input.tokenType].push(input.tokenAddress);
        emit TokenCreated(ds.currentBlockTokenCreated, input);
        ds.currentBlockTokenCreated = block.number;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ICrossPaymentModule } from "../../common/admin/interfaces/ICrossPaymentModule.sol";

interface ITokenFiErc1155 {
    struct TokenInfo {
        string name;
        string symbol;
        string collectionLogo;
        string baseURI;
        bool isPublicMintEnabled;
        bool isAdminMintEnabled;
        address owner;
    }

    struct CreateTokenInput {
        uint256 tokenId;
        uint256 maxSupply;
        uint256 publicMintUsdPrice;
        uint8 decimals;
        string uri;
    }

    function adminMint(address account, uint256 id, uint256 amount) external;
    function setTokenInfo(TokenInfo memory _newTokenInfo) external;
    function createToken(CreateTokenInput memory input) external;
    function setTokenPublicMintPrice(uint256 _tokenId, uint256 _price) external;
    function setTokenUri(uint256 _tokenId, string memory _uri) external;
    function mint(address account, uint256 id, uint256 amount, address paymentToken, address referrer) external payable;
    function mintWithPaymentSignature(
        address account,
        uint256 id,
        uint256 amount,
        ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput
    ) external;
    function tokenInfo() external view returns (TokenInfo memory);
    function maxSupply(uint256 tokenId) external view returns (uint256);
    function decimals(uint256 tokenId) external view returns (uint256);
    function paymentServiceIndexByTokenId(uint256 tokenId) external view returns (uint256);
    function exists(uint256 id) external view returns (bool);
    function getExistingTokenIds() external view returns (uint256[] memory);
    function paymentModule() external view returns (address);

    event TokenInfoUpdated(TokenInfo indexed oldTokenInfo, TokenInfo indexed newTokenInfo);
    event MintPaymentProccessed(address indexed user, uint256 indexed paymentId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ITokenFiErc1155 } from "./ITokenFiErc1155.sol";

interface ITokenFiErc1155Init {
    function init(ITokenFiErc1155.TokenInfo memory input) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ITokenFiErc20 {
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

    struct BuybackDetails {
        address pairToken;
        address router;
        uint256 liquidityBasisPoints;
        uint256 priceImpactBasisPoints;
    }

    struct TokenInfo {
        string name;
        string symbol;
        string logo;
        uint8 decimals;
        uint256 initialSupply;
        uint256 maxSupply;
        address treasury;
        address owner;
        Fees fees;
        BuybackDetails buybackDetails;
    }

    struct TotalReflection {
        uint256 tTotal;
        uint256 rTotal;
        uint256 tFeeTotal;
    }

    struct ReflectionInfo {
        TotalReflection totalReflection;
        mapping(address => uint256) rOwned;
        mapping(address => uint256) tOwned;
        mapping(address => bool) isExcludedFromReflectionRewards;
        address[] excluded;
    }

    /** ONLY ROLES */
    function mint(address to, uint256 amount) external;
    function updateTokenLauncher(address _newTokenLauncher) external;
    function updateTreasury(address _newTreasury) external;
    function setName(string memory name) external;
    function setSymbol(string memory symbol) external;
    function setDecimals(uint8 decimals) external;
    function updateFees(Fees memory _fees) external;
    function setBuybackDetails(BuybackDetails memory _buybackDetails) external;
    function setBuybackHandler(address _newBuybackHandler) external;
    function addExchangePool(address pool) external;
    function removeExchangePool(address pool) external;
    function addExemptAddress(address account) external;
    function removeExemptAddress(address account) external;

    /** VIEW */
    function fees() external view returns (Fees memory);
    function tokenInfo() external view returns (TokenInfo memory);
    function buybackHandler() external view returns (address);
    function isExchangePool(address pool) external view returns (bool);
    function isExemptedFromTax(address account) external view returns (bool);
    function isReflectionToken() external view returns (bool);

    /** REFLECTION Implemetation */
    function reflect(uint256 tAmount) external;
    function excludeAccount(address account) external;
    function includeAccount(address account) external;
    function isExcludedFromReflectionRewards(address account) external view returns (bool);
    function totalReflection() external view returns (TotalReflection memory);
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256);
    function tokenFromReflection(uint256 rAmount) external view returns (uint256);
    function totalFees() external view returns (uint256);

    event ExemptedAdded(address indexed account);
    event ExemptedRemoved(address indexed account);
    event ExchangePoolAdded(address indexed pool);
    event ExchangePoolRemoved(address indexed pool);
    event TokenLauncherUpdated(address indexed oldTokenLauncher, address indexed newTokenLauncher);
    event TransferTax(address indexed account, address indexed receiver, uint256 amount, string indexed taxType);
    event BuybackHandlerUpdated(address indexed oldBuybackHandler, address indexed newBuybackHandler);
    event BuybackDetailsUpdated(address indexed router, address indexed pairToken, uint256 liquidityBasisPoints, uint256 priceImpactBasisPoints);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ITokenFiErc20 } from "./ITokenFiErc20.sol";

interface ITokenFiErc20Init {
    function init(ITokenFiErc20.TokenInfo memory input) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ICrossPaymentModule } from "../../common/admin/interfaces/ICrossPaymentModule.sol";

interface ITokenFiErc721 {
    enum PaymentServices {
        TOKEN_MINT
    }

    struct TokenInfo {
        string name;
        string symbol;
        string collectionLogo;
        string baseURI;
        uint256 maxSupply;
        bool isPublicMintEnabled;
        bool isAdminMintEnabled;
        address owner;
    }

    function adminMint(address _to) external;
    function adminMintBatch(address _to, uint256 _amount) external;
    function setTokenInfo(TokenInfo memory _newTokenInfo) external;
    function setTokenUri(uint256 tokenId, string memory uri) external;
    function mint(address _to, address paymentToken, address referrer) external payable;
    function mintWithPaymentSignature(address _to, ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput) external;
    function mintBatch(address _to, uint256 _amount, address paymentToken, address referrer) external payable;
    function mintBatchWithPaymentSignature(
        address _to,
        uint256 _amount,
        ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput
    ) external;
    function tokenInfo() external view returns (TokenInfo memory);
    function paymentModule() external view returns (address);

    event TokenInfoUpdated(TokenInfo indexed oldTokenInfo, TokenInfo indexed newTokenInfo);
    event MintPaymentProccessed(address indexed user, uint256 indexed paymentId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ITokenFiErc721 } from "./ITokenFiErc721.sol";

interface ITokenFiErc721Init {
    function init(ITokenFiErc721.TokenInfo memory input) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ITokenLauncherCommon {
    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ITokenLauncherCommon } from "./ITokenLauncherCommon.sol";
import { ITokenFiErc20 } from "./ITokenFiErc20.sol";
import { ITokenFiErc721 } from "./ITokenFiErc721.sol";
import { ITokenFiErc1155 } from "./ITokenFiErc1155.sol";
import { ICrossPaymentModule } from "../../common/admin/interfaces/ICrossPaymentModule.sol";

interface ITokenLauncherFactory is ITokenLauncherCommon {
    struct CreateErc20Input {
        ITokenFiErc20.TokenInfo tokenInfo;
        address referrer;
        address paymentToken;
    }

    struct PublicErc721MintPaymentInfo {
        uint256 usdPrice;
        address treasury;
        uint256 burnBasisPoints;
        uint256 referrerBasisPoints;
    }

    struct CreateErc721Input {
        ITokenFiErc721.TokenInfo tokenInfo;
        PublicErc721MintPaymentInfo publicMintPaymentInfo;
        address referrer;
        address paymentToken;
    }

    struct PublicErc1155MintPaymentInfo {
        address treasury;
        uint256 burnBasisPoints;
        uint256 referrerBasisPoints;
    }

    struct CreateErc1155Input {
        ITokenFiErc1155.TokenInfo tokenInfo;
        PublicErc1155MintPaymentInfo publicMintPaymentInfo;
        ITokenFiErc1155.CreateTokenInput[] initialTokens;
        address referrer;
        address paymentToken;
    }

    struct StoreTokenInput {
        address tokenAddress;
        address owner;
        address referrer;
        uint256 paymentIndex;
        TokenType tokenType;
    }

    function createErc20(CreateErc20Input memory input) external payable returns (address tokenAddress);
    function createErc20WithPaymentSignature(
        CreateErc20Input memory input,
        ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput
    ) external returns (address tokenAddress);
    function createErc721(CreateErc721Input memory input) external payable returns (address tokenAddress);
    function createErc721WithPaymentSignature(
        CreateErc721Input memory input,
        ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput
    ) external returns (address tokenAddress);
    function createErc1155(CreateErc1155Input memory input) external payable returns (address tokenAddress);
    function createErc1155WithPaymentSignature(
        CreateErc1155Input memory input,
        ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput
    ) external returns (address tokenAddress);

    /** EVNETS */
    event TokenCreated(uint256 indexed currentBlockTokenCreated, StoreTokenInput input);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibTokenLauncherConsts {
    bytes32 internal constant PRODUCT_ID = keccak256("tokenfi.tokenLauncher");

    // TOKEN LAUNCHER ROLES
    bytes32 internal constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    bytes32 public constant BUYBACK_CALLER_ROLE = keccak256("BUYBACK_CALLER_ROLE");

    uint256 public constant SLIPPAGE_TOLERANCE = 500;
    uint256 public constant REFLECTION_MAX = type(uint256).max / 2;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ITokenLauncherCommon } from "../interfaces/ITokenLauncherCommon.sol";
// ITokenFiErc20
import { IERC20 } from "@solidstate/contracts/interfaces/IERC20.sol";
import { IERC20Extended } from "@solidstate/contracts/token/ERC20/extended/IERC20Extended.sol";
import { IERC20Metadata } from "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";
import { IERC2612 } from "@solidstate/contracts/token/ERC20/permit/IERC2612.sol";
import { ITokenFiErc20 } from "../interfaces/ITokenFiErc20.sol";
// ITokenFiErc721
import { IERC721 } from "@solidstate/contracts/interfaces/IERC721.sol";
import { IERC721Enumerable } from "@solidstate/contracts/token/ERC721/enumerable/IERC721Enumerable.sol";
import { IERC721Metadata } from "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";
import { ITokenFiErc721 } from "../interfaces/ITokenFiErc721.sol";
// ITokenFiErc1155
import { IERC165 } from "@solidstate/contracts/interfaces/IERC165.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { IERC1155Enumerable } from "@solidstate/contracts/token/ERC1155/enumerable/IERC1155Enumerable.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";
import { ITokenFiErc1155 } from "../interfaces/ITokenFiErc1155.sol";

library LibTokenLauncherFactoryStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("tokenfi.tokenlauncher.factory.diamond.storage");

    struct DiamondStorage {
        mapping(ITokenLauncherCommon.TokenType => address[]) tokensByType;
        mapping(ITokenLauncherCommon.TokenType => mapping(address => address[])) tokensByOwnerByType;
        mapping(address => address) tokenOwnerByToken;
        uint256 currentBlockTokenCreated;
        uint256 currentBlockTokenOwnerUpdated;
        address buybackHandler;
        address accessControlFacet;
        address pausableFacet;
        address loupeFacet;
        address proxyFacet;
        address tokenFiErc20Facet;
        address tokenFiErc20DiamondInit;
        address tokenFiErc721Facet;
        address tokenFiErc721DiamondInit;
        address tokenFiErc1155Facet;
        address tokenFiErc1155DiamondInit;
        address tokenFiErc20Implementation;
        address tokenFiErc721Implementation;
        address tokenFiErc1155Implementation;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function getTokenFiErc20FunctionSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](41);

        /** IERC20 selectors */
        selectors[0] = IERC20.totalSupply.selector;
        selectors[1] = IERC20.balanceOf.selector;
        selectors[2] = IERC20.allowance.selector;
        selectors[3] = IERC20.approve.selector;
        selectors[4] = IERC20.transfer.selector;
        selectors[5] = IERC20.transferFrom.selector;

        /** IERC20Extended selectors */

        selectors[6] = IERC20Extended.increaseAllowance.selector;
        selectors[7] = IERC20Extended.decreaseAllowance.selector;

        /** IERC20Metadata selectors */
        selectors[8] = IERC20Metadata.name.selector;
        selectors[9] = IERC20Metadata.symbol.selector;
        selectors[10] = IERC20Metadata.decimals.selector;

        /** IERC2612 selectors */
        selectors[11] = IERC2612.DOMAIN_SEPARATOR.selector;
        selectors[12] = IERC2612.nonces.selector;
        selectors[13] = IERC2612.permit.selector;

        /** ITokenFiErc20 selectors */
        selectors[14] = ITokenFiErc20.mint.selector;
        selectors[15] = ITokenFiErc20.updateTokenLauncher.selector;
        selectors[16] = ITokenFiErc20.updateTreasury.selector;
        selectors[17] = ITokenFiErc20.setName.selector;
        selectors[18] = ITokenFiErc20.setSymbol.selector;
        selectors[19] = ITokenFiErc20.setDecimals.selector;
        selectors[20] = ITokenFiErc20.updateFees.selector;
        selectors[21] = ITokenFiErc20.setBuybackDetails.selector;
        selectors[22] = ITokenFiErc20.setBuybackHandler.selector;
        selectors[23] = ITokenFiErc20.addExchangePool.selector;
        selectors[24] = ITokenFiErc20.removeExchangePool.selector;
        selectors[25] = ITokenFiErc20.addExemptAddress.selector;
        selectors[26] = ITokenFiErc20.removeExemptAddress.selector;
        /** VIEW */
        selectors[27] = ITokenFiErc20.fees.selector;
        selectors[28] = ITokenFiErc20.tokenInfo.selector;
        selectors[29] = ITokenFiErc20.buybackHandler.selector;
        selectors[30] = ITokenFiErc20.isExchangePool.selector;
        selectors[31] = ITokenFiErc20.isExemptedFromTax.selector;
        selectors[32] = ITokenFiErc20.isReflectionToken.selector;

        // Reflection function selectors
        selectors[33] = ITokenFiErc20.reflect.selector;
        selectors[34] = ITokenFiErc20.excludeAccount.selector;
        selectors[35] = ITokenFiErc20.includeAccount.selector;
        selectors[36] = ITokenFiErc20.isExcludedFromReflectionRewards.selector;
        selectors[37] = ITokenFiErc20.totalReflection.selector;
        selectors[38] = ITokenFiErc20.reflectionFromToken.selector;
        selectors[39] = ITokenFiErc20.tokenFromReflection.selector;
        selectors[40] = ITokenFiErc20.totalFees.selector;

        return selectors;
    }

    function getTokenFiErc721FunctionSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](24);

        // IERC165 selectors
        selectors[0] = IERC165.supportsInterface.selector;

        // IERC721 function selectors
        selectors[1] = IERC721.balanceOf.selector;
        selectors[2] = IERC721.ownerOf.selector;
        // selectors[8] = IERC721.safeTransferFrom.selector;
        selectors[3] = IERC721.transferFrom.selector;
        selectors[4] = IERC721.approve.selector;
        selectors[5] = IERC721.getApproved.selector;
        selectors[6] = IERC721.setApprovalForAll.selector;
        selectors[7] = IERC721.isApprovedForAll.selector;

        // IERC721Enumerable selectors
        selectors[8] = IERC721Enumerable.totalSupply.selector;
        selectors[9] = IERC721Enumerable.tokenOfOwnerByIndex.selector;
        selectors[10] = IERC721Enumerable.tokenByIndex.selector;

        // IERC721Metadata selectors
        selectors[11] = IERC721Metadata.name.selector;
        selectors[12] = IERC721Metadata.symbol.selector;
        selectors[13] = IERC721Metadata.tokenURI.selector;

        // ITokenFiErc721 function selectors
        selectors[14] = ITokenFiErc721.adminMint.selector;
        selectors[15] = ITokenFiErc721.adminMintBatch.selector;
        selectors[16] = ITokenFiErc721.setTokenInfo.selector;
        selectors[17] = ITokenFiErc721.setTokenUri.selector;
        selectors[18] = ITokenFiErc721.mint.selector;
        selectors[19] = ITokenFiErc721.mintWithPaymentSignature.selector;
        selectors[20] = ITokenFiErc721.mintBatch.selector;
        selectors[21] = ITokenFiErc721.mintBatchWithPaymentSignature.selector;
        selectors[22] = ITokenFiErc721.tokenInfo.selector;
        selectors[23] = ITokenFiErc721.paymentModule.selector;

        return selectors;
    }

    function getTokenFiErc1155FunctionSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](26);

        // IERC165 selectors
        selectors[0] = IERC165.supportsInterface.selector;

        // IERC1155 selectors
        selectors[1] = IERC1155.balanceOf.selector;
        selectors[2] = IERC1155.balanceOfBatch.selector;
        selectors[3] = IERC1155.isApprovedForAll.selector;
        selectors[4] = IERC1155.setApprovalForAll.selector;
        selectors[5] = IERC1155.safeTransferFrom.selector;
        selectors[6] = IERC1155.safeBatchTransferFrom.selector;

        // IERC1155Enumerable selectors
        selectors[7] = IERC1155Enumerable.totalSupply.selector;
        selectors[8] = IERC1155Enumerable.totalHolders.selector;
        selectors[9] = IERC1155Enumerable.accountsByToken.selector;
        selectors[10] = IERC1155Enumerable.tokensByAccount.selector;

        // IERC1155Metadata selectors
        selectors[11] = IERC1155Metadata.uri.selector;

        // ITokenFiErc1155 selectors
        selectors[12] = ITokenFiErc1155.adminMint.selector;
        selectors[13] = ITokenFiErc1155.setTokenInfo.selector;
        selectors[14] = ITokenFiErc1155.createToken.selector;
        selectors[15] = ITokenFiErc1155.setTokenPublicMintPrice.selector;
        selectors[16] = ITokenFiErc1155.setTokenUri.selector;
        selectors[17] = ITokenFiErc1155.mint.selector;
        selectors[18] = ITokenFiErc1155.mintWithPaymentSignature.selector;
        selectors[19] = ITokenFiErc1155.tokenInfo.selector;
        selectors[20] = ITokenFiErc1155.maxSupply.selector;
        selectors[21] = ITokenFiErc1155.decimals.selector;
        selectors[22] = ITokenFiErc1155.paymentServiceIndexByTokenId.selector;
        selectors[23] = ITokenFiErc1155.exists.selector;
        selectors[24] = ITokenFiErc1155.getExistingTokenIds.selector;
        selectors[25] = ITokenFiErc1155.paymentModule.selector;

        return selectors;
    }
}