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
import { IPlatformModule } from "../interfaces/IPlatformModule.sol";
import { LibPlatformModuleStorage } from "../libraries/PlatformModuleStorage.sol";
import { LibPaymentModuleConsts } from "../libraries/PaymentModuleConsts.sol";

contract PlatformModuleFacet is IPlatformModule, AccessControlInternal {

    // solhint-disable-next-line func-name-mixedcase
    function PLATFORM_MANAGER_ROLE() external pure override returns (bytes32) {
        return LibPaymentModuleConsts.PLATFORM_MANAGER_ROLE;
    }

    function getPlatformCount() external view override returns (uint256) {
        LibPlatformModuleStorage.DiamondStorage storage ds = LibPlatformModuleStorage.diamondStorage();

        return ds.platformIds.length;
    }

    function getPlatformIds() external view override returns (bytes32[] memory) {
        LibPlatformModuleStorage.DiamondStorage storage ds = LibPlatformModuleStorage.diamondStorage();

        return ds.platformIds;
    }

    function getPlatformIdByIndex(uint256 index) external view override returns (bytes32) {
        LibPlatformModuleStorage.DiamondStorage storage ds = LibPlatformModuleStorage.diamondStorage();

        return ds.platformIds[index];
    }

    function getPlatformById(bytes32 platformId) external view override returns (IPlatformModule.Platform memory) {
        LibPlatformModuleStorage.DiamondStorage storage ds = LibPlatformModuleStorage.diamondStorage();

        return ds.platformById[platformId];
    }

    function addPlatform(IPlatformModule.Platform memory platform) external override onlyRole(LibPaymentModuleConsts.PLATFORM_MANAGER_ROLE) {
        LibPlatformModuleStorage.DiamondStorage storage ds = LibPlatformModuleStorage.diamondStorage();

        // if the platform is already exists, should revert
        require(ds.platformById[platform.id].id != platform.id, "PlatformModule:addPlatform: Platform already exists");
        require(platform.treasury != address(0), "PlatformModule:addPlatform::ZERO: treasuryAddress cannot be zero address.");

        _copyPlatform(platform.id, platform);

        ds.platformIds.push(platform.id);

        emit LibPlatformModuleStorage.PlatformAdded(platform.id, platform);
    }

    function removePlatform(uint256 index) external override onlyRole(LibPaymentModuleConsts.PLATFORM_MANAGER_ROLE) {
        LibPlatformModuleStorage.DiamondStorage storage ds = LibPlatformModuleStorage.diamondStorage();

        bytes32 platformId = ds.platformIds[index];

        require(ds.platformById[platformId].id == platformId, "PlatformModule:removePlatform Platform does not exist");

        delete ds.platformById[platformId];

        ds.platformIds[index] = ds.platformIds[ds.platformIds.length - 1];
        ds.platformIds.pop();

        emit LibPlatformModuleStorage.PlatformRemoved(platformId, ds.platformById[platformId]);
    }

    function updatePlatform(IPlatformModule.Platform memory platform) external override {
        LibPlatformModuleStorage.DiamondStorage storage ds = LibPlatformModuleStorage.diamondStorage();

        require(platform.treasury != address(0), "PlatformModule:updatePlatform::ZERO: treasuryAddress cannot be zero address.");

        uint256 platformIndex = ds.platformIds.length;
        for (uint256 index = 0; index < ds.platformIds.length; index++) {
            if (ds.platformIds[index] == platform.id) {
                platformIndex = index;
                break;
            }
        }
        require(platformIndex < ds.platformIds.length, "PlatformModule:updatePlatform: Platform does not exist");

        bytes32 platformId = ds.platformIds[platformIndex];

        require(ds.platformById[platformId].owner == msg.sender, "PlatformModule:updatePlatform: Only owner can update platform");

        emit LibPlatformModuleStorage.PlatformUpdated(platformId, ds.platformById[platformId], platform);

        _copyPlatform(platformId, platform);
    }

    function addService(bytes32 platformId, IPlatformModule.Service memory service) external override {
        LibPlatformModuleStorage.DiamondStorage storage ds = LibPlatformModuleStorage.diamondStorage();

        require(ds.platformById[platformId].id == platformId, "PlatformModule:addService: Platform does not exist");

        IPlatformModule.Platform storage platform = ds.platformById[platformId];

        require(platform.owner == msg.sender, "PlatformModule:addService: Only owner can add service");

        emit LibPlatformModuleStorage.ServiceAdded(platformId, platform.services.length, service);

        platform.services.push(service);
    }

    function removeService(bytes32 platformId, uint256 serviceId) external override {
        LibPlatformModuleStorage.DiamondStorage storage ds = LibPlatformModuleStorage.diamondStorage();
        IPlatformModule.Platform storage platform = ds.platformById[platformId];

        require(platform.owner == msg.sender, "PlatformModule:removeService: Only owner can remove service");

        emit LibPlatformModuleStorage.ServiceRemoved(platformId, serviceId, platform.services[serviceId]);

        platform.services[serviceId] = platform.services[platform.services.length - 1];
        platform.services.pop();
    }

    function updateService(
        bytes32 platformId,
        uint256 serviceId,
        IPlatformModule.Service memory service
    ) external override {
        LibPlatformModuleStorage.DiamondStorage storage ds = LibPlatformModuleStorage.diamondStorage();
        IPlatformModule.Platform storage platform = ds.platformById[platformId];

        require(platform.owner == msg.sender, "PlatformModule:updateService: Only owner can update service");
        require(platform.services.length > serviceId, "PlatformModule:updateService: Service does not exist");

        emit LibPlatformModuleStorage.ServiceUpdated(platformId, serviceId, platform.services[serviceId], service);

        platform.services[serviceId] = service;
    }

    function _copyPlatform(bytes32 platformId, IPlatformModule.Platform memory platform) private {
        LibPlatformModuleStorage.DiamondStorage storage ds = LibPlatformModuleStorage.diamondStorage();

        ds.platformById[platformId].name = platform.name;
        ds.platformById[platformId].id = platform.id;
        ds.platformById[platformId].owner = platform.owner;
        ds.platformById[platformId].treasury = platform.treasury;
        ds.platformById[platformId].referrerBasisPoints = platform.referrerBasisPoints;
        ds.platformById[platformId].burnBasisPoints = platform.burnBasisPoints;

        for (uint256 i = 0; i < platform.services.length; i++) {
            ds.platformById[platformId].services.push(platform.services[i]);
        }
    }
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

    function addService(bytes32 platformId, IPlatformModule.Service memory service) external;

    function removeService(bytes32 platformId, uint256 serviceId) external;

    function updateService(bytes32 platformId, uint256 serviceId, IPlatformModule.Service memory service) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibPaymentModuleConsts {
    bytes32 internal constant PAYMENT_PROCESSOR_ROLE = keccak256("PAYMENT_PROCESSOR_ROLE");
    bytes32 internal constant PLATFORM_MANAGER_ROLE = keccak256("PLATFORM_MANAGER_ROLE");
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { IPlatformModule } from "../interfaces/IPlatformModule.sol";

library LibPlatformModuleStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("floki.platform.diamond.storage");

    struct DiamondStorage {
        mapping(bytes32 => IPlatformModule.Platform) platformById;
        bytes32[] platformIds;
    }

    event PlatformAdded(bytes32 platformId, IPlatformModule.Platform platform);

    event PlatformUpdated(bytes32 platformId, IPlatformModule.Platform oldPlatform, IPlatformModule.Platform newPlatform);

    event PlatformRemoved(bytes32 platformId, IPlatformModule.Platform platform);

    event ServiceAdded(bytes32 platformId, uint256 serviceId, IPlatformModule.Service service);

    event ServiceUpdated(bytes32 platformId, uint256 serviceId, IPlatformModule.Service oldService, IPlatformModule.Service newService);

    event ServiceRemoved(bytes32 platformId, uint256 serviceId, IPlatformModule.Service service);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }
}