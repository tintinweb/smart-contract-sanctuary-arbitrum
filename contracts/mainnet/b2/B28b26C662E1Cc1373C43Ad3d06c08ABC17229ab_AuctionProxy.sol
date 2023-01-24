// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/access/ownable/SafeOwnable.sol";
import "@solidstate/contracts/access/ownable/OwnableStorage.sol";
import "@solidstate/contracts/proxy/upgradeable/UpgradeableProxyOwnable.sol";
import "@solidstate/contracts/proxy/upgradeable/UpgradeableProxyStorage.sol";

import "./AuctionStorage.sol";

/**
 * @title Knox Auction Proxy Contract
 * @dev contracts are upgradable
 */

contract AuctionProxy is SafeOwnable, UpgradeableProxyOwnable {
    using AuctionStorage for AuctionStorage.Layout;
    using OwnableStorage for OwnableStorage.Layout;
    using UpgradeableProxyStorage for UpgradeableProxyStorage.Layout;

    constructor(
        int128 deltaOffset64x64,
        uint256 minSize,
        address exchange,
        address pricer,
        address implementation
    ) {
        AuctionStorage.Layout storage l = AuctionStorage.layout();

        l.deltaOffset64x64 = deltaOffset64x64;
        l.minSize = minSize;
        l.Exchange = IExchangeHelper(exchange);
        l.Pricer = IPricer(pricer);

        OwnableStorage.layout().setOwner(msg.sender);
        UpgradeableProxyStorage.layout().setImplementation(implementation);
    }

    receive() external payable {}

    function _transferOwnership(address account)
        internal
        virtual
        override(OwnableInternal, SafeOwnable)
    {
        super._transferOwnership(account);
    }

    /**
     * @notice get address of implementation contract
     * @return implementation address
     */
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Ownable, OwnableStorage } from './Ownable.sol';
import { ISafeOwnable } from './ISafeOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { SafeOwnableInternal } from './SafeOwnableInternal.sol';

/**
 * @title Ownership access control based on ERC173 with ownership transfer safety check
 */
