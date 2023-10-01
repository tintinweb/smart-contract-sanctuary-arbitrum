// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from '../../interfaces/IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {
    error Ownable__NotOwner();
    error Ownable__NotTransitiveOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using AddressUtils for address;

    modifier onlyOwner() {
        if (msg.sender != _owner()) revert Ownable__NotOwner();
        _;
    }

    modifier onlyTransitiveOwner() {
        if (msg.sender != _transitiveOwner())
            revert Ownable__NotTransitiveOwner();
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transitiveOwner() internal view virtual returns (address owner) {
        owner = _owner();

        while (owner.isContract()) {
            try IERC173(owner).owner() returns (address transitiveOwner) {
                owner = transitiveOwner;
            } catch {
                break;
            }
        }
    }

    function _transferOwnership(address account) internal virtual {
        _setOwner(account);
    }

    function _setOwner(address account) internal virtual {
        OwnableStorage.Layout storage l = OwnableStorage.layout();
        emit OwnershipTransferred(l.owner, account);
        l.owner = account;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
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

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return contract owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
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

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

interface IVaultRegistry {
    // Enumerations
    enum TradeSide {
        Buy,
        Sell,
        Both
    }

    enum OptionType {
        Call,
        Put,
        Both
    }

    // Structs
    struct Vault {
        address vault;
        address asset;
        bytes32 vaultType;
        TradeSide side;
        OptionType optionType;
    }

    struct TokenPair {
        address base;
        address quote;
        address oracleAdapter;
    }

    // Events
    event VaultImplementationSet(bytes32 indexed vaultType, address implementation);

    event VaultAdded(
        address indexed vault,
        address indexed asset,
        bytes32 vaultType,
        TradeSide side,
        OptionType optionType
    );
    event VaultRemoved(address indexed vault);
    event VaultUpdated(
        address indexed vault,
        address indexed asset,
        bytes32 vaultType,
        TradeSide side,
        OptionType optionType
    );
    event SupportedTokenPairAdded(
        address indexed vault,
        address indexed base,
        address indexed quote,
        address oracleAdapter
    );
    event SupportedTokenPairRemoved(
        address indexed vault,
        address indexed base,
        address indexed quote,
        address oracleAdapter
    );

    /// @notice Gets the total number of vaults in the registry.
    /// @return The total number of vaults in the registry.
    function getNumberOfVaults() external view returns (uint256);

    /// @notice Adds a vault to the registry.
    /// @param vault The proxy address of the vault.
    /// @param asset The address for the token deposited in the vault.
    /// @param vaultType The type of the vault.
    /// @param side The trade side of the vault.
    /// @param optionType The option type of the vault.
    function addVault(address vault, address asset, bytes32 vaultType, TradeSide side, OptionType optionType) external;

    /// @notice Removes a vault from the registry.
    /// @param vault The proxy address of the vault.
    function removeVault(address vault) external;

    /// @notice Returns whether the given address is a vault
    /// @param vault The address to check
    /// @return Whether the given address is a vault
    function isVault(address vault) external view returns (bool);

    /// @notice Updates a vault in the registry.
    /// @param vault The proxy address of the vault.
    /// @param asset The address for the token deposited in the vault.
    /// @param vaultType The type of the vault.
    /// @param side The trade side of the vault.
    /// @param optionType The option type of the vault.
    function updateVault(
        address vault,
        address asset,
        bytes32 vaultType,
        TradeSide side,
        OptionType optionType
    ) external;

    /// @notice Adds a set of supported token pairs to the vault.
    /// @param vault The proxy address of the vault.
    /// @param tokenPairs The token pairs to add.
    function addSupportedTokenPairs(address vault, TokenPair[] memory tokenPairs) external;

    /// @notice Removes a set of supported token pairs from the vault.
    /// @param vault The proxy address of the vault.
    /// @param tokenPairsToRemove The token pairs to remove.
    function removeSupportedTokenPairs(address vault, TokenPair[] memory tokenPairsToRemove) external;

    /// @notice Gets the vault at the specified by the proxy address.
    /// @param vault The proxy address of the vault.
    /// @return The vault associated with the proxy address.
    function getVault(address vault) external view returns (Vault memory);

    /// @notice Gets the token supports supported for trading within the vault.
    /// @param vault The proxy address of the vault.
    /// @return The token pairs supported for trading within the vault.
    function getSupportedTokenPairs(address vault) external view returns (TokenPair[] memory);

    /// @notice Gets all vaults in the registry.
    /// @return All vaults in the registry.
    function getVaults() external view returns (Vault[] memory);

    /// @notice Gets all vaults with trade side `side` and option type `optionType`.
    /// @param assets The accepted assets (empty list for all assets).
    /// @param side The trade side.
    /// @param optionType The option type.
    /// @return All vaults meeting all of the passed filter criteria.
    function getVaultsByFilter(
        address[] memory assets,
        TradeSide side,
        OptionType optionType
    ) external view returns (Vault[] memory);

    /// @notice Gets all vaults with `asset` as their deposit token.
    /// @param asset The desired asset.
    /// @return All vaults with `asset` as their deposit token.
    function getVaultsByAsset(address asset) external view returns (Vault[] memory);

    /// @notice Gets all vaults with `tokenPair` in their trading set.
    /// @param tokenPair The desired token pair.
    /// @return All vaults with `tokenPair` in their trading set.
    function getVaultsByTokenPair(TokenPair memory tokenPair) external view returns (Vault[] memory);

    /// @notice Gets all vaults with trade side `side`.
    /// @param side The trade side.
    /// @return All vaults with trade side `side`.
    function getVaultsByTradeSide(TradeSide side) external view returns (Vault[] memory);

    /// @notice Gets all vaults with option type `optionType`.
    /// @param optionType The option type.
    /// @return All vaults with option type `optionType`.
    function getVaultsByOptionType(OptionType optionType) external view returns (Vault[] memory);

    /// @notice Gets all the vaults of type `vaultType`.
    /// @param vaultType The vault type.
    /// @return All the vaults of type `vaultType`.
    function getVaultsByType(bytes32 vaultType) external view returns (Vault[] memory);

    /// @notice Gets the implementation for the vaultType.
    /// @param vaultType The vault type.
    /// @return The implementation address.
    function getImplementation(bytes32 vaultType) external view returns (address);

    /// @notice Sets the implementation for the vaultType.
    /// @param vaultType The vault type.
    /// @param implementation The implementation contract address
    function setImplementation(bytes32 vaultType, address implementation) external;
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";
import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";

import {IVaultRegistry} from "./IVaultRegistry.sol";
import {VaultRegistryStorage} from "./VaultRegistryStorage.sol";

contract VaultRegistry is IVaultRegistry, OwnableInternal {
    using VaultRegistryStorage for VaultRegistryStorage.Layout;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @inheritdoc IVaultRegistry
    function getNumberOfVaults() external view returns (uint256) {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();
        return l.vaultAddresses.length();
    }

    /// @inheritdoc IVaultRegistry
    function addVault(
        address vault,
        address asset,
        bytes32 vaultType,
        TradeSide side,
        OptionType optionType
    ) external onlyOwner {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();

        l.vaults[vault] = Vault(vault, asset, vaultType, side, optionType);

        l.vaultAddresses.add(vault);
        l.vaultsByType[vaultType].add(vault);
        l.vaultsByAsset[asset].add(vault);
        l.vaultsByTradeSide[side].add(vault);
        l.vaultsByOptionType[optionType].add(vault);

        if (side == TradeSide.Both) {
            l.vaultsByTradeSide[TradeSide.Buy].add(vault);
            l.vaultsByTradeSide[TradeSide.Sell].add(vault);
        }

        if (optionType == OptionType.Both) {
            l.vaultsByOptionType[OptionType.Call].add(vault);
            l.vaultsByOptionType[OptionType.Put].add(vault);
        }

        emit VaultAdded(vault, asset, vaultType, side, optionType);
    }

    /// @inheritdoc IVaultRegistry
    function removeVault(address vault) public onlyOwner {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();

        l.vaultAddresses.remove(vault);
        l.vaultsByType[l.vaults[vault].vaultType].remove(vault);
        l.vaultsByAsset[l.vaults[vault].asset].remove(vault);
        l.vaultsByTradeSide[l.vaults[vault].side].remove(vault);
        l.vaultsByOptionType[l.vaults[vault].optionType].remove(vault);

        for (uint256 i = 0; i < l.supportedTokenPairs[vault].length; i++) {
            TokenPair memory pair = l.supportedTokenPairs[vault][i];
            l.vaultsByTokenPair[pair.base][pair.quote][pair.oracleAdapter].remove(vault);
        }

        if (l.vaults[vault].side == TradeSide.Both) {
            l.vaultsByTradeSide[TradeSide.Buy].remove(vault);
            l.vaultsByTradeSide[TradeSide.Sell].remove(vault);
        }

        if (l.vaults[vault].optionType == OptionType.Both) {
            l.vaultsByOptionType[OptionType.Call].remove(vault);
            l.vaultsByOptionType[OptionType.Put].remove(vault);
        }

        delete l.vaults[vault];
        delete l.supportedTokenPairs[vault];

        emit VaultRemoved(vault);
    }

    /// @inheritdoc IVaultRegistry
    function isVault(address vault) external view returns (bool) {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();
        return l.vaultAddresses.contains(vault);
    }

    /// @inheritdoc IVaultRegistry
    function updateVault(
        address vault,
        address asset,
        bytes32 vaultType,
        TradeSide side,
        OptionType optionType
    ) external onlyOwner {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();

        if (l.vaults[vault].asset != asset) {
            l.vaultsByAsset[l.vaults[vault].asset].remove(vault);
            l.vaultsByAsset[asset].add(vault);
        }

        if (l.vaults[vault].vaultType != vaultType) {
            l.vaultsByType[l.vaults[vault].vaultType].remove(vault);
            l.vaultsByType[vaultType].add(vault);
        }

        if (l.vaults[vault].side != side) {
            if (l.vaults[vault].side == TradeSide.Both) {
                l.vaultsByTradeSide[TradeSide.Buy].remove(vault);
                l.vaultsByTradeSide[TradeSide.Sell].remove(vault);
            } else {
                l.vaultsByTradeSide[l.vaults[vault].side].remove(vault);
            }

            if (side == TradeSide.Both) {
                l.vaultsByTradeSide[TradeSide.Buy].add(vault);
                l.vaultsByTradeSide[TradeSide.Sell].add(vault);
            } else {
                l.vaultsByTradeSide[side].add(vault);
            }
        }

        if (l.vaults[vault].optionType != optionType) {
            if (l.vaults[vault].optionType == OptionType.Both) {
                l.vaultsByOptionType[OptionType.Call].remove(vault);
                l.vaultsByOptionType[OptionType.Put].remove(vault);
            } else {
                l.vaultsByOptionType[l.vaults[vault].optionType].remove(vault);
            }

            if (optionType == OptionType.Both) {
                l.vaultsByOptionType[OptionType.Call].add(vault);
                l.vaultsByOptionType[OptionType.Put].add(vault);
            } else {
                l.vaultsByOptionType[optionType].add(vault);
            }
        }

        l.vaults[vault] = Vault(vault, asset, vaultType, side, optionType);

        emit VaultUpdated(vault, asset, vaultType, side, optionType);
    }

    /// @inheritdoc IVaultRegistry
    function addSupportedTokenPairs(address vault, TokenPair[] memory tokenPairs) external onlyOwner {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();

        for (uint256 i = 0; i < tokenPairs.length; i++) {
            l.supportedTokenPairs[vault].push(tokenPairs[i]);
            l.vaultsByTokenPair[tokenPairs[i].base][tokenPairs[i].quote][tokenPairs[i].oracleAdapter].add(vault);
        }
    }

    /// @notice Returns true if `tokenPairs` contains `tokenPair`, false otherwise
    function _containsTokenPair(
        TokenPair[] memory tokenPairs,
        TokenPair memory tokenPair
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < tokenPairs.length; i++) {
            if (
                tokenPairs[i].base == tokenPair.base &&
                tokenPairs[i].quote == tokenPair.quote &&
                tokenPairs[i].oracleAdapter == tokenPair.oracleAdapter
            ) {
                return true;
            }
        }

        return false;
    }

    /// @inheritdoc IVaultRegistry
    function removeSupportedTokenPairs(address vault, TokenPair[] memory tokenPairsToRemove) external onlyOwner {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();

        for (uint256 i = 0; i < tokenPairsToRemove.length; i++) {
            l
            .vaultsByTokenPair[tokenPairsToRemove[i].base][tokenPairsToRemove[i].quote][
                tokenPairsToRemove[i].oracleAdapter
            ].remove(vault);
        }

        uint256 length = l.supportedTokenPairs[vault].length;
        TokenPair[] memory newTokenPairs = new TokenPair[](length);

        uint256 count = 0;
        for (uint256 i = 0; i < length; i++) {
            if (!_containsTokenPair(tokenPairsToRemove, l.supportedTokenPairs[vault][i])) {
                newTokenPairs[count] = l.supportedTokenPairs[vault][i];
                count++;
            }
        }

        delete l.supportedTokenPairs[vault];

        for (uint256 i = 0; i < count; i++) {
            l.supportedTokenPairs[vault].push(newTokenPairs[i]);
        }
    }

    /// @inheritdoc IVaultRegistry
    function getVault(address vault) external view returns (Vault memory) {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();
        return l.vaults[vault];
    }

    /// @inheritdoc IVaultRegistry
    function getSupportedTokenPairs(address vault) external view returns (TokenPair[] memory) {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();
        return l.supportedTokenPairs[vault];
    }

    /// @notice Returns an array of vaults from a set of vault addresses
    function _getVaultsFromAddressSet(
        EnumerableSet.AddressSet storage vaultSet
    ) internal view returns (Vault[] memory) {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();

        uint256 length = vaultSet.length();
        Vault[] memory vaults = new Vault[](length);

        for (uint256 i = 0; i < length; i++) {
            vaults[i] = l.vaults[vaultSet.at(i)];
        }
        return vaults;
    }

    /// @inheritdoc IVaultRegistry
    function getVaults() external view returns (Vault[] memory) {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();
        return _getVaultsFromAddressSet(l.vaultAddresses);
    }

    /// @inheritdoc IVaultRegistry
    function getVaultsByFilter(
        address[] memory assets,
        TradeSide side,
        OptionType optionType
    ) external view returns (Vault[] memory) {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();

        uint256 length = l.vaultsByOptionType[optionType].length();
        Vault[] memory vaults = new Vault[](length);

        uint256 count;
        for (uint256 i = 0; i < length; i++) {
            Vault memory vault = l.vaults[l.vaultsByOptionType[optionType].at(i)];

            if (vault.side == side || vault.side == TradeSide.Both) {
                bool assetFound = false;

                if (assets.length == 0) {
                    assetFound = true;
                } else {
                    for (uint256 j = 0; j < assets.length; j++) {
                        if (vault.asset == assets[j]) {
                            assetFound = true;
                            break;
                        }
                    }
                }

                if (assetFound) {
                    vaults[count] = vault;
                    count++;
                }
            }
        }

        // Remove empty elements from array
        if (count < length) {
            assembly {
                mstore(vaults, count)
            }
        }

        return vaults;
    }

    /// @inheritdoc IVaultRegistry
    function getVaultsByAsset(address asset) external view returns (Vault[] memory) {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();
        return _getVaultsFromAddressSet(l.vaultsByAsset[asset]);
    }

    /// @inheritdoc IVaultRegistry
    function getVaultsByTokenPair(TokenPair memory tokenPair) external view returns (Vault[] memory) {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();
        return _getVaultsFromAddressSet(l.vaultsByTokenPair[tokenPair.base][tokenPair.quote][tokenPair.oracleAdapter]);
    }

    /// @inheritdoc IVaultRegistry
    function getVaultsByTradeSide(TradeSide side) external view returns (Vault[] memory) {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();
        return _getVaultsFromAddressSet(l.vaultsByTradeSide[side]);
    }

    /// @inheritdoc IVaultRegistry
    function getVaultsByOptionType(OptionType optionType) external view returns (Vault[] memory) {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();
        return _getVaultsFromAddressSet(l.vaultsByOptionType[optionType]);
    }

    /// @inheritdoc IVaultRegistry
    function getVaultsByType(bytes32 vaultType) external view returns (Vault[] memory) {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();
        return _getVaultsFromAddressSet(l.vaultsByType[vaultType]);
    }

    /// @inheritdoc IVaultRegistry
    function getImplementation(bytes32 vaultType) external view returns (address) {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();
        return l.implementations[vaultType];
    }

    /// @inheritdoc IVaultRegistry
    function setImplementation(bytes32 vaultType, address implementation) external onlyOwner {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();
        l.implementations[vaultType] = implementation;

        emit VaultImplementationSet(vaultType, implementation);
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

import {IVaultRegistry} from "./IVaultRegistry.sol";

library VaultRegistryStorage {
    using VaultRegistryStorage for VaultRegistryStorage.Layout;

    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.VaultRegistry");

    struct Layout {
        EnumerableSet.AddressSet vaultAddresses;
        mapping(bytes32 vaultType => bytes) __deprecated_settings;
        mapping(bytes32 vaultType => address) implementations;
        mapping(address vault => IVaultRegistry.Vault) vaults;
        mapping(address vault => IVaultRegistry.TokenPair[] supported) supportedTokenPairs;
        mapping(bytes32 vaultType => EnumerableSet.AddressSet vaults) vaultsByType;
        mapping(address asset => EnumerableSet.AddressSet vaults) vaultsByAsset;
        mapping(address base => mapping(address quote => mapping(address oracleAdapter => EnumerableSet.AddressSet vaults))) vaultsByTokenPair;
        mapping(IVaultRegistry.TradeSide tradeSide => EnumerableSet.AddressSet vaults) vaultsByTradeSide;
        mapping(IVaultRegistry.OptionType optionType => EnumerableSet.AddressSet vaults) vaultsByOptionType;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}