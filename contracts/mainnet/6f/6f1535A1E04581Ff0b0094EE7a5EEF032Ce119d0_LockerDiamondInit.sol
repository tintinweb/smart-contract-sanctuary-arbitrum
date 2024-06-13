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

interface IWhitelistFacet {
    function isWhitelistEnabled(bytes32 productId) external view returns (bool);

    function setWhitelistEnabled(bool enabled, bytes32 productId) external;
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

import { ILockerCommon } from "../interfaces/ILockerCommon.sol";

interface IPricingModule {
    enum TokenType {
        ERC20,
        ERC721,
        ERC1155,
        ERC20_VESTED
    }

    struct PriceInfo {
        address[] v2LpTokens;
        uint256[] v2LpAmounts;
        ILockerCommon.V3LPData[] v3LpTokens;
        uint256 usdtAmount;
    }

    function getDiscountNFTs() external view returns (address[] memory);

    function getFeeToken() external view returns (address);

    function getFlokiToken() external view returns (address);

    /**
     * @notice Get price of vault creation.
     * @param user Address of vault creator.
     * @param fungibleTokenDeposits Array of fungible token deposits
     * consisting of addresses and amounts.
     * @param nonFungibleTokenDeposits Array of non-fungible token deposits
     * consisting of addresses and IDs.
     * @param multiTokenDeposits Array of multi token deposits consisting of
     * addresses, IDs and their corresponding amounts.
     * @return A four-item tuple consisting of an array of LP token addresses,
     * an array of the corresponding required payment amounts, an array of V3LPData, and the amount
     * of USDT required.
     */
    function getPrice(
        address user,
        ILockerCommon.FungibleTokenDeposit[] memory fungibleTokenDeposits,
        ILockerCommon.NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        ILockerCommon.MultiTokenDeposit[] memory multiTokenDeposits,
        bool isVested
    ) external view returns (PriceInfo memory);

    function isDiscountNft(address nft) external view returns (bool);

    function priceDecimals() external view returns (uint8);

    function setTokenPrice(uint256 newPrice) external;

    function setMultiTokenPrice(uint256 newPrice) external;

    function setNftTokenPrice(uint256 newPrice) external;

    function setVestedTokenPrice(uint256 newPrice) external;

    function setLPBasisPoints(uint256 newBasisPoints) external;

    function setFeeToken(address newFeeToken) external;

    function setFlokiToken(address newFlokiToken) external;
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

library LibPaymentStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("flokifi.locker.payment.diamond.storage");

    struct DiamondStorage {
        address dexRouter;
        bool isV2Router;
        address nativeWrappedToken;
        uint24 v3PoolFeeForUsdNative;
        bool convertNativeFeeToUsd;
        uint256 feeCollectedLastBlock;
        uint256 flokiBurnedLastBlock;
        uint256 referrerShareLastBlock;
        address priceOracleManager;
        address tokenSwapper;
    }

    event TreasuryAddressUpdated(address indexed oldTreasury, address indexed newTreasury);
    event FeeCollected(uint256 indexed previousBlock, address indexed vault, uint256 usdAmount);
    event ReferrerSharePaid(uint256 indexed previousBlock, address indexed vault, address referrer, uint256 usdAmount);
    event FlokiBurned(uint256 indexed previousBlock, address indexed vault, uint256 usdAmount, uint256 flokiAmount);
    event V3PoolFeeForUsdUpdated(uint24 indexed oldFee, uint24 indexed newFee);
    event V3PoolFeeForFlokiUpdated(uint24 indexed oldFee, uint24 indexed newFee);
    event RouterUpdated(address indexed oldRouter, address indexed newRouter, bool isV3Router);
    event UsdTokenUpdated(address indexed oldUsd, address indexed newUsd);
    event SlippageUpdated(uint256 indexed oldSlippage, uint256 indexed newSlippage);

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

import { IPricingModule } from "../interfaces/IPricingModule.sol";

library LibPricingStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("flokifi.locker.pricing.diamond.storage");

    struct DiamondStorage {
        uint256 erc20TokenPrice;
        uint256 erc721TokenPrice;
        uint256 erc1155TokenPrice;
        uint256 erc20VestedTokenPrice;
        uint256 lpTokenBasisPoints;
        address[] discountNFTs;
        uint8 priceDecimals;
        address feeToken;
        address flokiToken;
        address treasury;
    }

