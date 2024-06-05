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

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ILaunchPadFactory, ILaunchPadCommon } from "../interfaces/ILaunchPadFactory.sol";
import { ILaunchPadProjectInit } from "../interfaces/ILaunchPadProjectInit.sol";
import { LibLaunchPadFactoryStorage } from "../libraries/LibLaunchPadFactoryStorage.sol";
import { LibLaunchPadConsts } from "../libraries/LibLaunchPadConsts.sol";
import { IPaymentModule } from "../../common/admin/interfaces/IPaymentModule.sol";
import { ICrossPaymentModule } from "../../common/admin/interfaces/ICrossPaymentModule.sol";
import { IDiamondCut } from "../../common/diamonds/interfaces/IDiamondCut.sol";
import { LibDiamond } from "../../common/diamonds/libraries/LibDiamond.sol";
import { LibDiamondHelpers } from "../../common/diamonds/libraries/LibDiamondHelpers.sol";
import { Diamond } from "../../common/diamonds/Diamond.sol";
import { ITokenLauncherFactory } from "../../token-launcher/interfaces/ITokenLauncherFactory.sol";
import { ITokenFiErc20 } from "../../token-launcher/interfaces/ITokenFiErc20.sol";
import { WhitelistInternal } from "../../common/admin/internal/WhitelistInternal.sol";
import { IDiamondProxy } from "../../common/diamonds/interfaces/IDiamondProxy.sol";

