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

    function recoverSigner(bytes32 message, bytes memory signature) external view returns (address);

    function refund(uint256 tokenAmount) external;

    function refundOnSoftCapFailure() external;

    function refundOnTokenCreationExpired(uint256 tokenAmount) external;

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

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";

interface ILaunchPadQuerier is ILaunchPadCommon {
    function getLaunchPadsPaginated(uint256 quantity, uint256 page) external view returns (address[] memory);

    function getLaunchPadsCount() external view returns (uint256);

    function getLaunchPadsByInvestorPaginated(address investor, uint256 quantity, uint256 page) external view returns (address[] memory);

    function getLaunchPadsByInvestorCount() external view returns (uint256);

    function getLaunchPadCountByOwner(address owner) external view returns (uint256);

    function getLaunchPadsByOwnerPaginated(address owner, uint256 quantity, uint256 page) external view returns (address[] memory);

    function getMaxTokenCreationDeadline() external view returns (uint256);

    function getSignerAddress() external view returns (address);

    function getSuperChargerHeadstartByTier(uint256 tier) external view returns (uint256);

    function getSuperChargerHeadstarts() external view returns (uint256[] memory);

    function getSuperChargerMultiplierByTier(uint256 tier) external view returns (uint256);

    function getSuperChargerTokensPercByTier(uint256 tier) external view returns (uint256);

    function launchPadTokenInfo(address launchPadAddress) external view returns (CreateErc20Input memory createErc20Input);

    function tokenLauncherERC20() external view returns (address);
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

import { AccessControl } from "@solidstate/contracts/access/access_control/AccessControl.sol";
import { AccessControlStorage } from "@solidstate/contracts/access/access_control/AccessControlStorage.sol";

import { ILaunchPadCommon } from "../interfaces/ILaunchPadCommon.sol";
import { ILaunchPadQuerier } from "../interfaces/ILaunchPadQuerier.sol";
import { ILaunchPadPricing } from "../interfaces/ILaunchPadPricing.sol";
import { ILaunchPadProjectInit } from "../interfaces/ILaunchPadProjectInit.sol";
import { LibLaunchPadConsts } from "../libraries/LaunchPadConsts.sol";
import { LibLaunchPadProjectStorage } from "../libraries/LaunchPadProjectStorage.sol";

contract LaunchPadProjectDiamondInit is AccessControl, ILaunchPadProjectInit {
    function init(ILaunchPadCommon.CreateLaunchPadInput memory input) external {
        require(input.launchPadInfo.owner != address(0), "LaunchPad: owner is 0");
        require(input.launchPadInfo.price > 0, "LaunchPad: price must be greater than 0");
        require(input.launchPadInfo.fundTarget.softCap > 0, "LaunchPad: softCap must be greater than 0");
        require(input.launchPadInfo.fundTarget.softCap <= input.launchPadInfo.fundTarget.hardCap, "LaunchPad: softCap must be less than hardCap");
        require(input.launchPadInfo.maxInvestPerWallet > 0, "LaunchPad: maxInvestPerWallet must be greater than 0");
        require(input.launchPadInfo.refundInfo.penaltyFeePercent <= 5_000, "LaunchPad: penaltyFeePercent must be less than or equal to 5000");

        uint256 icoEndTimestamp = input.launchPadInfo.startTimestamp + input.launchPadInfo.duration;
        require(input.launchPadInfo.startTimestamp >= block.timestamp, "LaunchPad: startTimestamp must be in the future");
        require(input.launchPadInfo.duration > 0, "LaunchPad: duration must be greater than 0");
        require(icoEndTimestamp < input.launchPadInfo.tokenCreationDeadline, "LaunchPad: end of sale must be before tokenCreationDeadline");

        uint256 maxTokenCreationDeadline = ILaunchPadQuerier(msg.sender).getMaxTokenCreationDeadline();

        uint256 tokenCreationWindowTime = input.launchPadInfo.tokenCreationDeadline - icoEndTimestamp;
        require(tokenCreationWindowTime <= maxTokenCreationDeadline, "LaunchPad: token creation window must be less than or equal to maxTokenCreationDeadline");

        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();

        ds.launchPadInfo = input.launchPadInfo;
        ds.isSuperchargerEnabled = input.isSuperchargerEnabled;
        ds.feePercentage = ILaunchPadPricing(msg.sender).getFeePercentage();
        ds.launchPadFactory = msg.sender;
        // Ensure they are sorted and sum to 100%
        uint256 lastReleaseTime = 0;
        uint256 totalPerc = 0;
        for (uint256 i = 0; i < input.releaseSchedule.length; i++) {
            require(lastReleaseTime < input.releaseSchedule[i].timestamp, "LaunchPad: release times must be in ascending order");
            lastReleaseTime = input.releaseSchedule[i].timestamp;
            totalPerc += input.releaseSchedule[i].percent;
            ds.releaseScheduleV2.push(input.releaseSchedule[i]);
        }
        require(totalPerc == LibLaunchPadConsts.BASIS_POINTS, "LaunchPad: release percentages must sum up to 100%");

        _grantRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(LibLaunchPadProjectStorage.LAUNCHPAD_OWNER_ROLE, input.launchPadInfo.owner);
        _grantRole(LibLaunchPadProjectStorage.PAUSER_ROLE, input.launchPadInfo.owner);
    }
}