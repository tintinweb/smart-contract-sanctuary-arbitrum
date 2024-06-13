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

library LibAccessControl {
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 internal constant WHITELIST_ADMIN_ROLE = keccak256("WHITELIST_ADMIN_ROLE");
    bytes32 internal constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { AccessControlInternal } from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import { LibAccessControl } from "../../common/admin/libraries/LibAccessControl.sol";

import { LibPricingStorage } from "../libraries/LibPricingStorage.sol";
import { LibPaymentStorage } from "../libraries/LibPaymentStorage.sol";
import { IPricingModule } from "../interfaces/IPricingModule.sol";
import { ILockerCommon } from "../interfaces/ILockerCommon.sol";
import { ITokenSwapperFacet } from "../interfaces/ITokenSwapperFacet.sol";

/**
 * @title Pricing module V1
 * @notice This module calculates the required price to lock a set of tokens on
 * Project L. Pricing is determined by the number of tokens a user is trying to
 * lock in a vault, as well as the type of token. Project L uses the following
 * pricing tiers:
 *  - fungible tokens:           50 USDT flat fee per unique token address.
 *  - non-fungible tokens:      100 USDT flat fee per unique token address.
 *  - multi tokens:             100 USDT flat fee per unique token address.
 *  - vested tokens:            100 USDT flat fee per unique token address.
 *  - liquidity pool tokens:    0.5 percent of the locked tokens.
 *
 * In case of liquidity pool tokens being vested, the pricing tier of 0.5
 * percent is used.
 */
contract LockerPricingModuleFacet is IPricingModule, AccessControlInternal {
    function addDiscountNFTs(address[] memory newDiscountNFTs) external onlyAdmin {
        LibPricingStorage.DiamondStorage storage ds = LibPricingStorage.diamondStorage();
        for (uint256 i = 0; i < newDiscountNFTs.length; i++) {
            require(newDiscountNFTs[i] != address(0), "PricingModuleFacet::addDiscountNFTs::ZERO: Discount NFT cannot be zero address.");

            ds.discountNFTs.push(newDiscountNFTs[i]);
        }
    }

    function getDiscountNFTs() external view override returns (address[] memory) {
        LibPricingStorage.DiamondStorage storage ds = LibPricingStorage.diamondStorage();
        return ds.discountNFTs;
    }

    function isDiscountNft(address nft) external view override returns (bool) {
        LibPricingStorage.DiamondStorage storage ds = LibPricingStorage.diamondStorage();
        for (uint256 i = 0; i < ds.discountNFTs.length; i++) {
            if (ds.discountNFTs[i] == nft) {
                return true;
            }
        }
        return false;
    }

    function priceDecimals() external view override returns (uint8) {
        LibPricingStorage.DiamondStorage storage ds = LibPricingStorage.diamondStorage();
        return ds.priceDecimals;
    }

    function setTokenPrice(uint256 newPrice) external override onlyAdmin {
        LibPricingStorage.DiamondStorage storage ds = LibPricingStorage.diamondStorage();
        uint256 oldPrice = ds.erc20TokenPrice;
        ds.erc20TokenPrice = newPrice;

        emit LibPricingStorage.TokenPriceUpdated(oldPrice, newPrice, TokenType.ERC20);
    }

    function setMultiTokenPrice(uint256 newPrice) external override onlyAdmin {
        LibPricingStorage.DiamondStorage storage ds = LibPricingStorage.diamondStorage();
        uint256 oldPrice = ds.erc1155TokenPrice;
        ds.erc1155TokenPrice = newPrice;

        emit LibPricingStorage.TokenPriceUpdated(oldPrice, newPrice, TokenType.ERC1155);
    }

    function setNftTokenPrice(uint256 newPrice) external override onlyAdmin {
        LibPricingStorage.DiamondStorage storage ds = LibPricingStorage.diamondStorage();
        uint256 oldPrice = ds.erc721TokenPrice;
        ds.erc721TokenPrice = newPrice;

        emit LibPricingStorage.TokenPriceUpdated(oldPrice, newPrice, TokenType.ERC721);
    }

    function setVestedTokenPrice(uint256 newPrice) external override onlyAdmin {
        LibPricingStorage.DiamondStorage storage ds = LibPricingStorage.diamondStorage();
        uint256 oldPrice = ds.erc20VestedTokenPrice;
        ds.erc20VestedTokenPrice = newPrice;

        emit LibPricingStorage.TokenPriceUpdated(oldPrice, newPrice, TokenType.ERC20_VESTED);
    }

    function setLPBasisPoints(uint256 newBasisPoints) external override onlyAdmin {
        LibPricingStorage.DiamondStorage storage ds = LibPricingStorage.diamondStorage();
        uint256 oldBasisPoints = ds.lpTokenBasisPoints;
        ds.lpTokenBasisPoints = newBasisPoints;

        emit LibPricingStorage.BasisPointsUpdated(oldBasisPoints, newBasisPoints);
    }

    function getPrice(
        address user,
        ILockerCommon.FungibleTokenDeposit[] memory fungibleTokenDeposits,
        ILockerCommon.NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        ILockerCommon.MultiTokenDeposit[] memory multiTokenDeposits,
        bool isVested
    ) external view override returns (PriceInfo memory) {
        // Array to hold addresses of V2 LP tokens in which payment will be
        // required.
        address[] memory lpV2Tokens = new address[](fungibleTokenDeposits.length);

        // Array containing payment amounts required per LP token. The indices
        // match the ones in `lpV2Tokens`.
        uint256[] memory lpV2Amounts = new uint256[](fungibleTokenDeposits.length);

        // Array to hold addresses of V3 LP tokens in which payment will be
        // required.
        ILockerCommon.V3LPData[] memory lpV3Tokens = new ILockerCommon.V3LPData[](nonFungibleTokenDeposits.length);

        LibPricingStorage.DiamondStorage storage ds = LibPricingStorage.diamondStorage();
        LibPaymentStorage.DiamondStorage storage ps = LibPaymentStorage.diamondStorage();
        // The pricing model for fungible tokens is unique due to the fact that
        // they could be liquidity pool tokens.
        bool hasFungibleToken = false;
        for (uint256 i = 0; i < fungibleTokenDeposits.length; i++) {
            if (ITokenSwapperFacet(ps.tokenSwapper).isV2LiquidityPoolToken(fungibleTokenDeposits[i].tokenAddress)) {
                lpV2Tokens[i] = fungibleTokenDeposits[i].tokenAddress;
                lpV2Amounts[i] = (fungibleTokenDeposits[i].amount * ds.lpTokenBasisPoints) / 10000;
            } else {
                hasFungibleToken = true;
            }
        }
        bool hasNonFungibleToken = false;
        for (uint256 i = 0; i < nonFungibleTokenDeposits.length; i++) {
            address tokenAddress = nonFungibleTokenDeposits[i].tokenAddress;
            uint256 tokenId = nonFungibleTokenDeposits[i].tokenId;
            (address token0, address token1, uint128 liquidity, uint24 fee) = ITokenSwapperFacet(ps.tokenSwapper).getV3Position(tokenAddress, tokenId);
            if (token0 != address(0)) {
                lpV3Tokens[i].tokenAddress = tokenAddress;
                lpV3Tokens[i].token0 = token0;
                lpV3Tokens[i].token1 = token1;
                lpV3Tokens[i].liquidityToRemove = uint128((liquidity * ds.lpTokenBasisPoints) / 10000);
                lpV3Tokens[i].fee = fee;
            } else {
                hasNonFungibleToken = true;
            }
        }
        bool hasMultiToken = multiTokenDeposits.length > 0;
        uint256 usdCost = _calculateFlatPrice(user, isVested, hasFungibleToken, hasNonFungibleToken, hasMultiToken);

        return PriceInfo({ v2LpTokens: lpV2Tokens, v2LpAmounts: lpV2Amounts, v3LpTokens: lpV3Tokens, usdtAmount: usdCost });
    }

    function getFeeToken() external view override returns (address) {
        LibPricingStorage.DiamondStorage storage ds = LibPricingStorage.diamondStorage();
        return ds.feeToken;
    }

    function getFlokiToken() external view override returns (address) {
        LibPricingStorage.DiamondStorage storage ds = LibPricingStorage.diamondStorage();
        return ds.flokiToken;
    }

    function setFeeToken(address newFeeToken) external override onlyAdmin {
        require(newFeeToken != address(0), "PricingModuleFacet::setFeeToken::ZERO: feeToken cannot be zero address.");
        LibPricingStorage.DiamondStorage storage ds = LibPricingStorage.diamondStorage();
        address oldFeeToken = ds.feeToken;
        ds.feeToken = newFeeToken;
        emit LibPricingStorage.FeeTokenUpdated(oldFeeToken, newFeeToken);
    }

    function setFlokiToken(address newFlokiToken) external override onlyAdmin {
        LibPricingStorage.DiamondStorage storage ds = LibPricingStorage.diamondStorage();
        ds.flokiToken = newFlokiToken;
    }

    function _calculateFlatPrice(
        address user,
        bool isVested,
        bool hasFungibleToken,
        bool hasNonFungibleToken,
        bool hasMultiToken
    ) private view returns (uint256 usdCost) {
        LibPricingStorage.DiamondStorage storage ds = LibPricingStorage.diamondStorage();
        if (_hasDiscount(user, ds)) {
            return 0;
        }

        // The USDT price per token.
        uint256 tokenPrice = isVested ? ds.erc20VestedTokenPrice : ds.erc20TokenPrice;

        if (hasFungibleToken) {
            usdCost += tokenPrice;
        }

        // Non-fungible and multi token pricing is per token and therefore
        // needs no uniqueness checks.
        if (hasNonFungibleToken) {
            usdCost += ds.erc721TokenPrice;
        }
        if (hasMultiToken) {
            usdCost += ds.erc1155TokenPrice;
        }
    }

    function _hasDiscount(address user, LibPricingStorage.DiamondStorage storage ds) private view returns (bool) {
        for (uint256 i = 0; i < ds.discountNFTs.length; i++) {
            uint256 balance = IERC721Enumerable(ds.discountNFTs[i]).balanceOf(user);
            if (balance > 0) {
                return true;
            }
        }
        return false;
    }

    modifier onlyAdmin() {
        require(_hasRole(LibAccessControl.DEFAULT_ADMIN_ROLE, msg.sender) || msg.sender == address(this), "PricingModuleFacet: caller is not an admin");
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

interface ITokenSwapperFacet {
    struct TokenSwapInfo {
        address tokenAddress;
        address routerFactory;
        bool isV2;
        address referrer;
        address vault;
        uint256 amount;
        uint24 v3PoolFee;
    }

    function addRouter(address routerAddress, bool isV2) external;

    function addTokenForSwapping(TokenSwapInfo memory params, uint256 addedTime) external;

    function adminWithdraw(address tokenAddress, uint256 amount, address destination) external;

    function clearTokensFromSwapping() external;

    function getTokensForSwapping() external view returns (TokenSwapInfo[] memory);

    function getRouter(address lpTokenAddress) external view returns (address);

    function getV3Position(address tokenAddress, uint256 tokenId) external view returns (address, address, uint128, uint24);

    function isRouterFactorySupported(address factory) external view returns (bool);

    function isTokenReadyForSwapping(address tokenAddress) external view returns (bool);

    function isV2LiquidityPoolToken(address tokenAddress) external view returns (bool);

    function isV3LiquidityPoolToken(address tokenAddress, uint256 tokenId) external view returns (bool);

    function processTokenSwapping(address token) external;

    function processTokenSwappingByIndex(uint256 index) external;

    function removeTokenFromSwapping(address tokenAddress) external;

    function removeTokensFromSwappingByIndexes(uint256[] memory indexes) external;

    function setRequireOraclePrice(bool requires) external;

    function setRouterForFloki(address routerAddress, bool isV2Router) external;

    function setSellDelay(uint256 newDelay) external;

    function setSlippageBasisPoints(uint256 newSlippage) external;

    function setSlippagePerToken(uint256 slippage, address token) external;

    function setWethToUsdV3PoolFee(uint24 newFee) external;

    // solhint-disable-next-line func-name-mixedcase
    function TOKEN_SWAPPER_ADMIN_ROLE() external view returns (bytes32);
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