contract LaunchPadFactoryFacet is ILaunchPadFactory, WhitelistInternal {
    function addInvestorToLaunchPad(address investor) external override {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        // Can only be called by a launchpad contract
        require(ds.isLaunchPad[msg.sender], "LaunchPadFactoryFacet:addInvestorToLaunchPad: LaunchPad does not exist");
        ds.launchPadsByInvestor[investor].push(msg.sender);
    }

    // solhint-disable-next-line function-max-lines
    function _createLaunchPad(ILaunchPadCommon.CreateLaunchPadInput memory storeInput) private {
        if (storeInput.launchPadType == ILaunchPadCommon.LaunchPadType.FlokiPadCreatedBefore) {
            // create a TokenFiErc20 token by using TokenLauncherFactory
            // payment would be ignored because launchpad factory has a discount NFT

            address tokenAddress = ITokenLauncherFactory(address(this)).createErc20(
                ITokenLauncherFactory.CreateErc20Input({
                    tokenInfo: ITokenFiErc20.TokenInfo({
                        name: storeInput.createErc20Input.name,
                        symbol: storeInput.createErc20Input.symbol,
                        logo: storeInput.createErc20Input.logo,
                        decimals: storeInput.createErc20Input.decimals,
                        initialSupply: storeInput.launchPadInfo.fundTarget.hardCap + storeInput.createErc20Input.treasuryReserved,
                        maxSupply: storeInput.createErc20Input.maxSupply,
                        treasury: address(this),
                        owner: storeInput.createErc20Input.owner,
                        fees: ITokenFiErc20.Fees({
                            transferFee: ITokenFiErc20.FeeDetails({ percentage: 0, onlyOnSwaps: false }),
                            burn: ITokenFiErc20.FeeDetails({ percentage: 0, onlyOnSwaps: false }),
                            reflection: ITokenFiErc20.FeeDetails({ percentage: 0, onlyOnSwaps: false }),
                            buyback: ITokenFiErc20.FeeDetails({ percentage: 0, onlyOnSwaps: false })
                        }),
                        buybackDetails: ITokenFiErc20.BuybackDetails({
                            pairToken: address(0),
                            router: address(0),
                            liquidityBasisPoints: 0,
                            priceImpactBasisPoints: 0
                        })
                    }),
                    referrer: storeInput.referrer,
                    paymentToken: address(0)
                })
            );

            storeInput.launchPadInfo.tokenAddress = tokenAddress;
        } else if (storeInput.launchPadType == ILaunchPadCommon.LaunchPadType.FlokiPadCreatedAfter) {
            // create a TokenFiErc20 token by using TokenLauncherFactory after ICO by the launchpad owner
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

        // Create the new LaunchPad
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        LibDiamond.FacetAddressAndPosition memory diamondCutFacet = diamondStorage.selectorToFacetAndPosition[IDiamondCut.diamondCut.selector];
        address launchPad = address(new Diamond(address(this), diamondCutFacet.facetAddress));

        _prepareLaunchPadDiamond(launchPad, storeInput);

        // set LaunchpadImplementation for etherscan
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        IDiamondProxy(launchPad).setImplementation(ds.launchPadImplementation);

        // Transfer token to the launchpad and treasury address
        if (storeInput.launchPadType == ILaunchPadCommon.LaunchPadType.FlokiPadCreatedBefore) {
            IERC20(storeInput.launchPadInfo.tokenAddress).transfer(address(launchPad), storeInput.launchPadInfo.fundTarget.hardCap);
            if (storeInput.createErc20Input.treasuryReserved > 0) {
                IERC20(storeInput.launchPadInfo.tokenAddress).transfer(storeInput.createErc20Input.owner, storeInput.createErc20Input.treasuryReserved);
            }
        }

        // Log new launchPad into store
        _addLaunchPad(storeInput, launchPad);
    }

    function createLaunchPad(
        ILaunchPadCommon.CreateLaunchPadInput memory storeInput
    ) external payable override onlyWhitelisted(msg.sender, LibLaunchPadConsts.PRODUCT_ID) {
        // Now let's process the payment
        uint32[] memory services = new uint32[](1);
        services[0] = uint32(storeInput.launchPadType);
        uint32[] memory serviceAmounts = new uint32[](1);
        serviceAmounts[0] = 1;
        IPaymentModule.ProcessPaymentInput memory paymentInput = IPaymentModule.ProcessPaymentInput({
            platformId: LibLaunchPadConsts.PRODUCT_ID,
            services: services,
            serviceAmounts: serviceAmounts,
            referrer: storeInput.referrer,
            user: msg.sender,
            tokenAddress: storeInput.paymentTokenAddress
        });
        IPaymentModule(address(this)).processPayment{ value: msg.value }(paymentInput);

        _createLaunchPad(storeInput);
    }

    function createLaunchPadWithPaymentSignature(
        ILaunchPadCommon.CreateLaunchPadInput memory storeInput,
        ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput
    ) external override onlyWhitelisted(msg.sender, LibLaunchPadConsts.PRODUCT_ID) {
        // Now let's process the payment
        uint32[] memory services = new uint32[](1);
        services[0] = uint32(storeInput.launchPadType);
        uint32[] memory serviceAmounts = new uint32[](1);
        serviceAmounts[0] = 1;

        ICrossPaymentModule.ProcessCrossPaymentOutput memory processCrossPaymentOutput = ICrossPaymentModule.ProcessCrossPaymentOutput({
            platformId: LibLaunchPadConsts.PRODUCT_ID,
            services: services,
            serviceAmounts: serviceAmounts,
            spender: msg.sender,
            destinationChainId: ICrossPaymentModule(address(this)).getChainID(),
            payer: crossPaymentSignatureInput.payer,
            sourceChainId: crossPaymentSignatureInput.sourceChainId,
            paymentIndex: crossPaymentSignatureInput.paymentIndex
        });
        ICrossPaymentModule(address(this)).spendCrossPaymentSignature(msg.sender, processCrossPaymentOutput, crossPaymentSignatureInput.signature);

        _createLaunchPad(storeInput);
    }

    function _addLaunchPad(ILaunchPadCommon.CreateLaunchPadInput memory input, address launchPad) private {
        require(input.launchPadInfo.owner != address(0), "LaunchPadFactory: Owner cannot be 0");
        ILaunchPadFactory.StoreLaunchPadInput memory storeInput = ILaunchPadFactory.StoreLaunchPadInput({
            launchPadType: input.launchPadType,
            launchPadAddress: launchPad,
            owner: input.launchPadInfo.owner,
            referrer: input.referrer
        });

        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();

        ds.launchPadsByOwner[storeInput.owner].push(storeInput.launchPadAddress);
        ds.launchPads.push(storeInput.launchPadAddress);
        ds.isLaunchPad[storeInput.launchPadAddress] = true;
        ds.launchPadOwner[storeInput.launchPadAddress] = storeInput.owner;
        ds.tokenInfoByLaunchPadAddress[storeInput.launchPadAddress] = input.createErc20Input;
        emit LibLaunchPadFactoryStorage.LaunchPadCreated(ds.currentBlockLaunchPadCreated, storeInput);
        ds.currentBlockLaunchPadCreated = block.number;
    }

    function _prepareLaunchPadDiamond(address launchPad, ILaunchPadCommon.CreateLaunchPadInput memory input) private {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](6);

        // Add LaunchPadProjectFacet
        bytes4[] memory functionSelectors = LibLaunchPadFactoryStorage.getLaunchPadProjectSelectors();

        cut[0] = IDiamondCut.FacetCut({ facetAddress: ds.launchPadProjectFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });

        // Add LaunchPadProjectAdminFacet
        functionSelectors = LibLaunchPadFactoryStorage.getLaunchPadProjectAdminSelectors();

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: ds.launchPadProjectAdminFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        // Add AccessControlFacet
        functionSelectors = LibDiamondHelpers.getAccessControlSelectors();
        cut[2] = IDiamondCut.FacetCut({ facetAddress: ds.accessControlFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });

        // Add PausableFacet
        functionSelectors = LibDiamondHelpers.getPausableSelectors();
        cut[3] = IDiamondCut.FacetCut({ facetAddress: ds.pausableFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });

        // Add DiamondLoupeFacet
        functionSelectors = LibDiamondHelpers.getDiamondLoupeSelectors();
        cut[4] = IDiamondCut.FacetCut({ facetAddress: ds.loupeFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });

        // Add DiamondProxy
        functionSelectors = LibDiamondHelpers.getDiamondProxySelectors();
        cut[5] = IDiamondCut.FacetCut({ facetAddress: ds.proxyFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });

        // Add Facets to LaunchPad Diamond and initialize it
        bytes memory _calldata = abi.encodeCall(ILaunchPadProjectInit.init, input);
        IDiamondCut(launchPad).diamondCut(cut, ds.launchPadProjectDiamondInit, _calldata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ILaunchPadCommon {
    enum LaunchPadType {
        FlokiPadCreatedBefore,
        FlokiPadCreatedAfter
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
        uint256 feePercentage;
        address paymentTokenAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";
import { ICrossPaymentModule } from "../../common/admin/interfaces/ICrossPaymentModule.sol";

interface ILaunchPadFactory {
    struct StoreLaunchPadInput {
        ILaunchPadCommon.LaunchPadType launchPadType;
        address launchPadAddress;
        address owner;
        address referrer;
    }

    function addInvestorToLaunchPad(address investor) external;
    function createLaunchPad(ILaunchPadCommon.CreateLaunchPadInput memory input) external payable;
    function createLaunchPadWithPaymentSignature(
        ILaunchPadCommon.CreateLaunchPadInput memory storeInput,
        ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput
    ) external;
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

    function tokenDecimals() external view returns (uint256);

    function totalTokensClaimed() external view returns (uint256);

    function totalTokensSold() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";

interface ILaunchPadProjectAdmin {
    function setSupercharger(bool isSuperchargerEnabled) external;

    function updateStartTimestamp(uint256 newStartTimestamp) external;

    function extendDuration(uint256 durationIncrease) external;

    function updateReleaseSchedule(ILaunchPadCommon.ReleaseScheduleV2[] memory releaseSchedule) external;

    function setTokenAddress(address tokenAddress) external;

    function withdrawFees() external;

    function withdrawTokens(address tokenAddress) external;

    function withdrawTokensToRecipient(address tokenAddress, address recipient) external;

    /** ERRORS */
    error UPDATE_RELEASE_SCHEDULE_ERROR(string errorMessage);
    error UPDATE_START_TIMESTAMP_ERROR(string errorMessage);
    error EXTEND_DURATION_ERROR(string errorMessage);
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
    uint256 internal constant BURN_BASIS_POINTS = 5_000;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "../interfaces/ILaunchPadCommon.sol";
import { ILaunchPadFactory } from "../interfaces/ILaunchPadFactory.sol";
import { ILaunchPadProject } from "../interfaces/ILaunchPadProject.sol";
import { ILaunchPadProjectAdmin } from "../interfaces/ILaunchPadProjectAdmin.sol";

library LibLaunchPadFactoryStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("tokenfi.launchpad.factory.diamond.storage");

    struct DiamondStorage {
        address[] launchPads;
        mapping(address => address[]) launchPadsByOwner;
        mapping(address => address[]) launchPadsByInvestor;
        mapping(address => address) launchPadOwner;
        mapping(address => bool) isLaunchPad;
        mapping(address => ILaunchPadCommon.CreateErc20Input) tokenInfoByLaunchPadAddress;
        uint256 currentBlockLaunchPadCreated;
        uint256 currentBlockLaunchPadOwnerUpdated;
        address _tokenLauncherERC20; // deprecated (available on Diamond itself)
        address _tokenLauncherStore; // deprecated (available on Diamond itself)
        address _tokenLauncherBuybackHandler; // deprecated (available on Diamond itself)
        address launchPadProjectFacet;
        address accessControlFacet;
        address pausableFacet;
        address loupeFacet;
        address proxyFacet;
        address launchPadProjectDiamondInit;
        address _tokenfiToken; // deprecated (available on LaunchPadPaymentStorage)
        address _usdToken; // deprecated (available on LaunchPadPaymentStorage)
        address _router; // deprecated (available on LaunchPadPaymentStorage)
        address _treasury; // deprecated (available on LaunchPadPaymentStorage)
        address signerAddress;
        uint256 maxTokenCreationDeadline;
        uint256[] _superChargerMultiplierByTier; // deprecated (cause of wrong updates by v1)
        uint256[] _superChargerHeadstartByTier; // deprecated (cause of wrong updates by v1)
        uint256[] _superChargerTokensPercByTier; // deprecated (cause of wrong updates by v1)
        uint256 maxDurationIncrement;
        address launchPadProjectAdminFacet;
        address launchPadImplementation;
        uint256[] superChargerMultiplierByTier;
        uint256[] superChargerHeadstartByTier;
        uint256[] superChargerTokensPercByTier;
    }

    event LaunchPadCreated(uint256 indexed previousBlock, ILaunchPadFactory.StoreLaunchPadInput launchPad);
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
        bytes4[] memory functionSelectors = new bytes4[](29);
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
        functionSelectors[13] = ILaunchPadProject.getNextNonce.selector;
        functionSelectors[14] = ILaunchPadProject.getProjectOwnerRole.selector;
        functionSelectors[15] = ILaunchPadProject.getPurchasedInfoByUser.selector;
        functionSelectors[16] = ILaunchPadProject.getReleasedTokensPercentage.selector;
        functionSelectors[17] = ILaunchPadProject.getReleaseSchedule.selector;
        functionSelectors[18] = ILaunchPadProject.getTokensAvailableToBeClaimed.selector;
        functionSelectors[19] = ILaunchPadProject.getTokenCreationDeadline.selector;
        functionSelectors[20] = ILaunchPadProject.getTotalRaised.selector;
        functionSelectors[21] = ILaunchPadProject.isSuperchargerEnabled.selector;
        functionSelectors[22] = ILaunchPadProject.recoverSigner.selector;
        functionSelectors[23] = ILaunchPadProject.refund.selector;
        functionSelectors[24] = ILaunchPadProject.refundOnSoftCapFailure.selector;
        functionSelectors[25] = ILaunchPadProject.refundOnTokenCreationExpired.selector;
        functionSelectors[26] = ILaunchPadProject.tokenDecimals.selector;
        functionSelectors[27] = ILaunchPadProject.totalTokensClaimed.selector;
        functionSelectors[28] = ILaunchPadProject.totalTokensSold.selector;

        return functionSelectors;
    }

    function getLaunchPadProjectAdminSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory functionSelectors = new bytes4[](9);
        functionSelectors[0] = ILaunchPadProjectAdmin.setSupercharger.selector;
        functionSelectors[1] = ILaunchPadProjectAdmin.setTokenAddress.selector;
        functionSelectors[2] = ILaunchPadProjectAdmin.withdrawFees.selector;
        functionSelectors[3] = ILaunchPadProjectAdmin.withdrawTokens.selector;
        functionSelectors[4] = ILaunchPadProjectAdmin.withdrawTokensToRecipient.selector;
        functionSelectors[5] = ILaunchPadProjectAdmin.updateStartTimestamp.selector;
        functionSelectors[6] = ILaunchPadProjectAdmin.extendDuration.selector;
        functionSelectors[7] = ILaunchPadProjectAdmin.updateReleaseSchedule.selector;

        return functionSelectors;
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