    event TokenPriceUpdated(uint256 indexed oldPrice, uint256 newPrice, IPricingModule.TokenType indexed tokenType);
    event BasisPointsUpdated(uint256 indexed oldBasisPoints, uint256 indexed newBasisPoints);
    event FeeTokenUpdated(address indexed oldFeeToken, address indexed newFeeToken);

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { AccessControl } from "@solidstate/contracts/access/access_control/AccessControl.sol";

import { LibAccessControl } from "../../common/admin/libraries/LibAccessControl.sol";
import { IWhitelistFacet } from "../../common/admin/interfaces/IWhitelistFacet.sol";

import { LibLockerConsts } from "../libraries/LibLockerConsts.sol";
import { LibPaymentStorage } from "../libraries/LibPaymentStorage.sol";
import { LibPricingStorage } from "../libraries/LibPricingStorage.sol";
import { LibVaultFactoryStorage } from "../libraries/LibVaultFactoryStorage.sol";
import { LibVaultFacetsStorage } from "../libraries/LibVaultFacetsStorage.sol";

contract LockerDiamondInit is AccessControl {
    struct InitDiamondArgs {
        uint256 maxTokensPerVault;
        bool enableWhitelist;
        address[] whitelisted;
        address flokiToken;
        address dexRouter;
        bool isV2Router;
        address feeToken;
        address nativeWrappedToken;
        address treasury;
        address priceOracle;
        address tokenSwapper;
        address vaultKey;
        address[] discountNFTs;
        uint256 lpTokenBasisPoints;
        uint256 tokenPrice;
        uint256 nftTokenPrice;
        uint256 multiTokenPrice;
        uint256 vestedTokenPrice;
        uint8 priceDecimals;
        uint24 v3PoolFeeForUsdNative;
        InitVaultFacetArgs vaultFacetArgs;
    }

    struct InitVaultFacetArgs {
        address accessControlFacet;
        address fungibleVaultFacet;
        address fungibleVestingVaultFacet;
        address nftVaultFacet;
        address multiTokenVaultFacet;
        address loupeFacet;
        address pausableFacet;
        address proxyFacet;
        address vaultCommonFacet;
        address vaultDiamondInit;
    }

    function init(InitDiamondArgs memory _input) external {
        require(_input.feeToken != address(0), "LockerDiamondInit::init::ZERO: feeToken cannot be zero address.");
        require(_input.treasury != address(0), "LockerDiamondInit::init::ZERO: Treasury cannot be zero address.");
        // LibVaultFacetsStorage
        LibVaultFacetsStorage.DiamondStorage storage dsFacets = LibVaultFacetsStorage.diamondStorage();
        dsFacets.accessControlFacet = _input.vaultFacetArgs.accessControlFacet;
        dsFacets.fungibleVaultFacet = _input.vaultFacetArgs.fungibleVaultFacet;
        dsFacets.fungibleVestingVaultFacet = _input.vaultFacetArgs.fungibleVestingVaultFacet;
        dsFacets.nftVaultFacet = _input.vaultFacetArgs.nftVaultFacet;
        dsFacets.multiTokenVaultFacet = _input.vaultFacetArgs.multiTokenVaultFacet;
        dsFacets.loupeFacet = _input.vaultFacetArgs.loupeFacet;
        dsFacets.pausableFacet = _input.vaultFacetArgs.pausableFacet;
        dsFacets.proxyFacet = _input.vaultFacetArgs.proxyFacet;
        dsFacets.vaultCommonFacet = _input.vaultFacetArgs.vaultCommonFacet;
        dsFacets.vaultDiamondInit = _input.vaultFacetArgs.vaultDiamondInit;

        // VaultFactory
        LibVaultFactoryStorage.DiamondStorage storage ds0 = LibVaultFactoryStorage.diamondStorage();

        ds0.maxTokensPerVault = _input.maxTokensPerVault;
        ds0.vaultKey = _input.vaultKey;

        // PricingModule
        LibPricingStorage.DiamondStorage storage ds2 = LibPricingStorage.diamondStorage();

        for (uint256 i = 0; i < _input.discountNFTs.length; i++) {
            require(_input.discountNFTs[i] != address(0), "LockerDiamondInit::init::ZERO: Discount NFT cannot be zero address.");

            ds2.discountNFTs.push(_input.discountNFTs[i]);
        }
        ds2.erc20TokenPrice = _input.tokenPrice;
        ds2.erc721TokenPrice = _input.nftTokenPrice;
        ds2.erc1155TokenPrice = _input.multiTokenPrice;
        ds2.erc20VestedTokenPrice = _input.vestedTokenPrice;
        ds2.lpTokenBasisPoints = _input.lpTokenBasisPoints;

        ds2.priceDecimals = _input.priceDecimals;
        ds2.feeToken = _input.feeToken;
        ds2.flokiToken = _input.flokiToken;
        ds2.treasury = _input.treasury;

        // Payment Module
        LibPaymentStorage.DiamondStorage storage ds3 = LibPaymentStorage.diamondStorage();
        ds3.v3PoolFeeForUsdNative = _input.v3PoolFeeForUsdNative;
        ds3.convertNativeFeeToUsd = true;
        ds3.priceOracleManager = _input.priceOracle;
        ds3.dexRouter = _input.dexRouter;
        ds3.isV2Router = _input.isV2Router;
        ds3.tokenSwapper = _input.tokenSwapper;
        ds3.nativeWrappedToken = _input.nativeWrappedToken;

        // AccessControl
        _grantRole(LibAccessControl.DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(LibAccessControl.WHITELIST_ADMIN_ROLE, msg.sender);
        _grantRole(LibLockerConsts.TOKEN_SWAPPER_ADMIN_ROLE, msg.sender);

        if (_input.enableWhitelist) {
            IWhitelistFacet(address(this)).setWhitelistEnabled(true, LibLockerConsts.PRODUCT_ID);
            // whitelist users
            for (uint256 i = 0; i < _input.whitelisted.length; i++) {
                _grantRole(LibAccessControl.WHITELISTED_ROLE, _input.whitelisted[i]);
            }
        }
    }
}