abstract contract SafeOwnable is ISafeOwnable, Ownable, SafeOwnableInternal {
    /**
     * @inheritdoc ISafeOwnable
     */
    function nomineeOwner() public view virtual returns (address) {
        return _nomineeOwner();
    }

    /**
     * @inheritdoc ISafeOwnable
     */
    function acceptOwnership() public virtual onlyNomineeOwner {
        _acceptOwnership();
    }

    function _transferOwnership(address account)
        internal
        virtual
        override(OwnableInternal, SafeOwnableInternal)
    {
        super._transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { OwnableInternal } from '../../access/ownable/OwnableInternal.sol';
import { IUpgradeableProxyOwnable } from './IUpgradeableProxyOwnable.sol';
import { UpgradeableProxy } from './UpgradeableProxy.sol';

/**
 * @title Proxy with upgradeable implementation controlled by ERC171 owner
 */
abstract contract UpgradeableProxyOwnable is
    IUpgradeableProxyOwnable,
    UpgradeableProxy,
    OwnableInternal
{
    /**
     * @notice set logic implementation address
     * @param implementation implementation address
     */
    function setImplementation(address implementation) external onlyOwner {
        _setImplementation(implementation);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library UpgradeableProxyStorage {
    struct Layout {
        address implementation;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.UpgradeableProxy');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setImplementation(Layout storage l, address implementation)
        internal
    {
        l.implementation = implementation;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/utils/EnumerableSet.sol";

import "../pricer/IPricer.sol";

import "../vendor/IExchangeHelper.sol";

import "./OrderBook.sol";

/**
 * @title Knox Dutch Auction Diamond Storage Library
 */

library AuctionStorage {
    using OrderBook for OrderBook.Index;

    struct InitAuction {
        uint64 epoch;
        uint64 expiry;
        int128 strike64x64;
        uint256 longTokenId;
        uint256 startTime;
        uint256 endTime;
    }

    enum Status {UNINITIALIZED, INITIALIZED, FINALIZED, PROCESSED, CANCELLED}

    struct Auction {
        // status of the auction
        Status status;
        // option expiration timestamp
        uint64 expiry;
        // option strike price
        int128 strike64x64;
        // auction max price
        int128 maxPrice64x64;
        // auction min price
        int128 minPrice64x64;
        // last price paid during the auction
        int128 lastPrice64x64;
        // auction start timestamp
        uint256 startTime;
        // auction end timestamp
        uint256 endTime;
        // auction processed timestamp
        uint256 processedTime;
        // total contracts available
        uint256 totalContracts;
        // total contracts sold
        uint256 totalContractsSold;
        // total unclaimed contracts
        uint256 totalUnclaimedContracts;
        // total premiums collected
        uint256 totalPremiums;
        // option long token id
        uint256 longTokenId;
    }

    struct Layout {
        // percent offset from delta strike
        int128 deltaOffset64x64;
        // minimum order size
        uint256 minSize;
        // mapping of auctions to epoch id (epoch id -> auction)
        mapping(uint64 => Auction) auctions;
        // mapping of order books to epoch id (epoch id -> order book)
        mapping(uint64 => OrderBook.Index) orderbooks;
        // mapping of unique order ids (uoids) to buyer addresses (buyer -> uoid)
        mapping(address => EnumerableSet.UintSet) uoids;
        // ExchangeHelper contract interface
        IExchangeHelper Exchange;
        // Pricer contract interface
        IPricer Pricer;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("knox.contracts.storage.Auction");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @notice returns the auction parameters
     * @param epoch epoch id
     * @return auction parameters
     */
    function _getAuction(uint64 epoch) internal view returns (Auction memory) {
        return layout().auctions[epoch];
    }

    /**
     * @notice returns percent delta offset
     * @return percent delta offset as a 64x64 fixed point number
     */
    function _getDeltaOffset64x64() internal view returns (int128) {
        return layout().deltaOffset64x64;
    }

    /**
     * @notice returns the minimum order size
     * @return minimum order size
     */
    function _getMinSize() internal view returns (uint256) {
        return layout().minSize;
    }

    /**
     * @notice returns the order from the auction orderbook
     * @param epoch epoch id
     * @param orderId order id
     * @return order from auction orderbook
     */
    function _getOrderById(uint64 epoch, uint128 orderId)
        internal
        view
        returns (OrderBook.Data memory)
    {
        OrderBook.Index storage orderbook = layout().orderbooks[epoch];
        return orderbook._getOrderById(orderId);
    }

    /**
     * @notice returns the status of the auction
     * @param epoch epoch id
     * @return auction status
     */
    function _getStatus(uint64 epoch)
        internal
        view
        returns (AuctionStorage.Status)
    {
        return layout().auctions[epoch].status;
    }

    /**
     * @notice returns the stored total number of contracts that can be sold during the auction
     * returns 0 if the auction has not started
     * @param epoch epoch id
     * @return total number of contracts which may be sold
     */
    function _getTotalContracts(uint64 epoch) internal view returns (uint256) {
        return layout().auctions[epoch].totalContracts;
    }

    /**
     * @notice returns the total number of contracts sold
     * @param epoch epoch id
     * @return total number of contracts sold
     */
    function _getTotalContractsSold(uint64 epoch)
        internal
        view
        returns (uint256)
    {
        return layout().auctions[epoch].totalContractsSold;
    }

    /************************************************
     * HELPERS
     ***********************************************/

    /**
     * @notice calculates the unique order id
     * @param epoch epoch id
     * @param orderId order id
     * @return unique order id
     */
    function _formatUniqueOrderId(uint64 epoch, uint128 orderId)
        internal
        view
        returns (uint256)
    {
        // uses the first 8 bytes of the contract address to salt uoid
        bytes8 salt = bytes8(bytes20(address(this)));
        return
            (uint256(uint64(salt)) << 192) +
            (uint256(epoch) << 128) +
            uint256(orderId);
    }

    /**
     * @notice derives salt, epoch id, and order id from the unique order id
     * @param uoid unique order id
     * @return salt
     * @return epoch id
     * @return order id
     */
    function _parseUniqueOrderId(uint256 uoid)
        internal
        pure
        returns (
            bytes8,
            uint64,
            uint128
        )
    {
        uint64 salt;
        uint64 epoch;
        uint128 orderId;

        assembly {
            salt := shr(192, uoid)
            epoch := shr(128, uoid)
            orderId := uoid
        }

        return (bytes8(salt), epoch, orderId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173 } from '../IERC173.sol';
import { IOwnable } from './IOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

/**
 * @title Ownership access control based on ERC173
 */
abstract contract Ownable is IOwnable, OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    /**
     * @inheritdoc IERC173
     */
    function owner() public view virtual returns (address) {
        return _owner();
    }

    /**
     * @inheritdoc IERC173
     */
    function transferOwnership(address account) public virtual onlyOwner {
        _transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnable } from './IOwnable.sol';

interface ISafeOwnable is IOwnable {
    /**
     * @notice get the nominated owner who has permission to call acceptOwnership
     */
    function nomineeOwner() external view returns (address);

    /**
     * @notice accept transfer of contract ownership
     */
    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(
            msg.sender == OwnableStorage.layout().owner,
            'Ownable: sender must be owner'
        );
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(msg.sender, account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ISafeOwnableInternal } from './ISafeOwnableInternal.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';
import { SafeOwnableStorage } from './SafeOwnableStorage.sol';

abstract contract SafeOwnableInternal is ISafeOwnableInternal, OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;
    using SafeOwnableStorage for SafeOwnableStorage.Layout;

    modifier onlyNomineeOwner() {
        require(
            msg.sender == _nomineeOwner(),
            'SafeOwnable: sender must be nominee owner'
        );
        _;
    }

    /**
     * @notice get the nominated owner who has permission to call acceptOwnership
     */
    function _nomineeOwner() internal view virtual returns (address) {
        return SafeOwnableStorage.layout().nomineeOwner;
    }

    /**
     * @notice accept transfer of contract ownership
     */
    function _acceptOwnership() internal virtual {
        OwnableStorage.Layout storage l = OwnableStorage.layout();
        emit OwnershipTransferred(l.owner, msg.sender);
        l.setOwner(msg.sender);
        SafeOwnableStorage.layout().setNomineeOwner(address(0));
    }

    /**
     * @notice set nominee owner, granting permission to call acceptOwnership
     */
    function _transferOwnership(address account) internal virtual override {
        SafeOwnableStorage.layout().setNomineeOwner(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return conrtact owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173 } from '../IERC173.sol';

interface IOwnable is IERC173 {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import { IERC173Internal } from '../IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnableInternal } from './IOwnableInternal.sol';

interface ISafeOwnableInternal is IOwnableInternal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeOwnableStorage {
    struct Layout {
        address nomineeOwner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.SafeOwnable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setNomineeOwner(Layout storage l, address nomineeOwner) internal {
        l.nomineeOwner = nomineeOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IUpgradeableProxy } from './IUpgradeableProxy.sol';

interface IUpgradeableProxyOwnable is IUpgradeableProxy {
    /**
     * TODO: add to IUpgradeableProxy or remove from here
     */
    function setImplementation(address implementation) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Proxy } from '../Proxy.sol';
import { IUpgradeableProxy } from './IUpgradeableProxy.sol';
import { UpgradeableProxyStorage } from './UpgradeableProxyStorage.sol';

/**
 * @title Proxy with upgradeable implementation
 */
abstract contract UpgradeableProxy is IUpgradeableProxy, Proxy {
    using UpgradeableProxyStorage for UpgradeableProxyStorage.Layout;

    /**
     * @inheritdoc Proxy
     */
    function _getImplementation() internal view override returns (address) {
        // inline storage layout retrieval uses less gas
        UpgradeableProxyStorage.Layout storage l;
        bytes32 slot = UpgradeableProxyStorage.STORAGE_SLOT;
        assembly {
            l.slot := slot
        }

        return l.implementation;
    }

    /**
     * @notice set logic implementation address
     * @param implementation implementation address
     */
    function _setImplementation(address implementation) internal {
        UpgradeableProxyStorage.layout().setImplementation(implementation);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IProxy } from '../IProxy.sol';

interface IUpgradeableProxy is IProxy {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IProxy {
    fallback() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '../utils/AddressUtils.sol';
import { IProxy } from './IProxy.sol';

/**
 * @title Base proxy contract
 */
abstract contract Proxy is IProxy {
    using AddressUtils for address;

    /**
     * @notice delegate all calls to implementation contract
     * @dev reverts if implementation address contains no code, for compatibility with metamorphic contracts
     * @dev memory location in use by assembly may be unsafe in other contexts
     */
    fallback() external payable virtual {
        address implementation = _getImplementation();

        require(
            implementation.isContract(),
            'Proxy: implementation must be contract'
        );

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @notice get logic implementation address
     * @return implementation address
     */
    function _getImplementation() internal virtual returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

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
        require(success, 'AddressUtils: failed to send value');
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        require(
            address(this).balance >= value,
            'AddressUtils: insufficient balance for call'
        );
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        require(
            isContract(target),
            'AddressUtils: function call to non-contract'
        );

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

pragma solidity ^0.8.0;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

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

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        require(value == 0, 'UintUtils: hex length insufficient');

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
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

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
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

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            'EnumerableSet: index out of bounds'
        );
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
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

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Knox Pricer Interface
 */

interface IPricer {
    /**
     * @notice gets the latest price of the underlying denominated in the base
     * @return price of underlying asset as 64x64 fixed point number
     */
    function latestAnswer64x64() external view returns (int128);

    /**
     * @notice calculates the time remaining until maturity
     * @param expiry the expiry date as UNIX timestamp
     * @return time remaining until maturity
     */
    function getTimeToMaturity64x64(uint64 expiry)
        external
        view
        returns (int128);

    /**
     * @notice gets the annualized volatility of the pool pair
     * @param spot64x64 spot price of the underlying as 64x64 fixed point number
     * @param strike64x64 strike price of the option as 64x64 fixed point number
     * @param timeToMaturity64x64 time remaining until maturity as a 64x64 fixed point number
     * @return annualized volatility as 64x64 fixed point number
     */
    function getAnnualizedVolatility64x64(
        int128 spot64x64,
        int128 strike64x64,
        int128 timeToMaturity64x64
    ) external view returns (int128);

    /**
     * @notice gets the option price using the Black-Scholes model
     * @param spot64x64 spot price of the underlying as 64x64 fixed point number
     * @param strike64x64 strike price of the option as 64x64 fixed point number
     * @param timeToMaturity64x64 time remaining until maturity as a 64x64 fixed point number
     * @param isCall option type, true if call option
     * @return price of the option denominated in the base as 64x64 fixed point number
     */
    function getBlackScholesPrice64x64(
        int128 spot64x64,
        int128 strike64x64,
        int128 timeToMaturity64x64,
        bool isCall
    ) external view returns (int128);

    /**
     * @notice calculates the delta strike price
     * @param isCall option type, true if call option
     * @param expiry the expiry date as UNIX timestamp
     * @param delta64x64 option delta as 64x64 fixed point number
     * @return delta strike price as 64x64 fixed point number
     */
    function getDeltaStrikePrice64x64(
        bool isCall,
        uint64 expiry,
        int128 delta64x64
    ) external view returns (int128);

    /**
     * @notice rounds a value to the floor or ceiling depending on option type
     * @param isCall option type, true if call option
     * @param n input value
     * @return rounded value as 64x64 fixed point number
     */
    function snapToGrid64x64(bool isCall, int128 n)
        external
        view
        returns (int128);
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @title Premia Exchange Helper
 * @dev deployed standalone and referenced by internal functions
 * @dev do NOT set approval to this contract!
 */
interface IExchangeHelper {
    struct SwapArgs {
        // token to pass in to swap
        address tokenIn;
        // amount of tokenIn to trade
        uint256 amountInMax;
        //min amount out to be used to purchase
        uint256 amountOutMin;
        // exchange address to call to execute the trade
        address callee;
        // address for which to set allowance for the trade
        address allowanceTarget;
        // data to execute the trade
        bytes data;
        // address to which refund excess tokens
        address refundAddress;
    }

    /**
     * @notice perform arbitrary swap transaction
     * @param sourceToken source token to pull into this address
     * @param targetToken target token to buy
     * @param pullAmount amount of source token to start the trade
     * @param callee exchange address to call to execute the trade.
     * @param allowanceTarget address for which to set allowance for the trade
     * @param data calldata to execute the trade
     * @param refundAddress address that un-used source token goes to
     * @return amountOut quantity of targetToken yielded by swap
     */
    function swapWithToken(
        address sourceToken,
        address targetToken,
        uint256 pullAmount,
        address callee,
        address allowanceTarget,
        bytes calldata data,
        address refundAddress
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Knox Auction Order Book Library
 * @dev based on PiperMerriam's Grove v0.3
 * https://github.com/pipermerriam/ethereum-grove
 */

library OrderBook {
    struct Index {
        uint256 head;
        uint256 length;
        uint256 root;
        mapping(uint256 => Order) orders;
    }

    struct Order {
        Data data;
        uint256 parent;
        uint256 left;
        uint256 right;
        uint256 height;
    }

    struct Data {
        uint256 id;
        int128 price64x64;
        uint256 size;
        address buyer;
    }

    /// @dev Retrieve the highest bid in the order book.
    /// @param index The index that the order is part of.
    function _head(Index storage index) internal view returns (uint256) {
        return index.head;
    }

    /// @dev Retrieve the number of bids in the order book.
    /// @param index The index that the order is part of.
    function _length(Index storage index) internal view returns (uint256) {
        return index.length;
    }

    /// @dev Retrieve the id, price, size, and buyer for the order.
    /// @param index The index that the order is part of.
    /// @param id The id for the order to be looked up.
    function _getOrderById(Index storage index, uint256 id)
        internal
        view
        returns (Data memory)
    {
        return index.orders[id].data;
    }

    /// @dev Returns the previous bid in descending order.
    /// @param index The index that the order is part of.
    /// @param id The id for the order to be looked up.
    function _getPreviousOrder(Index storage index, uint256 id)
        internal
        view
        returns (uint256)
    {
        Order storage currentOrder = index.orders[id];

        if (currentOrder.data.id == 0) {
            // Unknown order, just return 0;
            return 0;
        }

        Order memory child;

        if (currentOrder.left != 0) {
            // Trace left to latest child in left tree.
            child = index.orders[currentOrder.left];

            while (child.right != 0) {
                child = index.orders[child.right];
            }
            return child.data.id;
        }

        if (currentOrder.parent != 0) {
            // Now we trace back up through parent relationships, looking
            // for a link where the child is the right child of it's
            // parent.
            Order storage parent = index.orders[currentOrder.parent];
            child = currentOrder;

            while (true) {
                if (parent.right == child.data.id) {
                    return parent.data.id;
                }

                if (parent.parent == 0) {
                    break;
                }
                child = parent;
                parent = index.orders[parent.parent];
            }
        }

        // This is the first order, and has no previous order.
        return 0;
    }

    /// @dev Returns the next bid in descending order.
    /// @param index The index that the order is part of.
    /// @param id The id for the order to be looked up.
    function _getNextOrder(Index storage index, uint256 id)
        internal
        view
        returns (uint256)
    {
        Order storage currentOrder = index.orders[id];

        if (currentOrder.data.id == 0) {
            // Unknown order, just return 0;
            return 0;
        }

        Order memory child;

        if (currentOrder.right != 0) {
            // Trace right to earliest child in right tree.
            child = index.orders[currentOrder.right];

            while (child.left != 0) {
                child = index.orders[child.left];
            }
            return child.data.id;
        }

        if (currentOrder.parent != 0) {
            // if the order is the left child of it's parent, then the
            // parent is the next one.
            Order storage parent = index.orders[currentOrder.parent];
            child = currentOrder;

            while (true) {
                if (parent.left == child.data.id) {
                    return parent.data.id;
                }

                if (parent.parent == 0) {
                    break;
                }
                child = parent;
                parent = index.orders[parent.parent];
            }

            // Now we need to trace all the way up checking to see if any parent is the
        }

        // This is the final order.
        return 0;
    }

    /// @dev Updates or Inserts the id into the index at its appropriate location based on the price provided.
    /// @param index The index that the order is part of.
    // / @param id The unique identifier of the data element the index order will represent.
    /// @param price64x64 The unit price specified by the buyer.
    /// @param size The size specified by the buyer.
    /// @param buyer The buyers wallet address.
    function _insert(
        Index storage index,
        int128 price64x64,
        uint256 size,
        address buyer
    ) internal returns (uint256) {
        index.length = index.length + 1;
        uint256 id = index.length;

        Data memory data = _getOrderById(index, index.head);

        int128 highestPricePaid = data.price64x64;

        if (index.head == 0 || price64x64 > highestPricePaid) {
            index.head = id;
        }

        if (index.orders[id].data.id == id) {
            // A order with this id already exists.  If the price is
            // the same, then just return early, otherwise, remove it
            // and reinsert it.
            if (index.orders[id].data.price64x64 == price64x64) {
                return id;
            }
            _remove(index, id);
        }

        uint256 previousOrderId = 0;

        if (index.root == 0) {
            index.root = id;
        }
        Order storage currentOrder = index.orders[index.root];

        // Do insertion
        while (true) {
            if (currentOrder.data.id == 0) {
                // This is a new unpopulated order.
                currentOrder.data.id = id;
                currentOrder.parent = previousOrderId;
                currentOrder.data.price64x64 = price64x64;
                currentOrder.data.size = size;
                currentOrder.data.buyer = buyer;
                break;
            }

            // Set the previous order id.
            previousOrderId = currentOrder.data.id;

            // The new order belongs in the right subtree
            if (price64x64 <= currentOrder.data.price64x64) {
                if (currentOrder.right == 0) {
                    currentOrder.right = id;
                }
                currentOrder = index.orders[currentOrder.right];
                continue;
            }

            // The new order belongs in the left subtree.
            if (currentOrder.left == 0) {
                currentOrder.left = id;
            }
            currentOrder = index.orders[currentOrder.left];
        }

        // Rebalance the tree
        _rebalanceTree(index, currentOrder.data.id);

        return id;
    }

    /// @dev Remove the order for the given unique identifier from the index.
    /// @param index The index that should be removed
    /// @param id The unique identifier of the data element to remove.
    function _remove(Index storage index, uint256 id) internal returns (bool) {
        if (id == index.head) {
            index.head = _getNextOrder(index, id);
        }

        Order storage replacementOrder;
        Order storage parent;
        Order storage child;
        uint256 rebalanceOrigin;

        Order storage orderToDelete = index.orders[id];

        if (orderToDelete.data.id != id) {
            // The id does not exist in the tree.
            return false;
        }

        if (orderToDelete.left != 0 || orderToDelete.right != 0) {
            // This order is not a leaf order and thus must replace itself in
            // it's tree by either the previous or next order.
            if (orderToDelete.left != 0) {
                // This order is guaranteed to not have a right child.
                replacementOrder = index.orders[
                    _getPreviousOrder(index, orderToDelete.data.id)
                ];
            } else {
                // This order is guaranteed to not have a left child.
                replacementOrder = index.orders[
                    _getNextOrder(index, orderToDelete.data.id)
                ];
            }
            // The replacementOrder is guaranteed to have a parent.
            parent = index.orders[replacementOrder.parent];

            // Keep note of the location that our tree rebalancing should
            // start at.
            rebalanceOrigin = replacementOrder.data.id;

            // Join the parent of the replacement order with any subtree of
            // the replacement order.  We can guarantee that the replacement
            // order has at most one subtree because of how getNextOrder and
            // getPreviousOrder are used.
            if (parent.left == replacementOrder.data.id) {
                parent.left = replacementOrder.right;
                if (replacementOrder.right != 0) {
                    child = index.orders[replacementOrder.right];
                    child.parent = parent.data.id;
                }
            }
            if (parent.right == replacementOrder.data.id) {
                parent.right = replacementOrder.left;
                if (replacementOrder.left != 0) {
                    child = index.orders[replacementOrder.left];
                    child.parent = parent.data.id;
                }
            }

            // Now we replace the orderToDelete with the replacementOrder.
            // This includes parent/child relationships for all of the
            // parent, the left child, and the right child.
            replacementOrder.parent = orderToDelete.parent;
            if (orderToDelete.parent != 0) {
                parent = index.orders[orderToDelete.parent];
                if (parent.left == orderToDelete.data.id) {
                    parent.left = replacementOrder.data.id;
                }
                if (parent.right == orderToDelete.data.id) {
                    parent.right = replacementOrder.data.id;
                }
            } else {
                // If the order we are deleting is the root order update the
                // index root order pointer.
                index.root = replacementOrder.data.id;
            }

            replacementOrder.left = orderToDelete.left;
            if (orderToDelete.left != 0) {
                child = index.orders[orderToDelete.left];
                child.parent = replacementOrder.data.id;
            }

            replacementOrder.right = orderToDelete.right;
            if (orderToDelete.right != 0) {
                child = index.orders[orderToDelete.right];
                child.parent = replacementOrder.data.id;
            }
        } else if (orderToDelete.parent != 0) {
            // The order being deleted is a leaf order so we only erase it's
            // parent linkage.
            parent = index.orders[orderToDelete.parent];

            if (parent.left == orderToDelete.data.id) {
                parent.left = 0;
            }
            if (parent.right == orderToDelete.data.id) {
                parent.right = 0;
            }

            // keep note of where the rebalancing should begin.
            rebalanceOrigin = parent.data.id;
        } else {
            // This is both a leaf order and the root order, so we need to
            // unset the root order pointer.
            index.root = 0;
        }

        // Now we zero out all of the fields on the orderToDelete.
        orderToDelete.data.id = 0;
        orderToDelete.data.price64x64 = 0;
        orderToDelete.data.size = 0;
        orderToDelete.data.buyer = 0x0000000000000000000000000000000000000000;
        orderToDelete.parent = 0;
        orderToDelete.left = 0;
        orderToDelete.right = 0;
        orderToDelete.height = 0;

        // Walk back up the tree rebalancing
        if (rebalanceOrigin != 0) {
            _rebalanceTree(index, rebalanceOrigin);
        }

        return true;
    }

    function _rebalanceTree(Index storage index, uint256 id) private {
        // Trace back up rebalancing the tree and updating heights as
        // needed..
        Order storage currentOrder = index.orders[id];

        while (true) {
            int256 balanceFactor =
                _getBalanceFactor(index, currentOrder.data.id);

            if (balanceFactor == 2) {
                // Right rotation (tree is heavy on the left)
                if (_getBalanceFactor(index, currentOrder.left) == -1) {
                    // The subtree is leaning right so it need to be
                    // rotated left before the current order is rotated
                    // right.
                    _rotateLeft(index, currentOrder.left);
                }
                _rotateRight(index, currentOrder.data.id);
            }

            if (balanceFactor == -2) {
                // Left rotation (tree is heavy on the right)
                if (_getBalanceFactor(index, currentOrder.right) == 1) {
                    // The subtree is leaning left so it need to be
                    // rotated right before the current order is rotated
                    // left.
                    _rotateRight(index, currentOrder.right);
                }
                _rotateLeft(index, currentOrder.data.id);
            }

            if ((-1 <= balanceFactor) && (balanceFactor <= 1)) {
                _updateOrderHeight(index, currentOrder.data.id);
            }

            if (currentOrder.parent == 0) {
                // Reached the root which may be new due to tree
                // rotation, so set it as the root and then break.
                break;
            }

            currentOrder = index.orders[currentOrder.parent];
        }
    }

    function _getBalanceFactor(Index storage index, uint256 id)
        private
        view
        returns (int256)
    {
        Order storage order = index.orders[id];
        return
            int256(index.orders[order.left].height) -
            int256(index.orders[order.right].height);
    }

    function _updateOrderHeight(Index storage index, uint256 id) private {
        Order storage order = index.orders[id];
        order.height =
            _max(
                index.orders[order.left].height,
                index.orders[order.right].height
            ) +
            1;
    }

    function _max(uint256 a, uint256 b) private pure returns (uint256) {
        if (a >= b) {
            return a;
        }
        return b;
    }

    function _rotateLeft(Index storage index, uint256 id) private {
        Order storage originalRoot = index.orders[id];

        if (originalRoot.right == 0) {
            // Cannot rotate left if there is no right originalRoot to rotate into
            // place.
            revert();
        }

        // The right child is the new root, so it gets the original
        // `originalRoot.parent` as it's parent.
        Order storage newRoot = index.orders[originalRoot.right];
        newRoot.parent = originalRoot.parent;

        // The original root needs to have it's right child nulled out.
        originalRoot.right = 0;

        if (originalRoot.parent != 0) {
            // If there is a parent order, it needs to now point downward at
            // the newRoot which is rotating into the place where `order` was.
            Order storage parent = index.orders[originalRoot.parent];

            // figure out if we're a left or right child and have the
            // parent point to the new order.
            if (parent.left == originalRoot.data.id) {
                parent.left = newRoot.data.id;
            }
            if (parent.right == originalRoot.data.id) {
                parent.right = newRoot.data.id;
            }
        }

        if (newRoot.left != 0) {
            // If the new root had a left child, that moves to be the
            // new right child of the original root order
            Order storage leftChild = index.orders[newRoot.left];
            originalRoot.right = leftChild.data.id;
            leftChild.parent = originalRoot.data.id;
        }

        // Update the newRoot's left order to point at the original order.
        originalRoot.parent = newRoot.data.id;
        newRoot.left = originalRoot.data.id;

        if (newRoot.parent == 0) {
            index.root = newRoot.data.id;
        }

        _updateOrderHeight(index, originalRoot.data.id);
        _updateOrderHeight(index, newRoot.data.id);
    }

    function _rotateRight(Index storage index, uint256 id) private {
        Order storage originalRoot = index.orders[id];

        if (originalRoot.left == 0) {
            // Cannot rotate right if there is no left order to rotate into
            // place.
            revert();
        }

        // The left child is taking the place of order, so we update it's
        // parent to be the original parent of the order.
        Order storage newRoot = index.orders[originalRoot.left];
        newRoot.parent = originalRoot.parent;

        // Null out the originalRoot.left
        originalRoot.left = 0;

        if (originalRoot.parent != 0) {
            // If the order has a parent, update the correct child to point
            // at the newRoot now.
            Order storage parent = index.orders[originalRoot.parent];

            if (parent.left == originalRoot.data.id) {
                parent.left = newRoot.data.id;
            }
            if (parent.right == originalRoot.data.id) {
                parent.right = newRoot.data.id;
            }
        }

        if (newRoot.right != 0) {
            Order storage rightChild = index.orders[newRoot.right];
            originalRoot.left = newRoot.right;
            rightChild.parent = originalRoot.data.id;
        }

        // Update the new root's right order to point to the original order.
        originalRoot.parent = newRoot.data.id;
        newRoot.right = originalRoot.data.id;

        if (newRoot.parent == 0) {
            index.root = newRoot.data.id;
        }

        // Recompute heights.
        _updateOrderHeight(index, originalRoot.data.id);
        _updateOrderHeight(index, newRoot.data.id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}