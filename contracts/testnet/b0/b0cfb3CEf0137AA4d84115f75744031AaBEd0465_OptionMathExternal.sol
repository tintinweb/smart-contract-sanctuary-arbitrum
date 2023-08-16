// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);
  address public constant JPY = address(392);
  address public constant KRW = address(410);
  address public constant CNY = address(156);
  address public constant AUD = address(36);
  address public constant CAD = address(124);
  address public constant CHF = address(756);
  address public constant ARS = address(32);
  address public constant PHP = address(608);
  address public constant NZD = address(554);
  address public constant SGD = address(702);
  address public constant NGN = address(566);
  address public constant ZAR = address(710);
  address public constant RUB = address(643);
  address public constant INR = address(356);
  address public constant BRL = address(986);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';

interface IOwnable is IOwnableInternal, IERC173 {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from '../../interfaces/IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {
    error Ownable__NotOwner();
    error Ownable__NotTransitiveOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IOwnable } from './IOwnable.sol';
import { ISafeOwnableInternal } from './ISafeOwnableInternal.sol';

interface ISafeOwnable is ISafeOwnableInternal, IOwnable {
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

pragma solidity ^0.8.8;

import { IOwnableInternal } from './IOwnableInternal.sol';

interface ISafeOwnableInternal is IOwnableInternal {
    error SafeOwnable__NotNomineeOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { IOwnable } from './IOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';

/**
 * @title Ownership access control based on ERC173
 */
abstract contract Ownable is IOwnable, OwnableInternal {
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

import { Ownable } from './Ownable.sol';
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

    function _transferOwnership(
        address account
    ) internal virtual override(OwnableInternal, SafeOwnableInternal) {
        super._transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ISafeOwnableInternal } from './ISafeOwnableInternal.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { SafeOwnableStorage } from './SafeOwnableStorage.sol';

abstract contract SafeOwnableInternal is ISafeOwnableInternal, OwnableInternal {
    modifier onlyNomineeOwner() {
        if (msg.sender != _nomineeOwner())
            revert SafeOwnable__NotNomineeOwner();
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
        _setOwner(msg.sender);
        delete SafeOwnableStorage.layout().nomineeOwner;
    }

    /**
     * @notice grant permission to given address to claim contract ownership
     */
    function _transferOwnership(address account) internal virtual override {
        _setNomineeOwner(account);
    }

    /**
     * @notice set nominee owner
     */
    function _setNomineeOwner(address account) internal virtual {
        SafeOwnableStorage.layout().nomineeOwner = account;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Elliptic Curve Digital Signature Algorithm (ECDSA) operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library ECDSA {
    error ECDSA__InvalidS();
    error ECDSA__InvalidSignature();
    error ECDSA__InvalidSignatureLength();
    error ECDSA__InvalidV();

    /**
     * @notice recover signer of hashed message from signature
     * @param hash hashed data payload
     * @param signature signed data payload
     * @return recovered message signer
     */
    function recover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        if (signature.length != 65) revert ECDSA__InvalidSignatureLength();

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @notice recover signer of hashed message from signature v, r, and s values
     * @param hash hashed data payload
     * @param v signature "v" value
     * @param r signature "r" value
     * @param s signature "s" value
     * @return recovered message signer
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) revert ECDSA__InvalidS();
        if (v != 27 && v != 28) revert ECDSA__InvalidV();

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) revert ECDSA__InvalidSignature();

        return signer;
    }

    /**
     * @notice generate an "Ethereum Signed Message" in the format returned by the eth_sign JSON-RPC method
     * @param hash hashed data payload
     * @return signed message hash
     */
    function toEthSignedMessageHash(
        bytes32 hash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked('\x19Ethereum Signed Message:\n32', hash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title EIP-712 typed structured data hashing and signing
 * @dev see https://eips.ethereum.org/EIPS/eip-712
 */
library EIP712 {
    bytes32 internal constant EIP712_TYPE_HASH =
        keccak256(
            'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
        );

    /**
     * @notice calculate unique EIP-712 domain separator
     * @dev name and version inputs are hashed as required by EIP-712 because they are of dynamic-length types
     * @dev implementation of EIP712Domain struct type excludes the optional salt parameter
     * @param nameHash hash of human-readable signing domain name
     * @param versionHash hash of signing domain version
     * @return domainSeparator domain separator
     */
    function calculateDomainSeparator(
        bytes32 nameHash,
        bytes32 versionHash
    ) internal view returns (bytes32 domainSeparator) {
        // execute EIP-712 hashStruct procedure using assembly, equavalent to:
        //
        // domainSeparator = keccak256(
        //   abi.encode(
        //     EIP712_TYPE_HASH,
        //     nameHash,
        //     versionHash,
        //     block.chainid,
        //     address(this)
        //   )
        // );

        bytes32 typeHash = EIP712_TYPE_HASH;

        assembly {
            // load free memory pointer
            let pointer := mload(64)

            mstore(pointer, typeHash)
            mstore(add(pointer, 32), nameHash)
            mstore(add(pointer, 64), versionHash)
            mstore(add(pointer, 96), chainid())
            mstore(add(pointer, 128), address())

            domainSeparator := keccak256(pointer, 160)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Doubly linked list implementation with enumeration functions
 */
library DoublyLinkedList {
    struct DoublyLinkedListInternal {
        mapping(bytes32 => bytes32) _nextValues;
        mapping(bytes32 => bytes32) _prevValues;
    }

    struct Bytes32List {
        DoublyLinkedListInternal _inner;
    }

    struct AddressList {
        DoublyLinkedListInternal _inner;
    }

    struct Uint256List {
        DoublyLinkedListInternal _inner;
    }

    /**
     * @notice indicate that an attempt was made to insert 0 into a list
     */
    error DoublyLinkedList__InvalidInput();

    /**
     * @notice indicate that a non-existent value was used as a reference for insertion or lookup
     */
    error DoublyLinkedList__NonExistentEntry();

    function contains(
        Bytes32List storage self,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(self._inner, value);
    }

    function contains(
        AddressList storage self,
        address value
    ) internal view returns (bool) {
        return _contains(self._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        Uint256List storage self,
        uint256 value
    ) internal view returns (bool) {
        return _contains(self._inner, bytes32(value));
    }

    function prev(
        Bytes32List storage self,
        bytes32 value
    ) internal view returns (bytes32) {
        return _prev(self._inner, value);
    }

    function prev(
        AddressList storage self,
        address value
    ) internal view returns (address) {
        return
            address(
                uint160(
                    uint256(
                        _prev(self._inner, bytes32(uint256(uint160(value))))
                    )
                )
            );
    }

    function prev(
        Uint256List storage self,
        uint256 value
    ) internal view returns (uint256) {
        return uint256(_prev(self._inner, bytes32(value)));
    }

    function next(
        Bytes32List storage self,
        bytes32 value
    ) internal view returns (bytes32) {
        return _next(self._inner, value);
    }

    function next(
        AddressList storage self,
        address value
    ) internal view returns (address) {
        return
            address(
                uint160(
                    uint256(
                        _next(self._inner, bytes32(uint256(uint160(value))))
                    )
                )
            );
    }

    function next(
        Uint256List storage self,
        uint256 value
    ) internal view returns (uint256) {
        return uint256(_next(self._inner, bytes32(value)));
    }

    function insertBefore(
        Bytes32List storage self,
        bytes32 nextValue,
        bytes32 newValue
    ) internal returns (bool status) {
        status = _insertBefore(self._inner, nextValue, newValue);
    }

    function insertBefore(
        AddressList storage self,
        address nextValue,
        address newValue
    ) internal returns (bool status) {
        status = _insertBefore(
            self._inner,
            bytes32(uint256(uint160(nextValue))),
            bytes32(uint256(uint160(newValue)))
        );
    }

    function insertBefore(
        Uint256List storage self,
        uint256 nextValue,
        uint256 newValue
    ) internal returns (bool status) {
        status = _insertBefore(
            self._inner,
            bytes32(nextValue),
            bytes32(newValue)
        );
    }

    function insertAfter(
        Bytes32List storage self,
        bytes32 prevValue,
        bytes32 newValue
    ) internal returns (bool status) {
        status = _insertAfter(self._inner, prevValue, newValue);
    }

    function insertAfter(
        AddressList storage self,
        address prevValue,
        address newValue
    ) internal returns (bool status) {
        status = _insertAfter(
            self._inner,
            bytes32(uint256(uint160(prevValue))),
            bytes32(uint256(uint160(newValue)))
        );
    }

    function insertAfter(
        Uint256List storage self,
        uint256 prevValue,
        uint256 newValue
    ) internal returns (bool status) {
        status = _insertAfter(
            self._inner,
            bytes32(prevValue),
            bytes32(newValue)
        );
    }

    function push(
        Bytes32List storage self,
        bytes32 value
    ) internal returns (bool status) {
        status = _push(self._inner, value);
    }

    function push(
        AddressList storage self,
        address value
    ) internal returns (bool status) {
        status = _push(self._inner, bytes32(uint256(uint160(value))));
    }

    function push(
        Uint256List storage self,
        uint256 value
    ) internal returns (bool status) {
        status = _push(self._inner, bytes32(value));
    }

    function pop(Bytes32List storage self) internal returns (bytes32 value) {
        value = _pop(self._inner);
    }

    function pop(AddressList storage self) internal returns (address value) {
        value = address(uint160(uint256(_pop(self._inner))));
    }

    function pop(Uint256List storage self) internal returns (uint256 value) {
        value = uint256(_pop(self._inner));
    }

    function shift(Bytes32List storage self) internal returns (bytes32 value) {
        value = _shift(self._inner);
    }

    function shift(AddressList storage self) internal returns (address value) {
        value = address(uint160(uint256(_shift(self._inner))));
    }

    function shift(Uint256List storage self) internal returns (uint256 value) {
        value = uint256(_shift(self._inner));
    }

    function unshift(
        Bytes32List storage self,
        bytes32 value
    ) internal returns (bool status) {
        status = _unshift(self._inner, value);
    }

    function unshift(
        AddressList storage self,
        address value
    ) internal returns (bool status) {
        status = _unshift(self._inner, bytes32(uint256(uint160(value))));
    }

    function unshift(
        Uint256List storage self,
        uint256 value
    ) internal returns (bool status) {
        status = _unshift(self._inner, bytes32(value));
    }

    function remove(
        Bytes32List storage self,
        bytes32 value
    ) internal returns (bool status) {
        status = _remove(self._inner, value);
    }

    function remove(
        AddressList storage self,
        address value
    ) internal returns (bool status) {
        status = _remove(self._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        Uint256List storage self,
        uint256 value
    ) internal returns (bool status) {
        status = _remove(self._inner, bytes32(value));
    }

    function replace(
        Bytes32List storage self,
        bytes32 oldValue,
        bytes32 newValue
    ) internal returns (bool status) {
        status = _replace(self._inner, oldValue, newValue);
    }

    function replace(
        AddressList storage self,
        address oldValue,
        address newValue
    ) internal returns (bool status) {
        status = _replace(
            self._inner,
            bytes32(uint256(uint160(oldValue))),
            bytes32(uint256(uint160(newValue)))
        );
    }

    function replace(
        Uint256List storage self,
        uint256 oldValue,
        uint256 newValue
    ) internal returns (bool status) {
        status = _replace(self._inner, bytes32(oldValue), bytes32(newValue));
    }

    function _contains(
        DoublyLinkedListInternal storage self,
        bytes32 value
    ) private view returns (bool) {
        return
            value != 0 &&
            (self._nextValues[value] != 0 || self._prevValues[0] == value);
    }

    function _prev(
        DoublyLinkedListInternal storage self,
        bytes32 nextValue
    ) private view returns (bytes32 prevValue) {
        prevValue = self._prevValues[nextValue];
        if (
            nextValue != 0 &&
            prevValue == 0 &&
            _next(self, prevValue) != nextValue
        ) revert DoublyLinkedList__NonExistentEntry();
    }

    function _next(
        DoublyLinkedListInternal storage self,
        bytes32 prevValue
    ) private view returns (bytes32 nextValue) {
        nextValue = self._nextValues[prevValue];
        if (
            prevValue != 0 &&
            nextValue == 0 &&
            _prev(self, nextValue) != prevValue
        ) revert DoublyLinkedList__NonExistentEntry();
    }

    function _insertBefore(
        DoublyLinkedListInternal storage self,
        bytes32 nextValue,
        bytes32 newValue
    ) private returns (bool status) {
        status = _insertBetween(
            self,
            _prev(self, nextValue),
            nextValue,
            newValue
        );
    }

    function _insertAfter(
        DoublyLinkedListInternal storage self,
        bytes32 prevValue,
        bytes32 newValue
    ) private returns (bool status) {
        status = _insertBetween(
            self,
            prevValue,
            _next(self, prevValue),
            newValue
        );
    }

    function _insertBetween(
        DoublyLinkedListInternal storage self,
        bytes32 prevValue,
        bytes32 nextValue,
        bytes32 newValue
    ) private returns (bool status) {
        if (newValue == 0) revert DoublyLinkedList__InvalidInput();

        if (!_contains(self, newValue)) {
            _link(self, prevValue, newValue);
            _link(self, newValue, nextValue);
            status = true;
        }
    }

    function _push(
        DoublyLinkedListInternal storage self,
        bytes32 value
    ) private returns (bool status) {
        status = _insertBetween(self, _prev(self, 0), 0, value);
    }

    function _pop(
        DoublyLinkedListInternal storage self
    ) private returns (bytes32 value) {
        value = _prev(self, 0);
        _remove(self, value);
    }

    function _shift(
        DoublyLinkedListInternal storage self
    ) private returns (bytes32 value) {
        value = _next(self, 0);
        _remove(self, value);
    }

    function _unshift(
        DoublyLinkedListInternal storage self,
        bytes32 value
    ) private returns (bool status) {
        status = _insertBetween(self, 0, _next(self, 0), value);
    }

    function _remove(
        DoublyLinkedListInternal storage self,
        bytes32 value
    ) private returns (bool status) {
        if (_contains(self, value)) {
            _link(self, _prev(self, value), _next(self, value));
            delete self._prevValues[value];
            delete self._nextValues[value];
            status = true;
        }
    }

    function _replace(
        DoublyLinkedListInternal storage self,
        bytes32 oldValue,
        bytes32 newValue
    ) private returns (bool status) {
        if (!_contains(self, oldValue))
            revert DoublyLinkedList__NonExistentEntry();

        status = _insertBetween(
            self,
            _prev(self, oldValue),
            _next(self, oldValue),
            newValue
        );

        if (status) {
            delete self._prevValues[oldValue];
            delete self._nextValues[oldValue];
        }
    }

    function _link(
        DoublyLinkedListInternal storage self,
        bytes32 prevValue,
        bytes32 nextValue
    ) private {
        self._nextValues[prevValue] = nextValue;
        self._prevValues[nextValue] = prevValue;
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

interface IERC3156FlashBorrower {
    /**
     * @notice Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import './IERC3156FlashBorrower.sol';

interface IERC3156FlashLender {
    /**
     * @notice The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @notice The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @notice Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Metadata } from '../token/ERC20/metadata/IERC20Metadata.sol';
import { IERC20 } from './IERC20.sol';
import { IERC4626Internal } from './IERC4626Internal.sol';

/**
 * @title ERC4626 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-4626
 */
interface IERC4626 is IERC4626Internal, IERC20, IERC20Metadata {
    /**
     * @notice get the address of the base token used for vault accountin purposes
     * @return base token address
     */
    function asset() external view returns (address);

    /**
     * @notice get the total quantity of the base asset currently managed by the vault
     * @return total managed asset amount
     */
    function totalAssets() external view returns (uint256);

    /**
     * @notice calculate the quantity of shares received in exchange for a given quantity of assets, not accounting for slippage
     * @param assetAmount quantity of assets to convert
     * @return shareAmount quantity of shares calculated
     */
    function convertToShares(
        uint256 assetAmount
    ) external view returns (uint256 shareAmount);

    /**
     * @notice calculate the quantity of assets received in exchange for a given quantity of shares, not accounting for slippage
     * @param shareAmount quantity of shares to convert
     * @return assetAmount quantity of assets calculated
     */
    function convertToAssets(
        uint256 shareAmount
    ) external view returns (uint256 assetAmount);

    /**
     * @notice calculate the maximum quantity of base assets which may be deposited on behalf of given receiver
     * @param receiver recipient of shares resulting from deposit
     * @return maxAssets maximum asset deposit amount
     */
    function maxDeposit(
        address receiver
    ) external view returns (uint256 maxAssets);

    /**
     * @notice calculate the maximum quantity of shares which may be minted on behalf of given receiver
     * @param receiver recipient of shares resulting from deposit
     * @return maxShares maximum share mint amount
     */
    function maxMint(
        address receiver
    ) external view returns (uint256 maxShares);

    /**
     * @notice calculate the maximum quantity of base assets which may be withdrawn by given holder
     * @param owner holder of shares to be redeemed
     * @return maxAssets maximum asset mint amount
     */
    function maxWithdraw(
        address owner
    ) external view returns (uint256 maxAssets);

    /**
     * @notice calculate the maximum quantity of shares which may be redeemed by given holder
     * @param owner holder of shares to be redeemed
     * @return maxShares maximum share redeem amount
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @notice simulate a deposit of given quantity of assets
     * @param assetAmount quantity of assets to deposit
     * @return shareAmount quantity of shares to mint
     */
    function previewDeposit(
        uint256 assetAmount
    ) external view returns (uint256 shareAmount);

    /**
     * @notice simulate a minting of given quantity of shares
     * @param shareAmount quantity of shares to mint
     * @return assetAmount quantity of assets to deposit
     */
    function previewMint(
        uint256 shareAmount
    ) external view returns (uint256 assetAmount);

    /**
     * @notice simulate a withdrawal of given quantity of assets
     * @param assetAmount quantity of assets to withdraw
     * @return shareAmount quantity of shares to redeem
     */
    function previewWithdraw(
        uint256 assetAmount
    ) external view returns (uint256 shareAmount);

    /**
     * @notice simulate a redemption of given quantity of shares
     * @param shareAmount quantity of shares to redeem
     * @return assetAmount quantity of assets to withdraw
     */
    function previewRedeem(
        uint256 shareAmount
    ) external view returns (uint256 assetAmount);

    /**
     * @notice execute a deposit of assets on behalf of given address
     * @param assetAmount quantity of assets to deposit
     * @param receiver recipient of shares resulting from deposit
     * @return shareAmount quantity of shares to mint
     */
    function deposit(
        uint256 assetAmount,
        address receiver
    ) external returns (uint256 shareAmount);

    /**
     * @notice execute a minting of shares on behalf of given address
     * @param shareAmount quantity of shares to mint
     * @param receiver recipient of shares resulting from deposit
     * @return assetAmount quantity of assets to deposit
     */
    function mint(
        uint256 shareAmount,
        address receiver
    ) external returns (uint256 assetAmount);

    /**
     * @notice execute a withdrawal of assets on behalf of given address
     * @param assetAmount quantity of assets to withdraw
     * @param receiver recipient of assets resulting from withdrawal
     * @param owner holder of shares to be redeemed
     * @return shareAmount quantity of shares to redeem
     */
    function withdraw(
        uint256 assetAmount,
        address receiver,
        address owner
    ) external returns (uint256 shareAmount);

    /**
     * @notice execute a redemption of shares on behalf of given address
     * @param shareAmount quantity of shares to redeem
     * @param receiver recipient of assets resulting from withdrawal
     * @param owner holder of shares to be redeemed
     * @return assetAmount quantity of assets to withdraw
     */
    function redeem(
        uint256 shareAmount,
        address receiver,
        address owner
    ) external returns (uint256 assetAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC4626 interface needed by internal functions
 */
interface IERC4626Internal {
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from '../../../interfaces/IERC165.sol';
import { IERC165Base } from './IERC165Base.sol';
import { ERC165BaseInternal } from './ERC165BaseInternal.sol';
import { ERC165BaseStorage } from './ERC165BaseStorage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165Base is IERC165Base, ERC165BaseInternal {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165BaseInternal } from './IERC165BaseInternal.sol';
import { ERC165BaseStorage } from './ERC165BaseStorage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165BaseInternal is IERC165BaseInternal {
    /**
     * @notice indicates whether an interface is already supported based on the interfaceId
     * @param interfaceId id of interface to check
     * @return bool indicating whether interface is supported
     */
    function _supportsInterface(
        bytes4 interfaceId
    ) internal view virtual returns (bool) {
        return ERC165BaseStorage.layout().supportedInterfaces[interfaceId];
    }

    /**
     * @notice sets status of interface support
     * @param interfaceId id of interface to set status for
     * @param status boolean indicating whether interface will be set as supported
     */
    function _setSupportsInterface(
        bytes4 interfaceId,
        bool status
    ) internal virtual {
        if (interfaceId == 0xffffffff) revert ERC165Base__InvalidInterfaceId();
        ERC165BaseStorage.layout().supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC165BaseStorage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../../interfaces/IERC165.sol';
import { IERC165BaseInternal } from './IERC165BaseInternal.sol';

interface IERC165Base is IERC165, IERC165BaseInternal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165Internal } from '../../../interfaces/IERC165Internal.sol';

interface IERC165BaseInternal is IERC165Internal {
    error ERC165Base__InvalidInterfaceId();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { Proxy } from '../../Proxy.sol';
import { IDiamondBase } from './IDiamondBase.sol';
import { DiamondBaseStorage } from './DiamondBaseStorage.sol';

/**
 * @title EIP-2535 "Diamond" proxy base contract
 * @dev see https://eips.ethereum.org/EIPS/eip-2535
 */
abstract contract DiamondBase is IDiamondBase, Proxy {
    /**
     * @inheritdoc Proxy
     */
    function _getImplementation()
        internal
        view
        virtual
        override
        returns (address implementation)
    {
        // inline storage layout retrieval uses less gas
        DiamondBaseStorage.Layout storage l;
        bytes32 slot = DiamondBaseStorage.STORAGE_SLOT;
        assembly {
            l.slot := slot
        }

        implementation = address(bytes20(l.facets[msg.sig]));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @dev derived from https://github.com/mudgen/diamond-2 (MIT license)
 */
library DiamondBaseStorage {
    struct Layout {
        // function selector => (facet address, selector slot position)
        mapping(bytes4 => bytes32) facets;
        // total number of selectors registered
        uint16 selectorCount;
        // array of selector slots with 8 selectors per slot
        mapping(uint256 => bytes32) selectorSlots;
        address fallbackAddress;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.DiamondBase');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IProxy } from '../../IProxy.sol';

interface IDiamondBase is IProxy {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { OwnableInternal } from '../../../access/ownable/OwnableInternal.sol';
import { DiamondBase } from '../base/DiamondBase.sol';
import { DiamondBaseStorage } from '../base/DiamondBaseStorage.sol';
import { IDiamondFallback } from './IDiamondFallback.sol';

/**
 * @title Fallback feature for EIP-2535 "Diamond" proxy
 */
abstract contract DiamondFallback is
    IDiamondFallback,
    OwnableInternal,
    DiamondBase
{
    /**
     * @inheritdoc IDiamondFallback
     */
    function getFallbackAddress()
        external
        view
        returns (address fallbackAddress)
    {
        fallbackAddress = _getFallbackAddress();
    }

    /**
     * @inheritdoc IDiamondFallback
     */
    function setFallbackAddress(address fallbackAddress) external onlyOwner {
        _setFallbackAddress(fallbackAddress);
    }

    /**
     * @inheritdoc DiamondBase
     * @notice query custom fallback address is no implementation is found
     */
    function _getImplementation()
        internal
        view
        virtual
        override
        returns (address implementation)
    {
        implementation = super._getImplementation();

        if (implementation == address(0)) {
            implementation = _getFallbackAddress();
        }
    }

    /**
     * @notice query the address of the fallback implementation
     * @return fallbackAddress address of fallback implementation
     */
    function _getFallbackAddress()
        internal
        view
        virtual
        returns (address fallbackAddress)
    {
        fallbackAddress = DiamondBaseStorage.layout().fallbackAddress;
    }

    /**
     * @notice set the address of the fallback implementation
     * @param fallbackAddress address of fallback implementation
     */
    function _setFallbackAddress(address fallbackAddress) internal virtual {
        DiamondBaseStorage.layout().fallbackAddress = fallbackAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IDiamondBase } from '../base/IDiamondBase.sol';

interface IDiamondFallback is IDiamondBase {
    /**
     * @notice query the address of the fallback implementation
     * @return fallbackAddress address of fallback implementation
     */
    function getFallbackAddress()
        external
        view
        returns (address fallbackAddress);

    /**
     * @notice set the address of the fallback implementation
     * @param fallbackAddress address of fallback implementation
     */
    function setFallbackAddress(address fallbackAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ISafeOwnable } from '../../access/ownable/ISafeOwnable.sol';
import { IERC165 } from '../../interfaces/IERC165.sol';
import { IDiamondBase } from './base/IDiamondBase.sol';
import { IDiamondFallback } from './fallback/IDiamondFallback.sol';
import { IDiamondReadable } from './readable/IDiamondReadable.sol';
import { IDiamondWritable } from './writable/IDiamondWritable.sol';

interface ISolidStateDiamond is
    IDiamondBase,
    IDiamondFallback,
    IDiamondReadable,
    IDiamondWritable,
    ISafeOwnable,
    IERC165
{
    receive() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { DiamondBaseStorage } from '../base/DiamondBaseStorage.sol';
import { IDiamondReadable } from './IDiamondReadable.sol';

/**
 * @title EIP-2535 "Diamond" proxy introspection contract
 * @dev derived from https://github.com/mudgen/diamond-2 (MIT license)
 */
abstract contract DiamondReadable is IDiamondReadable {
    /**
     * @inheritdoc IDiamondReadable
     */
    function facets() external view returns (Facet[] memory diamondFacets) {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        diamondFacets = new Facet[](l.selectorCount);

        uint8[] memory numFacetSelectors = new uint8[](l.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;

        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < l.selectorCount; slotIndex++) {
            bytes32 slot = l.selectorSlots[slotIndex];

            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;

                if (selectorIndex > l.selectorCount) {
                    break;
                }

                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facet = address(bytes20(l.facets[selector]));

                bool continueLoop;

                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (diamondFacets[facetIndex].target == facet) {
                        diamondFacets[facetIndex].selectors[
                            numFacetSelectors[facetIndex]
                        ] = selector;
                        // probably will never have more than 256 functions from one facet contract
                        require(numFacetSelectors[facetIndex] < 255);
                        numFacetSelectors[facetIndex]++;
                        continueLoop = true;
                        break;
                    }
                }

                if (continueLoop) {
                    continue;
                }

                diamondFacets[numFacets].target = facet;
                diamondFacets[numFacets].selectors = new bytes4[](
                    l.selectorCount
                );
                diamondFacets[numFacets].selectors[0] = selector;
                numFacetSelectors[numFacets] = 1;
                numFacets++;
            }
        }

        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = diamondFacets[facetIndex].selectors;

            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }

        // setting the number of facets
        assembly {
            mstore(diamondFacets, numFacets)
        }
    }

    /**
     * @inheritdoc IDiamondReadable
     */
    function facetFunctionSelectors(
        address facet
    ) external view returns (bytes4[] memory selectors) {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        selectors = new bytes4[](l.selectorCount);

        uint256 numSelectors;
        uint256 selectorIndex;

        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < l.selectorCount; slotIndex++) {
            bytes32 slot = l.selectorSlots[slotIndex];

            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;

                if (selectorIndex > l.selectorCount) {
                    break;
                }

                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));

                if (facet == address(bytes20(l.facets[selector]))) {
                    selectors[numSelectors] = selector;
                    numSelectors++;
                }
            }
        }

        // set the number of selectors in the array
        assembly {
            mstore(selectors, numSelectors)
        }
    }

    /**
     * @inheritdoc IDiamondReadable
     */
    function facetAddresses()
        external
        view
        returns (address[] memory addresses)
    {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        addresses = new address[](l.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;

        for (uint256 slotIndex; selectorIndex < l.selectorCount; slotIndex++) {
            bytes32 slot = l.selectorSlots[slotIndex];

            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;

                if (selectorIndex > l.selectorCount) {
                    break;
                }

                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facet = address(bytes20(l.facets[selector]));

                bool continueLoop;

                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facet == addresses[facetIndex]) {
                        continueLoop = true;
                        break;
                    }
                }

                if (continueLoop) {
                    continue;
                }

                addresses[numFacets] = facet;
                numFacets++;
            }
        }

        // set the number of facet addresses in the array
        assembly {
            mstore(addresses, numFacets)
        }
    }

    /**
     * @inheritdoc IDiamondReadable
     */
    function facetAddress(
        bytes4 selector
    ) external view returns (address facet) {
        facet = address(bytes20(DiamondBaseStorage.layout().facets[selector]));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Diamond proxy introspection interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2535
 */
interface IDiamondReadable {
    struct Facet {
        address target;
        bytes4[] selectors;
    }

    /**
     * @notice get all facets and their selectors
     * @return diamondFacets array of structured facet data
     */
    function facets() external view returns (Facet[] memory diamondFacets);

    /**
     * @notice get all selectors for given facet address
     * @param facet address of facet to query
     * @return selectors array of function selectors
     */
    function facetFunctionSelectors(
        address facet
    ) external view returns (bytes4[] memory selectors);

    /**
     * @notice get addresses of all facets used by diamond
     * @return addresses array of facet addresses
     */
    function facetAddresses()
        external
        view
        returns (address[] memory addresses);

    /**
     * @notice get the address of the facet associated with given selector
     * @param selector function selector to query
     * @return facet facet address (zero address if not found)
     */
    function facetAddress(
        bytes4 selector
    ) external view returns (address facet);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IOwnable, Ownable, OwnableInternal } from '../../access/ownable/Ownable.sol';
import { ISafeOwnable, SafeOwnable } from '../../access/ownable/SafeOwnable.sol';
import { IERC165 } from '../../interfaces/IERC165.sol';
import { IERC173 } from '../../interfaces/IERC173.sol';
import { ERC165Base, ERC165BaseStorage } from '../../introspection/ERC165/base/ERC165Base.sol';
import { DiamondBase } from './base/DiamondBase.sol';
import { DiamondFallback, IDiamondFallback } from './fallback/DiamondFallback.sol';
import { DiamondReadable, IDiamondReadable } from './readable/DiamondReadable.sol';
import { DiamondWritable, IDiamondWritable } from './writable/DiamondWritable.sol';
import { ISolidStateDiamond } from './ISolidStateDiamond.sol';

/**
 * @title SolidState "Diamond" proxy reference implementation
 */
abstract contract SolidStateDiamond is
    ISolidStateDiamond,
    DiamondBase,
    DiamondFallback,
    DiamondReadable,
    DiamondWritable,
    SafeOwnable,
    ERC165Base
{
    constructor() {
        bytes4[] memory selectors = new bytes4[](12);
        uint256 selectorIndex;

        // register DiamondFallback

        selectors[selectorIndex++] = IDiamondFallback
            .getFallbackAddress
            .selector;
        selectors[selectorIndex++] = IDiamondFallback
            .setFallbackAddress
            .selector;

        _setSupportsInterface(type(IDiamondFallback).interfaceId, true);

        // register DiamondWritable

        selectors[selectorIndex++] = IDiamondWritable.diamondCut.selector;

        _setSupportsInterface(type(IDiamondWritable).interfaceId, true);

        // register DiamondReadable

        selectors[selectorIndex++] = IDiamondReadable.facets.selector;
        selectors[selectorIndex++] = IDiamondReadable
            .facetFunctionSelectors
            .selector;
        selectors[selectorIndex++] = IDiamondReadable.facetAddresses.selector;
        selectors[selectorIndex++] = IDiamondReadable.facetAddress.selector;

        _setSupportsInterface(type(IDiamondReadable).interfaceId, true);

        // register ERC165

        selectors[selectorIndex++] = IERC165.supportsInterface.selector;

        _setSupportsInterface(type(IERC165).interfaceId, true);

        // register SafeOwnable

        selectors[selectorIndex++] = Ownable.owner.selector;
        selectors[selectorIndex++] = SafeOwnable.nomineeOwner.selector;
        selectors[selectorIndex++] = Ownable.transferOwnership.selector;
        selectors[selectorIndex++] = SafeOwnable.acceptOwnership.selector;

        _setSupportsInterface(type(IERC173).interfaceId, true);

        // diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({
            target: address(this),
            action: FacetCutAction.ADD,
            selectors: selectors
        });

        _diamondCut(facetCuts, address(0), '');

        // set owner

        _setOwner(msg.sender);
    }

    receive() external payable {}

    function _transferOwnership(
        address account
    ) internal virtual override(OwnableInternal, SafeOwnable) {
        super._transferOwnership(account);
    }

    /**
     * @inheritdoc DiamondFallback
     */
    function _getImplementation()
        internal
        view
        override(DiamondBase, DiamondFallback)
        returns (address implementation)
    {
        implementation = super._getImplementation();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { OwnableInternal } from '../../../access/ownable/OwnableInternal.sol';
import { IDiamondWritable } from './IDiamondWritable.sol';
import { DiamondWritableInternal } from './DiamondWritableInternal.sol';

/**
 * @title EIP-2535 "Diamond" proxy update contract
 */
abstract contract DiamondWritable is
    IDiamondWritable,
    DiamondWritableInternal,
    OwnableInternal
{
    /**
     * @inheritdoc IDiamondWritable
     */
    function diamondCut(
        FacetCut[] calldata facetCuts,
        address target,
        bytes calldata data
    ) external onlyOwner {
        _diamondCut(facetCuts, target, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { DiamondBaseStorage } from '../base/DiamondBaseStorage.sol';
import { IDiamondWritableInternal } from './IDiamondWritableInternal.sol';

abstract contract DiamondWritableInternal is IDiamondWritableInternal {
    using AddressUtils for address;

    bytes32 private constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 private constant CLEAR_SELECTOR_MASK =
        bytes32(uint256(0xffffffff << 224));

    /**
     * @notice update functions callable on Diamond proxy
     * @param facetCuts array of structured Diamond facet update data
     * @param target optional recipient of initialization delegatecall
     * @param data optional initialization call data
     */
    function _diamondCut(
        FacetCut[] memory facetCuts,
        address target,
        bytes memory data
    ) internal {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        unchecked {
            uint256 originalSelectorCount = l.selectorCount;
            uint256 selectorCount = originalSelectorCount;
            bytes32 selectorSlot;

            // Check if last selector slot is not full
            if (selectorCount & 7 > 0) {
                // get last selectorSlot
                selectorSlot = l.selectorSlots[selectorCount >> 3];
            }

            for (uint256 i; i < facetCuts.length; i++) {
                FacetCut memory facetCut = facetCuts[i];
                FacetCutAction action = facetCut.action;

                if (facetCut.selectors.length == 0)
                    revert DiamondWritable__SelectorNotSpecified();

                if (action == FacetCutAction.ADD) {
                    (selectorCount, selectorSlot) = _addFacetSelectors(
                        l,
                        selectorCount,
                        selectorSlot,
                        facetCut
                    );
                } else if (action == FacetCutAction.REPLACE) {
                    _replaceFacetSelectors(l, facetCut);
                } else if (action == FacetCutAction.REMOVE) {
                    (selectorCount, selectorSlot) = _removeFacetSelectors(
                        l,
                        selectorCount,
                        selectorSlot,
                        facetCut
                    );
                }
            }

            if (selectorCount != originalSelectorCount) {
                l.selectorCount = uint16(selectorCount);
            }

            // If last selector slot is not full
            if (selectorCount & 7 > 0) {
                l.selectorSlots[selectorCount >> 3] = selectorSlot;
            }

            emit DiamondCut(facetCuts, target, data);
            _initialize(target, data);
        }
    }

    function _addFacetSelectors(
        DiamondBaseStorage.Layout storage l,
        uint256 selectorCount,
        bytes32 selectorSlot,
        FacetCut memory facetCut
    ) internal returns (uint256, bytes32) {
        unchecked {
            if (
                facetCut.target != address(this) &&
                !facetCut.target.isContract()
            ) revert DiamondWritable__TargetHasNoCode();

            for (uint256 i; i < facetCut.selectors.length; i++) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = l.facets[selector];

                if (address(bytes20(oldFacet)) != address(0))
                    revert DiamondWritable__SelectorAlreadyAdded();

                // add facet for selector
                l.facets[selector] =
                    bytes20(facetCut.target) |
                    bytes32(selectorCount);
                uint256 selectorInSlotPosition = (selectorCount & 7) << 5;

                // clear selector position in slot and add selector
                selectorSlot =
                    (selectorSlot &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);

                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    l.selectorSlots[selectorCount >> 3] = selectorSlot;
                    selectorSlot = 0;
                }

                selectorCount++;
            }

            return (selectorCount, selectorSlot);
        }
    }

    function _removeFacetSelectors(
        DiamondBaseStorage.Layout storage l,
        uint256 selectorCount,
        bytes32 selectorSlot,
        FacetCut memory facetCut
    ) internal returns (uint256, bytes32) {
        unchecked {
            if (facetCut.target != address(0))
                revert DiamondWritable__RemoveTargetNotZeroAddress();

            uint256 selectorSlotCount = selectorCount >> 3;
            uint256 selectorInSlotIndex = selectorCount & 7;

            for (uint256 i; i < facetCut.selectors.length; i++) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = l.facets[selector];

                if (address(bytes20(oldFacet)) == address(0))
                    revert DiamondWritable__SelectorNotFound();

                if (address(bytes20(oldFacet)) == address(this))
                    revert DiamondWritable__SelectorIsImmutable();

                if (selectorSlot == 0) {
                    selectorSlotCount--;
                    selectorSlot = l.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }

                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;

                // adding a block here prevents stack too deep error
                {
                    // replace selector with last selector in l.facets
                    lastSelector = bytes4(
                        selectorSlot << (selectorInSlotIndex << 5)
                    );

                    if (lastSelector != selector) {
                        // update last selector slot position info
                        l.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(l.facets[lastSelector]);
                    }

                    delete l.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }

                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = l.selectorSlots[
                        oldSelectorsSlotCount
                    ];

                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);

                    // update storage with the modified slot
                    l.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    selectorSlot =
                        (selectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }

                if (selectorInSlotIndex == 0) {
                    delete l.selectorSlots[selectorSlotCount];
                    selectorSlot = 0;
                }
            }

            selectorCount = (selectorSlotCount << 3) | selectorInSlotIndex;

            return (selectorCount, selectorSlot);
        }
    }

    function _replaceFacetSelectors(
        DiamondBaseStorage.Layout storage l,
        FacetCut memory facetCut
    ) internal {
        unchecked {
            if (!facetCut.target.isContract())
                revert DiamondWritable__TargetHasNoCode();

            for (uint256 i; i < facetCut.selectors.length; i++) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = l.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));

                if (oldFacetAddress == address(0))
                    revert DiamondWritable__SelectorNotFound();
                if (oldFacetAddress == address(this))
                    revert DiamondWritable__SelectorIsImmutable();
                if (oldFacetAddress == facetCut.target)
                    revert DiamondWritable__ReplaceTargetIsIdentical();

                // replace old facet address
                l.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(facetCut.target);
            }
        }
    }

    function _initialize(address target, bytes memory data) private {
        if ((target == address(0)) != (data.length == 0))
            revert DiamondWritable__InvalidInitializationParameters();

        if (target != address(0)) {
            if (target != address(this)) {
                if (!target.isContract())
                    revert DiamondWritable__TargetHasNoCode();
            }

            (bool success, ) = target.delegatecall(data);

            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IDiamondWritableInternal } from './IDiamondWritableInternal.sol';

/**
 * @title Diamond proxy upgrade interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2535
 */
interface IDiamondWritable is IDiamondWritableInternal {
    /**
     * @notice update diamond facets and optionally execute arbitrary initialization function
     * @param facetCuts array of structured Diamond facet update data
     * @param target optional target of initialization delegatecall
     * @param data optional initialization function call data
     */
    function diamondCut(
        FacetCut[] calldata facetCuts,
        address target,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IDiamondWritableInternal {
    enum FacetCutAction {
        ADD,
        REPLACE,
        REMOVE
    }

    event DiamondCut(FacetCut[] facetCuts, address target, bytes data);

    error DiamondWritable__InvalidInitializationParameters();
    error DiamondWritable__RemoveTargetNotZeroAddress();
    error DiamondWritable__ReplaceTargetIsIdentical();
    error DiamondWritable__SelectorAlreadyAdded();
    error DiamondWritable__SelectorIsImmutable();
    error DiamondWritable__SelectorNotFound();
    error DiamondWritable__SelectorNotSpecified();
    error DiamondWritable__TargetHasNoCode();

    struct FacetCut {
        address target;
        FacetCutAction action;
        bytes4[] selectors;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IProxy {
    error Proxy__ImplementationIsNotContract();

    fallback() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

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

        if (!implementation.isContract())
            revert Proxy__ImplementationIsNotContract();

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

    modifier nonReentrant() {
        if (ReentrancyGuardStorage.layout().status == REENTRANCY_STATUS_LOCKED)
            revert ReentrancyGuard__ReentrantCall();
        _lockReentrancyGuard();
        _;
        _unlockReentrancyGuard();
    }

    /**
     * @notice lock functions that use the nonReentrant modifier
     */
    function _lockReentrancyGuard() internal virtual {
        ReentrancyGuardStorage.layout().status = REENTRANCY_STATUS_LOCKED;
    }

    /**
     * @notice unlock funtions that use the nonReentrant modifier
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

import { IERC1155 } from '../../../interfaces/IERC1155.sol';
import { IERC1155Receiver } from '../../../interfaces/IERC1155Receiver.sol';
import { IERC1155Base } from './IERC1155Base.sol';
import { ERC1155BaseInternal, ERC1155BaseStorage } from './ERC1155BaseInternal.sol';

/**
 * @title Base ERC1155 contract
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 * @dev inheritor must either implement ERC165 supportsInterface or inherit ERC165Base
 */
abstract contract ERC1155Base is IERC1155Base, ERC1155BaseInternal {
    /**
     * @inheritdoc IERC1155
     */
    function balanceOf(
        address account,
        uint256 id
    ) public view virtual returns (uint256) {
        return _balanceOf(account, id);
    }

    /**
     * @inheritdoc IERC1155
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual returns (uint256[] memory) {
        if (accounts.length != ids.length)
            revert ERC1155Base__ArrayLengthMismatch();

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        uint256[] memory batchBalances = new uint256[](accounts.length);

        unchecked {
            for (uint256 i; i < accounts.length; i++) {
                if (accounts[i] == address(0))
                    revert ERC1155Base__BalanceQueryZeroAddress();
                batchBalances[i] = balances[ids[i]][accounts[i]];
            }
        }

        return batchBalances;
    }

    /**
     * @inheritdoc IERC1155
     */
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual returns (bool) {
        return ERC1155BaseStorage.layout().operatorApprovals[account][operator];
    }

    /**
     * @inheritdoc IERC1155
     */
    function setApprovalForAll(address operator, bool status) public virtual {
        if (msg.sender == operator) revert ERC1155Base__SelfApproval();
        ERC1155BaseStorage.layout().operatorApprovals[msg.sender][
            operator
        ] = status;
        emit ApprovalForAll(msg.sender, operator, status);
    }

    /**
     * @inheritdoc IERC1155
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender))
            revert ERC1155Base__NotOwnerOrApproved();
        _safeTransfer(msg.sender, from, to, id, amount, data);
    }

    /**
     * @inheritdoc IERC1155
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender))
            revert ERC1155Base__NotOwnerOrApproved();
        _safeTransferBatch(msg.sender, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Receiver } from '../../../interfaces/IERC1155Receiver.sol';
import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { IERC1155BaseInternal } from './IERC1155BaseInternal.sol';
import { ERC1155BaseStorage } from './ERC1155BaseStorage.sol';

/**
 * @title Base ERC1155 internal functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155BaseInternal is IERC1155BaseInternal {
    using AddressUtils for address;

    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function _balanceOf(
        address account,
        uint256 id
    ) internal view virtual returns (uint256) {
        if (account == address(0))
            revert ERC1155Base__BalanceQueryZeroAddress();
        return ERC1155BaseStorage.layout().balances[id][account];
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__MintToZeroAddress();

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        ERC1155BaseStorage.layout().balances[id][account] += amount;

        emit TransferSingle(msg.sender, address(0), account, id, amount);
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _safeMint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _mint(account, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    /**
     * @notice mint batch of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _mintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__MintToZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            balances[ids[i]][account] += amounts[i];
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), account, ids, amounts);
    }

    /**
     * @notice mint batch of tokens for given address
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _safeMintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _mintBatch(account, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice burn given quantity of tokens held by given address
     * @param account holder of tokens to burn
     * @param id token ID
     * @param amount quantity of tokens to burn
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__BurnFromZeroAddress();

        _beforeTokenTransfer(
            msg.sender,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ''
        );

        mapping(address => uint256) storage balances = ERC1155BaseStorage
            .layout()
            .balances[id];

        unchecked {
            if (amount > balances[account])
                revert ERC1155Base__BurnExceedsBalance();
            balances[account] -= amount;
        }

        emit TransferSingle(msg.sender, account, address(0), id, amount);
    }

    /**
     * @notice burn given batch of tokens held by given address
     * @param account holder of tokens to burn
     * @param ids token IDs
     * @param amounts quantities of tokens to burn
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__BurnFromZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(msg.sender, account, address(0), ids, amounts, '');

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            for (uint256 i; i < ids.length; i++) {
                uint256 id = ids[i];
                if (amounts[i] > balances[id][account])
                    revert ERC1155Base__BurnExceedsBalance();
                balances[id][account] -= amounts[i];
            }
        }

        emit TransferBatch(msg.sender, account, address(0), ids, amounts);
    }

    /**
     * @notice transfer tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _transfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (recipient == address(0))
            revert ERC1155Base__TransferToZeroAddress();

        _beforeTokenTransfer(
            operator,
            sender,
            recipient,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            uint256 senderBalance = balances[id][sender];
            if (amount > senderBalance)
                revert ERC1155Base__TransferExceedsBalance();
            balances[id][sender] = senderBalance - amount;
        }

        balances[id][recipient] += amount;

        emit TransferSingle(operator, sender, recipient, id, amount);
    }

    /**
     * @notice transfer tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _safeTransfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _transfer(operator, sender, recipient, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            id,
            amount,
            data
        );
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _transferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (recipient == address(0))
            revert ERC1155Base__TransferToZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(operator, sender, recipient, ids, amounts, data);

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            uint256 token = ids[i];
            uint256 amount = amounts[i];

            unchecked {
                uint256 senderBalance = balances[token][sender];

                if (amount > senderBalance)
                    revert ERC1155Base__TransferExceedsBalance();

                balances[token][sender] = senderBalance - amount;

                i++;
            }

            // balance increase cannot be unchecked because ERC1155Base neither tracks nor validates a totalSupply
            balances[token][recipient] += amount;
        }

        emit TransferBatch(operator, sender, recipient, ids, amounts);
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _safeTransferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _transferBatch(operator, sender, recipient, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice wrap given element in array of length 1
     * @param element element to wrap
     * @return singleton array
     */
    function _asSingletonArray(
        uint256 element
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector)
                    revert ERC1155Base__ERC1155ReceiverRejected();
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155Base__ERC1155ReceiverNotImplemented();
            }
        }
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) revert ERC1155Base__ERC1155ReceiverRejected();
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155Base__ERC1155ReceiverNotImplemented();
            }
        }
    }

    /**
     * @notice ERC1155 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @dev called for both single and batch transfers
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC1155BaseStorage {
    struct Layout {
        mapping(uint256 => mapping(address => uint256)) balances;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155 } from '../../../interfaces/IERC1155.sol';
import { IERC1155BaseInternal } from './IERC1155BaseInternal.sol';

/**
 * @title ERC1155 base interface
 */
interface IERC1155Base is IERC1155BaseInternal, IERC1155 {

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

import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { ERC1155BaseInternal } from '../base/ERC1155BaseInternal.sol';
import { IERC1155Enumerable } from './IERC1155Enumerable.sol';
import { ERC1155EnumerableInternal, ERC1155EnumerableStorage } from './ERC1155EnumerableInternal.sol';

/**
 * @title ERC1155 implementation including enumerable and aggregate functions
 */
abstract contract ERC1155Enumerable is
    IERC1155Enumerable,
    ERC1155EnumerableInternal
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function totalHolders(uint256 id) public view virtual returns (uint256) {
        return _totalHolders(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function accountsByToken(
        uint256 id
    ) public view virtual returns (address[] memory) {
        return _accountsByToken(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function tokensByAccount(
        address account
    ) public view virtual returns (uint256[] memory) {
        return _tokensByAccount(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { ERC1155BaseInternal, ERC1155BaseStorage } from '../base/ERC1155BaseInternal.sol';
import { ERC1155EnumerableStorage } from './ERC1155EnumerableStorage.sol';

/**
 * @title ERC1155Enumerable internal functions
 */
abstract contract ERC1155EnumerableInternal is ERC1155BaseInternal {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function _totalSupply(uint256 id) internal view virtual returns (uint256) {
        return ERC1155EnumerableStorage.layout().totalSupply[id];
    }

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function _totalHolders(uint256 id) internal view virtual returns (uint256) {
        return ERC1155EnumerableStorage.layout().accountsByToken[id].length();
    }

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function _accountsByToken(
        uint256 id
    ) internal view virtual returns (address[] memory) {
        EnumerableSet.AddressSet storage accounts = ERC1155EnumerableStorage
            .layout()
            .accountsByToken[id];

        address[] memory addresses = new address[](accounts.length());

        unchecked {
            for (uint256 i; i < accounts.length(); i++) {
                addresses[i] = accounts.at(i);
            }
        }

        return addresses;
    }

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function _tokensByAccount(
        address account
    ) internal view virtual returns (uint256[] memory) {
        EnumerableSet.UintSet storage tokens = ERC1155EnumerableStorage
            .layout()
            .tokensByAccount[account];

        uint256[] memory ids = new uint256[](tokens.length());

        unchecked {
            for (uint256 i; i < tokens.length(); i++) {
                ids[i] = tokens.at(i);
            }
        }

        return ids;
    }

    /**
     * @notice ERC1155 hook: update aggregate values
     * @inheritdoc ERC1155BaseInternal
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from != to) {
            ERC1155EnumerableStorage.Layout storage l = ERC1155EnumerableStorage
                .layout();
            mapping(uint256 => EnumerableSet.AddressSet)
                storage tokenAccounts = l.accountsByToken;
            EnumerableSet.UintSet storage fromTokens = l.tokensByAccount[from];
            EnumerableSet.UintSet storage toTokens = l.tokensByAccount[to];

            for (uint256 i; i < ids.length; ) {
                uint256 amount = amounts[i];

                if (amount > 0) {
                    uint256 id = ids[i];

                    if (from == address(0)) {
                        l.totalSupply[id] += amount;
                    } else if (_balanceOf(from, id) == amount) {
                        tokenAccounts[id].remove(from);
                        fromTokens.remove(id);
                    }

                    if (to == address(0)) {
                        l.totalSupply[id] -= amount;
                    } else if (_balanceOf(to, id) == 0) {
                        tokenAccounts[id].add(to);
                        toTokens.add(id);
                    }
                }

                unchecked {
                    i++;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableSet } from '../../../data/EnumerableSet.sol';

library ERC1155EnumerableStorage {
    struct Layout {
        mapping(uint256 => uint256) totalSupply;
        mapping(uint256 => EnumerableSet.AddressSet) accountsByToken;
        mapping(address => EnumerableSet.UintSet) tokensByAccount;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Enumerable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
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

import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IERC20Base } from './IERC20Base.sol';
import { ERC20BaseInternal } from './ERC20BaseInternal.sol';
import { ERC20BaseStorage } from './ERC20BaseStorage.sol';

/**
 * @title Base ERC20 implementation, excluding optional extensions
 */
abstract contract ERC20Base is IERC20Base, ERC20BaseInternal {
    /**
     * @inheritdoc IERC20
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply();
    }

    /**
     * @inheritdoc IERC20
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * @inheritdoc IERC20
     */
    function allowance(
        address holder,
        address spender
    ) external view returns (uint256) {
        return _allowance(holder, spender);
    }

    /**
     * @inheritdoc IERC20
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    /**
     * @inheritdoc IERC20
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    /**
     * @inheritdoc IERC20
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        return _transferFrom(holder, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20BaseInternal } from './IERC20BaseInternal.sol';
import { ERC20BaseStorage } from './ERC20BaseStorage.sol';

/**
 * @title Base ERC20 internal functions, excluding optional extensions
 */
abstract contract ERC20BaseInternal is IERC20BaseInternal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function _totalSupply() internal view virtual returns (uint256) {
        return ERC20BaseStorage.layout().totalSupply;
    }

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function _balanceOf(
        address account
    ) internal view virtual returns (uint256) {
        return ERC20BaseStorage.layout().balances[account];
    }

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function _allowance(
        address holder,
        address spender
    ) internal view virtual returns (uint256) {
        return ERC20BaseStorage.layout().allowances[holder][spender];
    }

    /**
     * @notice enable spender to spend tokens on behalf of holder
     * @param holder address on whose behalf tokens may be spent
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function _approve(
        address holder,
        address spender,
        uint256 amount
    ) internal virtual returns (bool) {
        if (holder == address(0)) revert ERC20Base__ApproveFromZeroAddress();
        if (spender == address(0)) revert ERC20Base__ApproveToZeroAddress();

        ERC20BaseStorage.layout().allowances[holder][spender] = amount;

        emit Approval(holder, spender, amount);

        return true;
    }

    /**
     * @notice decrease spend amount granted by holder to spender
     * @param holder address on whose behalf tokens may be spent
     * @param spender address whose allowance to decrease
     * @param amount quantity by which to decrease allowance
     */
    function _decreaseAllowance(
        address holder,
        address spender,
        uint256 amount
    ) internal {
        uint256 allowance = _allowance(holder, spender);

        if (amount > allowance) revert ERC20Base__InsufficientAllowance();

        unchecked {
            _approve(holder, spender, allowance - amount);
        }
    }

    /**
     * @notice mint tokens for given account
     * @param account recipient of minted tokens
     * @param amount quantity of tokens minted
     */
    function _mint(address account, uint256 amount) internal virtual {
        if (account == address(0)) revert ERC20Base__MintToZeroAddress();

        _beforeTokenTransfer(address(0), account, amount);

        ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
        l.totalSupply += amount;
        l.balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice burn tokens held by given account
     * @param account holder of burned tokens
     * @param amount quantity of tokens burned
     */
    function _burn(address account, uint256 amount) internal virtual {
        if (account == address(0)) revert ERC20Base__BurnFromZeroAddress();

        _beforeTokenTransfer(account, address(0), amount);

        ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
        uint256 balance = l.balances[account];
        if (amount > balance) revert ERC20Base__BurnExceedsBalance();
        unchecked {
            l.balances[account] = balance - amount;
        }
        l.totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @notice transfer tokens from holder to recipient
     * @param holder owner of tokens to be transferred
     * @param recipient beneficiary of transfer
     * @param amount quantity of tokens transferred
     * @return success status (always true; otherwise function should revert)
     */
    function _transfer(
        address holder,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        if (holder == address(0)) revert ERC20Base__TransferFromZeroAddress();
        if (recipient == address(0)) revert ERC20Base__TransferToZeroAddress();

        _beforeTokenTransfer(holder, recipient, amount);

        ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
        uint256 holderBalance = l.balances[holder];
        if (amount > holderBalance) revert ERC20Base__TransferExceedsBalance();
        unchecked {
            l.balances[holder] = holderBalance - amount;
        }
        l.balances[recipient] += amount;

        emit Transfer(holder, recipient, amount);

        return true;
    }

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function _transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        _decreaseAllowance(holder, msg.sender, amount);

        _transfer(holder, recipient, amount);

        return true;
    }

    /**
     * @notice ERC20 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param amount quantity of tokens transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC20BaseStorage {
    struct Layout {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC20Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IERC20BaseInternal } from './IERC20BaseInternal.sol';

/**
 * @title ERC20 base interface
 */
interface IERC20Base is IERC20BaseInternal, IERC20 {

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

import { IERC20Extended } from './IERC20Extended.sol';
import { ERC20ExtendedInternal } from './ERC20ExtendedInternal.sol';

/**
 * @title ERC20 safe approval extensions
 * @dev mitigations for transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
 */
abstract contract ERC20Extended is IERC20Extended, ERC20ExtendedInternal {
    /**
     * @inheritdoc IERC20Extended
     */
    function increaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool) {
        return _increaseAllowance(spender, amount);
    }

    /**
     * @inheritdoc IERC20Extended
     */
    function decreaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool) {
        return _decreaseAllowance(spender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ERC20BaseInternal, ERC20BaseStorage } from '../base/ERC20Base.sol';
import { IERC20ExtendedInternal } from './IERC20ExtendedInternal.sol';

/**
 * @title ERC20 safe approval extensions
 * @dev mitigations for transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
 */
abstract contract ERC20ExtendedInternal is
    ERC20BaseInternal,
    IERC20ExtendedInternal
{
    /**
     * @notice increase spend amount granted to spender
     * @param spender address whose allowance to increase
     * @param amount quantity by which to increase allowance
     * @return success status (always true; otherwise function will revert)
     */
    function _increaseAllowance(
        address spender,
        uint256 amount
    ) internal virtual returns (bool) {
        uint256 allowance = _allowance(msg.sender, spender);

        unchecked {
            if (allowance > allowance + amount)
                revert ERC20Extended__ExcessiveAllowance();

            return _approve(msg.sender, spender, allowance + amount);
        }
    }

    /**
     * @notice decrease spend amount granted to spender
     * @param spender address whose allowance to decrease
     * @param amount quantity by which to decrease allowance
     * @return success status (always true; otherwise function will revert)
     */
    function _decreaseAllowance(
        address spender,
        uint256 amount
    ) internal virtual returns (bool) {
        _decreaseAllowance(msg.sender, spender, amount);

        return true;
    }
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

import { IERC20Base } from './base/IERC20Base.sol';
import { IERC20Extended } from './extended/IERC20Extended.sol';
import { IERC20Metadata } from './metadata/IERC20Metadata.sol';
import { IERC20Permit } from './permit/IERC20Permit.sol';

interface ISolidStateERC20 is
    IERC20Base,
    IERC20Extended,
    IERC20Metadata,
    IERC20Permit
{}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Metadata } from './IERC20Metadata.sol';
import { ERC20MetadataInternal } from './ERC20MetadataInternal.sol';

/**
 * @title ERC20 metadata extensions
 */
abstract contract ERC20Metadata is IERC20Metadata, ERC20MetadataInternal {
    /**
     * @inheritdoc IERC20Metadata
     */
    function name() external view returns (string memory) {
        return _name();
    }

    /**
     * @inheritdoc IERC20Metadata
     */
    function symbol() external view returns (string memory) {
        return _symbol();
    }

    /**
     * @inheritdoc IERC20Metadata
     */
    function decimals() external view returns (uint8) {
        return _decimals();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20MetadataInternal } from './IERC20MetadataInternal.sol';
import { ERC20MetadataStorage } from './ERC20MetadataStorage.sol';

/**
 * @title ERC20Metadata internal functions
 */
abstract contract ERC20MetadataInternal is IERC20MetadataInternal {
    /**
     * @notice return token name
     * @return token name
     */
    function _name() internal view virtual returns (string memory) {
        return ERC20MetadataStorage.layout().name;
    }

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function _symbol() internal view virtual returns (string memory) {
        return ERC20MetadataStorage.layout().symbol;
    }

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function _decimals() internal view virtual returns (uint8) {
        return ERC20MetadataStorage.layout().decimals;
    }

    function _setName(string memory name) internal virtual {
        ERC20MetadataStorage.layout().name = name;
    }

    function _setSymbol(string memory symbol) internal virtual {
        ERC20MetadataStorage.layout().symbol = symbol;
    }

    function _setDecimals(uint8 decimals) internal virtual {
        ERC20MetadataStorage.layout().decimals = decimals;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC20MetadataStorage {
    struct Layout {
        string name;
        string symbol;
        uint8 decimals;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC20Metadata');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
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

import { ERC20Base } from '../base/ERC20Base.sol';
import { ERC20Metadata } from '../metadata/ERC20Metadata.sol';
import { ERC20PermitInternal } from './ERC20PermitInternal.sol';
import { ERC20PermitStorage } from './ERC20PermitStorage.sol';
import { IERC2612 } from './IERC2612.sol';
import { IERC20Permit } from './IERC20Permit.sol';

/**
 * @title ERC20 extension with support for ERC2612 permits
 * @dev derived from https://github.com/soliditylabs/ERC20-Permit (MIT license)
 */
abstract contract ERC20Permit is IERC20Permit, ERC20PermitInternal {
    /**
     * @inheritdoc IERC2612
     */
    function DOMAIN_SEPARATOR()
        external
        view
        returns (bytes32 domainSeparator)
    {
        return _DOMAIN_SEPARATOR();
    }

    /**
     * @inheritdoc IERC2612
     */
    function nonces(address owner) public view returns (uint256) {
        return _nonces(owner);
    }

    /**
     * @inheritdoc IERC2612
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        _permit(owner, spender, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import { ECDSA } from '../../../cryptography/ECDSA.sol';
import { EIP712 } from '../../../cryptography/EIP712.sol';
import { ERC20BaseInternal } from '../base/ERC20BaseInternal.sol';
import { ERC20MetadataInternal } from '../metadata/ERC20MetadataInternal.sol';
import { ERC20PermitStorage } from './ERC20PermitStorage.sol';
import { IERC20PermitInternal } from './IERC20PermitInternal.sol';

/**
 * @title ERC20 extension with support for ERC2612 permits
 * @dev derived from https://github.com/soliditylabs/ERC20-Permit (MIT license)
 */
abstract contract ERC20PermitInternal is
    ERC20BaseInternal,
    ERC20MetadataInternal,
    IERC20PermitInternal
{
    using ECDSA for bytes32;

    bytes32 internal constant EIP712_TYPE_HASH =
        keccak256(
            'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
        );

    /**
     * @notice return the EIP-712 domain separator unique to contract and chain
     * @return domainSeparator domain separator
     */
    function _DOMAIN_SEPARATOR()
        internal
        view
        returns (bytes32 domainSeparator)
    {
        domainSeparator = ERC20PermitStorage.layout().domainSeparators[
            block.chainid
        ];

        if (domainSeparator == 0x00) {
            domainSeparator = EIP712.calculateDomainSeparator(
                keccak256(bytes(_name())),
                keccak256(bytes(_version()))
            );
        }
    }

    /**
     * @notice get the current ERC2612 nonce for the given address
     * @return current nonce
     */
    function _nonces(address owner) internal view returns (uint256) {
        return ERC20PermitStorage.layout().nonces[owner];
    }

    /**
     * @notice query signing domain version
     * @return version signing domain version
     */
    function _version() internal view virtual returns (string memory version) {
        version = '1';
    }

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
    function _permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal virtual {
        if (deadline < block.timestamp) revert ERC20Permit__ExpiredDeadline();

        ERC20PermitStorage.Layout storage l = ERC20PermitStorage.layout();

        // execute EIP-712 hashStruct procedure using assembly, equavalent to:
        //
        // bytes32 structHash = keccak256(
        //   abi.encode(
        //     EIP712_TYPE_HASH,
        //     owner,
        //     spender,
        //     amount,
        //     nonce,
        //     deadline
        //   )
        // );

        bytes32 structHash;
        uint256 nonce = l.nonces[owner];

        bytes32 typeHash = EIP712_TYPE_HASH;

        assembly {
            // load free memory pointer
            let pointer := mload(64)

            mstore(pointer, typeHash)
            mstore(add(pointer, 32), owner)
            mstore(add(pointer, 64), spender)
            mstore(add(pointer, 96), amount)
            mstore(add(pointer, 128), nonce)
            mstore(add(pointer, 160), deadline)

            structHash := keccak256(pointer, 192)
        }

        bytes32 domainSeparator = l.domainSeparators[block.chainid];

        if (domainSeparator == 0x00) {
            domainSeparator = EIP712.calculateDomainSeparator(
                keccak256(bytes(_name())),
                keccak256(bytes(_version()))
            );
            l.domainSeparators[block.chainid] = domainSeparator;
        }

        // recreate and hash data payload using assembly, equivalent to:
        //
        // bytes32 hash = keccak256(
        //   abi.encodePacked(
        //     uint16(0x1901),
        //     domainSeparator,
        //     structHash
        //   )
        // );

        bytes32 hash;

        assembly {
            // load free memory pointer
            let pointer := mload(64)

            // this magic value is the EIP-191 signed data header, consisting of
            // the hardcoded 0x19 and the one-byte version 0x01
            mstore(
                pointer,
                0x1901000000000000000000000000000000000000000000000000000000000000
            )
            mstore(add(pointer, 2), domainSeparator)
            mstore(add(pointer, 34), structHash)

            hash := keccak256(pointer, 66)
        }

        // validate signature

        address signer = hash.recover(v, r, s);

        if (signer != owner) revert ERC20Permit__InvalidSignature();

        l.nonces[owner]++;
        _approve(owner, spender, amount);
    }

    /**
     * @inheritdoc ERC20MetadataInternal
     * @notice set new token name and invalidate cached domain separator
     * @dev domain separator is not immediately recalculated, and will ultimately depend on the output of the _name view function
     */
    function _setName(string memory name) internal virtual override {
        // TODO: cache invalidation can fail if chainid is reverted to a previous value
        super._setName(name);
        delete ERC20PermitStorage.layout().domainSeparators[block.chainid];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC20PermitStorage {
    struct Layout {
        mapping(address => uint256) nonces;
        // Mapping of ChainID to domain separators. This is a very gas efficient way
        // to not recalculate the domain separator on every call, while still
        // automatically detecting ChainID changes.
        mapping(uint256 => bytes32) domainSeparators;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC20Permit');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Metadata } from '../metadata/IERC20Metadata.sol';
import { IERC2612 } from './IERC2612.sol';
import { IERC20PermitInternal } from './IERC20PermitInternal.sol';

// TODO: note that IERC20Metadata is needed for eth-permit library

interface IERC20Permit is IERC20PermitInternal, IERC2612 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC2612Internal } from './IERC2612Internal.sol';

interface IERC20PermitInternal is IERC2612Internal {
    error ERC20Permit__ExpiredDeadline();
    error ERC20Permit__InvalidSignature();
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

import { ISolidStateERC20 } from './ISolidStateERC20.sol';
import { ERC20Base } from './base/ERC20Base.sol';
import { ERC20Extended } from './extended/ERC20Extended.sol';
import { ERC20Metadata } from './metadata/ERC20Metadata.sol';
import { ERC20MetadataInternal } from './metadata/ERC20MetadataInternal.sol';
import { ERC20Permit } from './permit/ERC20Permit.sol';
import { ERC20PermitInternal } from './permit/ERC20PermitInternal.sol';

/**
 * @title SolidState ERC20 implementation, including recommended extensions
 */
abstract contract SolidStateERC20 is
    ISolidStateERC20,
    ERC20Base,
    ERC20Extended,
    ERC20Metadata,
    ERC20Permit
{
    function _setName(
        string memory name
    ) internal virtual override(ERC20MetadataInternal, ERC20PermitInternal) {
        super._setName(name);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC4626 } from '../../../interfaces/IERC4626.sol';
import { IERC4626 } from '../../../interfaces/IERC4626.sol';
import { ERC20Base } from '../../ERC20/base/ERC20Base.sol';
import { ERC20Metadata } from '../../ERC20/metadata/ERC20Metadata.sol';
import { IERC4626Base } from './IERC4626Base.sol';
import { ERC4626BaseInternal } from './ERC4626BaseInternal.sol';

/**
 * @title Base ERC4626 implementation
 */
abstract contract ERC4626Base is
    IERC4626Base,
    ERC4626BaseInternal,
    ERC20Base,
    ERC20Metadata
{
    /**
     * @inheritdoc IERC4626
     */
    function asset() external view returns (address) {
        return _asset();
    }

    /**
     * @inheritdoc IERC4626
     */
    function totalAssets() external view returns (uint256) {
        return _totalAssets();
    }

    /**
     * @inheritdoc IERC4626
     */
    function convertToShares(
        uint256 assetAmount
    ) external view returns (uint256 shareAmount) {
        shareAmount = _convertToShares(assetAmount);
    }

    /**
     * @inheritdoc IERC4626
     */
    function convertToAssets(
        uint256 shareAmount
    ) external view returns (uint256 assetAmount) {
        assetAmount = _convertToAssets(shareAmount);
    }

    /**
     * @inheritdoc IERC4626
     */
    function maxDeposit(
        address receiver
    ) external view returns (uint256 maxAssets) {
        maxAssets = _maxDeposit(receiver);
    }

    /**
     * @inheritdoc IERC4626
     */
    function maxMint(
        address receiver
    ) external view returns (uint256 maxShares) {
        maxShares = _maxMint(receiver);
    }

    /**
     * @inheritdoc IERC4626
     */
    function maxWithdraw(
        address owner
    ) external view returns (uint256 maxAssets) {
        maxAssets = _maxWithdraw(owner);
    }

    /**
     * @inheritdoc IERC4626
     */
    function maxRedeem(
        address owner
    ) external view returns (uint256 maxShares) {
        maxShares = _maxRedeem(owner);
    }

    /**
     * @inheritdoc IERC4626
     */
    function previewDeposit(
        uint256 assetAmount
    ) external view returns (uint256 shareAmount) {
        shareAmount = _previewDeposit(assetAmount);
    }

    /**
     * @inheritdoc IERC4626
     */
    function previewMint(
        uint256 shareAmount
    ) external view returns (uint256 assetAmount) {
        assetAmount = _previewMint(shareAmount);
    }

    /**
     * @inheritdoc IERC4626
     */
    function previewWithdraw(
        uint256 assetAmount
    ) external view returns (uint256 shareAmount) {
        shareAmount = _previewWithdraw(assetAmount);
    }

    /**
     * @inheritdoc IERC4626
     */
    function previewRedeem(
        uint256 shareAmount
    ) external view returns (uint256 assetAmount) {
        assetAmount = _previewRedeem(shareAmount);
    }

    /**
     * @inheritdoc IERC4626
     */
    function deposit(
        uint256 assetAmount,
        address receiver
    ) external returns (uint256 shareAmount) {
        shareAmount = _deposit(assetAmount, receiver);
    }

    /**
     * @inheritdoc IERC4626
     */
    function mint(
        uint256 shareAmount,
        address receiver
    ) external returns (uint256 assetAmount) {
        assetAmount = _mint(shareAmount, receiver);
    }

    /**
     * @inheritdoc IERC4626
     */
    function withdraw(
        uint256 assetAmount,
        address receiver,
        address owner
    ) external returns (uint256 shareAmount) {
        shareAmount = _withdraw(assetAmount, receiver, owner);
    }

    /**
     * @inheritdoc IERC4626
     */
    function redeem(
        uint256 shareAmount,
        address receiver,
        address owner
    ) external returns (uint256 assetAmount) {
        assetAmount = _redeem(shareAmount, receiver, owner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20 } from '../../../interfaces/IERC20.sol';
import { SafeERC20 } from '../../../utils/SafeERC20.sol';
import { ERC20BaseInternal } from '../../ERC20/base/ERC20BaseInternal.sol';
import { ERC20MetadataInternal } from '../../ERC20/metadata/ERC20MetadataInternal.sol';
import { IERC4626BaseInternal } from './IERC4626BaseInternal.sol';
import { ERC4626BaseStorage } from './ERC4626BaseStorage.sol';

/**
 * @title Base ERC4626 internal functions
 */
abstract contract ERC4626BaseInternal is
    IERC4626BaseInternal,
    ERC20BaseInternal,
    ERC20MetadataInternal
{
    using SafeERC20 for IERC20;

    /**
     * @notice get the address of the base token used for vault accountin purposes
     * @return base token address
     */
    function _asset() internal view virtual returns (address) {
        return ERC4626BaseStorage.layout().asset;
    }

    /**
     * @notice get the total quantity of the base asset currently managed by the vault
     * @return total managed asset amount
     */
    function _totalAssets() internal view virtual returns (uint256);

    /**
     * @notice calculate the quantity of shares received in exchange for a given quantity of assets, not accounting for slippage
     * @param assetAmount quantity of assets to convert
     * @return shareAmount quantity of shares calculated
     */
    function _convertToShares(
        uint256 assetAmount
    ) internal view virtual returns (uint256 shareAmount) {
        uint256 supply = _totalSupply();

        if (supply == 0) {
            shareAmount = assetAmount;
        } else {
            uint256 totalAssets = _totalAssets();
            if (totalAssets == 0) {
                shareAmount = assetAmount;
            } else {
                shareAmount = (assetAmount * supply) / totalAssets;
            }
        }
    }

    /**
     * @notice calculate the quantity of assets received in exchange for a given quantity of shares, not accounting for slippage
     * @param shareAmount quantity of shares to convert
     * @return assetAmount quantity of assets calculated
     */
    function _convertToAssets(
        uint256 shareAmount
    ) internal view virtual returns (uint256 assetAmount) {
        uint256 supply = _totalSupply();

        if (supply == 0) {
            assetAmount = shareAmount;
        } else {
            assetAmount = (shareAmount * _totalAssets()) / supply;
        }
    }

    /**
     * @notice calculate the maximum quantity of base assets which may be deposited on behalf of given receiver
     * @dev unused address param represents recipient of shares resulting from deposit
     * @return maxAssets maximum asset deposit amount
     */
    function _maxDeposit(
        address
    ) internal view virtual returns (uint256 maxAssets) {
        maxAssets = type(uint256).max;
    }

    /**
     * @notice calculate the maximum quantity of shares which may be minted on behalf of given receiver
     * @dev unused address param represents recipient of shares resulting from deposit
     * @return maxShares maximum share mint amount
     */
    function _maxMint(
        address
    ) internal view virtual returns (uint256 maxShares) {
        maxShares = type(uint256).max;
    }

    /**
     * @notice calculate the maximum quantity of base assets which may be withdrawn by given holder
     * @param owner holder of shares to be redeemed
     * @return maxAssets maximum asset mint amount
     */
    function _maxWithdraw(
        address owner
    ) internal view virtual returns (uint256 maxAssets) {
        maxAssets = _convertToAssets(_balanceOf(owner));
    }

    /**
     * @notice calculate the maximum quantity of shares which may be redeemed by given holder
     * @param owner holder of shares to be redeemed
     * @return maxShares maximum share redeem amount
     */
    function _maxRedeem(
        address owner
    ) internal view virtual returns (uint256 maxShares) {
        maxShares = _balanceOf(owner);
    }

    /**
     * @notice simulate a deposit of given quantity of assets
     * @param assetAmount quantity of assets to deposit
     * @return shareAmount quantity of shares to mint
     */
    function _previewDeposit(
        uint256 assetAmount
    ) internal view virtual returns (uint256 shareAmount) {
        shareAmount = _convertToShares(assetAmount);
    }

    /**
     * @notice simulate a minting of given quantity of shares
     * @param shareAmount quantity of shares to mint
     * @return assetAmount quantity of assets to deposit
     */
    function _previewMint(
        uint256 shareAmount
    ) internal view virtual returns (uint256 assetAmount) {
        uint256 supply = _totalSupply();

        if (supply == 0) {
            assetAmount = shareAmount;
        } else {
            assetAmount = (shareAmount * _totalAssets() + supply - 1) / supply;
        }
    }

    /**
     * @notice simulate a withdrawal of given quantity of assets
     * @param assetAmount quantity of assets to withdraw
     * @return shareAmount quantity of shares to redeem
     */
    function _previewWithdraw(
        uint256 assetAmount
    ) internal view virtual returns (uint256 shareAmount) {
        uint256 supply = _totalSupply();

        if (supply == 0) {
            shareAmount = assetAmount;
        } else {
            uint256 totalAssets = _totalAssets();

            if (totalAssets == 0) {
                shareAmount = assetAmount;
            } else {
                shareAmount =
                    (assetAmount * supply + totalAssets - 1) /
                    totalAssets;
            }
        }
    }

    /**
     * @notice simulate a redemption of given quantity of shares
     * @param shareAmount quantity of shares to redeem
     * @return assetAmount quantity of assets to withdraw
     */
    function _previewRedeem(
        uint256 shareAmount
    ) internal view virtual returns (uint256 assetAmount) {
        assetAmount = _convertToAssets(shareAmount);
    }

    /**
     * @notice execute a deposit of assets on behalf of given address
     * @param assetAmount quantity of assets to deposit
     * @param receiver recipient of shares resulting from deposit
     * @return shareAmount quantity of shares to mint
     */
    function _deposit(
        uint256 assetAmount,
        address receiver
    ) internal virtual returns (uint256 shareAmount) {
        if (assetAmount > _maxDeposit(receiver))
            revert ERC4626Base__MaximumAmountExceeded();

        shareAmount = _previewDeposit(assetAmount);

        _deposit(msg.sender, receiver, assetAmount, shareAmount, 0, 0);
    }

    /**
     * @notice execute a minting of shares on behalf of given address
     * @param shareAmount quantity of shares to mint
     * @param receiver recipient of shares resulting from deposit
     * @return assetAmount quantity of assets to deposit
     */
    function _mint(
        uint256 shareAmount,
        address receiver
    ) internal virtual returns (uint256 assetAmount) {
        if (shareAmount > _maxMint(receiver))
            revert ERC4626Base__MaximumAmountExceeded();

        assetAmount = _previewMint(shareAmount);

        _deposit(msg.sender, receiver, assetAmount, shareAmount, 0, 0);
    }

    /**
     * @notice execute a withdrawal of assets on behalf of given address
     * @param assetAmount quantity of assets to withdraw
     * @param receiver recipient of assets resulting from withdrawal
     * @param owner holder of shares to be redeemed
     * @return shareAmount quantity of shares to redeem
     */
    function _withdraw(
        uint256 assetAmount,
        address receiver,
        address owner
    ) internal virtual returns (uint256 shareAmount) {
        if (assetAmount > _maxWithdraw(owner))
            revert ERC4626Base__MaximumAmountExceeded();

        shareAmount = _previewWithdraw(assetAmount);

        _withdraw(msg.sender, receiver, owner, assetAmount, shareAmount, 0, 0);
    }

    /**
     * @notice execute a redemption of shares on behalf of given address
     * @param shareAmount quantity of shares to redeem
     * @param receiver recipient of assets resulting from withdrawal
     * @param owner holder of shares to be redeemed
     * @return assetAmount quantity of assets to withdraw
     */
    function _redeem(
        uint256 shareAmount,
        address receiver,
        address owner
    ) internal virtual returns (uint256 assetAmount) {
        if (shareAmount > _maxRedeem(owner))
            revert ERC4626Base__MaximumAmountExceeded();

        assetAmount = _previewRedeem(shareAmount);

        _withdraw(msg.sender, receiver, owner, assetAmount, shareAmount, 0, 0);
    }

    /**
     * @notice ERC4626 hook, called deposit and mint actions
     * @dev function should be overridden and new implementation must call super
     * @param receiver recipient of shares resulting from deposit
     * @param assetAmount quantity of assets being deposited
     * @param shareAmount quantity of shares being minted
     */
    function _afterDeposit(
        address receiver,
        uint256 assetAmount,
        uint256 shareAmount
    ) internal virtual {}

    /**
     * @notice ERC4626 hook, called before withdraw and redeem actions
     * @dev function should be overridden and new implementation must call super
     * @param owner holder of shares to be redeemed
     * @param assetAmount quantity of assets being withdrawn
     * @param shareAmount quantity of shares being redeemed
     */
    function _beforeWithdraw(
        address owner,
        uint256 assetAmount,
        uint256 shareAmount
    ) internal virtual {}

    /**
     * @notice exchange assets for shares on behalf of given address
     * @param caller supplier of assets to be deposited
     * @param receiver recipient of shares resulting from deposit
     * @param assetAmount quantity of assets to deposit
     * @param shareAmount quantity of shares to mint
     * @param assetAmountOffset quantity of assets to deduct from deposit amount
     * @param shareAmountOffset quantity of shares to deduct from mint amount
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assetAmount,
        uint256 shareAmount,
        uint256 assetAmountOffset,
        uint256 shareAmountOffset
    ) internal virtual {
        uint256 assetAmountNet = assetAmount - assetAmountOffset;

        if (assetAmountNet > 0) {
            IERC20(_asset()).safeTransferFrom(
                caller,
                address(this),
                assetAmountNet
            );
        }

        uint256 shareAmountNet = shareAmount - shareAmountOffset;

        if (shareAmountNet > 0) {
            _mint(receiver, shareAmountNet);
        }

        _afterDeposit(receiver, assetAmount, shareAmount);

        emit Deposit(caller, receiver, assetAmount, shareAmount);
    }

    /**
     * @notice exchange shares for assets on behalf of given address
     * @param caller transaction operator for purposes of allowance verification
     * @param receiver recipient of assets resulting from withdrawal
     * @param owner holder of shares to be redeemed
     * @param assetAmount quantity of assets to withdraw
     * @param shareAmount quantity of shares to redeem
     * @param assetAmountOffset quantity of assets to deduct from withdrawal amount
     * @param shareAmountOffset quantity of shares to deduct from burn amount
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assetAmount,
        uint256 shareAmount,
        uint256 assetAmountOffset,
        uint256 shareAmountOffset
    ) internal virtual {
        if (caller != owner) {
            uint256 allowance = _allowance(owner, caller);

            if (shareAmount > allowance)
                revert ERC4626Base__AllowanceExceeded();

            unchecked {
                _approve(owner, caller, allowance - shareAmount);
            }
        }

        _beforeWithdraw(owner, assetAmount, shareAmount);

        uint256 shareAmountNet = shareAmount - shareAmountOffset;

        if (shareAmountNet > 0) {
            _burn(owner, shareAmountNet);
        }

        uint256 assetAmountNet = assetAmount - assetAmountOffset;

        if (assetAmountNet > 0) {
            IERC20(_asset()).safeTransfer(receiver, assetAmountNet);
        }

        emit Withdraw(caller, receiver, owner, assetAmount, shareAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC4626BaseStorage {
    struct Layout {
        address asset;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC4626Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC4626 } from '../../../interfaces/IERC4626.sol';
import { IERC4626BaseInternal } from './IERC4626BaseInternal.sol';

/**
 * @title ERC4626 base interface
 */
interface IERC4626Base is IERC4626BaseInternal, IERC4626 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC4626Internal } from '../../../interfaces/IERC4626Internal.sol';

/**
 * @title ERC4626 base interface
 */
interface IERC4626BaseInternal is IERC4626Internal {
    error ERC4626Base__MaximumAmountExceeded();
    error ERC4626Base__AllowanceExceeded();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ISolidStateERC20 } from '../ERC20/ISolidStateERC20.sol';
import { IERC4626Base } from './base/IERC4626Base.sol';

interface ISolidStateERC4626 is IERC4626Base, ISolidStateERC20 {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ERC20MetadataInternal } from '../ERC20/metadata/ERC20MetadataInternal.sol';
import { ERC20PermitInternal } from '../ERC20/permit/ERC20PermitInternal.sol';
import { SolidStateERC20 } from '../ERC20/SolidStateERC20.sol';
import { ERC4626Base } from './base/ERC4626Base.sol';
import { ISolidStateERC4626 } from './ISolidStateERC4626.sol';

/**
 * @title SolidState ERC4626 implementation, including recommended ERC20 extensions
 */
abstract contract SolidStateERC4626 is
    ISolidStateERC4626,
    ERC4626Base,
    SolidStateERC20
{
    function _setName(
        string memory name
    ) internal virtual override(ERC20MetadataInternal, SolidStateERC20) {
        super._setName(name);
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
 * @title Interface for the Multicall utility contract
 */
interface IMulticall {
    /**
     * @notice batch function calls to the contract and return the results of each
     * @param data array of function call data payloads
     * @return results array of function call results
     */
    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory results);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library Math {
    /**
     * @notice calculate the absolute value of a number
     * @param a number whose absoluve value to calculate
     * @return absolute value
     */
    function abs(int256 a) internal pure returns (uint256) {
        return uint256(a < 0 ? -a : a);
    }

    /**
     * @notice select the greater of two numbers
     * @param a first number
     * @param b second number
     * @return greater number
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @notice select the lesser of two numbers
     * @param a first number
     * @param b second number
     * @return lesser number
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    /**
     * @notice calculate the average of two numbers, rounded down
     * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
     * @param a first number
     * @param b second number
     * @return mean value
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return (a & b) + ((a ^ b) >> 1);
        }
    }

    /**
     * @notice estimate square root of number
     * @dev uses Babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     * @param x input number
     * @return y square root
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) >> 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) >> 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IMulticall } from './IMulticall.sol';

/**
 * @title Utility contract for supporting processing of multiple function calls in a single transaction
 */
abstract contract Multicall is IMulticall {
    /**
     * @inheritdoc IMulticall
     */
    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory results) {
        results = new bytes[](data.length);

        unchecked {
            for (uint256 i; i < data.length; i++) {
                (bool success, bytes memory returndata) = address(this)
                    .delegatecall(data[i]);

                if (success) {
                    results[i] = returndata;
                } else {
                    assembly {
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                }
            }
        }

        return results;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Helper library for safe casting of uint and int values
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library SafeCast {
    error SafeCast__NegativeValue();
    error SafeCast__ValueDoesNotFit();

    function toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) revert SafeCast__ValueDoesNotFit();
        return uint224(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) revert SafeCast__ValueDoesNotFit();
        return uint128(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) revert SafeCast__ValueDoesNotFit();
        return uint96(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) revert SafeCast__ValueDoesNotFit();
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) revert SafeCast__ValueDoesNotFit();
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        if (value > type(uint16).max) revert SafeCast__ValueDoesNotFit();
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) revert SafeCast__ValueDoesNotFit();
        return uint8(value);
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) revert SafeCast__NegativeValue();
        return uint256(value);
    }

    function toInt128(int256 value) internal pure returns (int128) {
        if (value < type(int128).min || value > type(int128).max)
            revert SafeCast__ValueDoesNotFit();

        return int128(value);
    }

    function toInt64(int256 value) internal pure returns (int64) {
        if (value < type(int64).min || value > type(int64).max)
            revert SafeCast__ValueDoesNotFit();
        return int64(value);
    }

    function toInt32(int256 value) internal pure returns (int32) {
        if (value < type(int32).min || value > type(int32).max)
            revert SafeCast__ValueDoesNotFit();
        return int32(value);
    }

    function toInt16(int256 value) internal pure returns (int16) {
        if (value < type(int16).min || value > type(int16).max)
            revert SafeCast__ValueDoesNotFit();
        return int16(value);
    }

    function toInt8(int256 value) internal pure returns (int8) {
        if (value < type(int8).min || value > type(int8).max)
            revert SafeCast__ValueDoesNotFit();
        return int8(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        if (value > uint256(type(int256).max))
            revert SafeCast__ValueDoesNotFit();
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20 } from '../interfaces/IERC20.sol';
import { AddressUtils } from './AddressUtils.sol';

/**
 * @title Safe ERC20 interaction library
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library SafeERC20 {
    using AddressUtils for address;

    error SafeERC20__ApproveFromNonZeroToNonZero();
    error SafeERC20__DecreaseAllowanceBelowZero();
    error SafeERC20__OperationFailed();

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev safeApprove (like approve) should only be called when setting an initial allowance or when resetting it to zero; otherwise prefer safeIncreaseAllowance and safeDecreaseAllowance
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        if ((value != 0) && (token.allowance(address(this), spender) != 0))
            revert SafeERC20__ApproveFromNonZeroToNonZero();

        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            if (oldAllowance < value)
                revert SafeERC20__DecreaseAllowanceBelowZero();
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @notice send transaction data and check validity of return value, if present
     * @param token ERC20 token interface
     * @param data transaction data
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            'SafeERC20: low-level call failed'
        );

        if (returndata.length > 0) {
            if (!abi.decode(returndata, (bool)))
                revert SafeERC20__OperationFailed();
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

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {Denominations} from "@chainlink/contracts/src/v0.8/Denominations.sol";
import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";
import {SafeCast} from "@solidstate/contracts/utils/SafeCast.sol";

import {ArrayUtils} from "../../libraries/ArrayUtils.sol";
import {ZERO, ONE} from "../../libraries/Constants.sol";
import {AggregatorProxyInterface} from "../../vendor/AggregatorProxyInterface.sol";

import {FeedRegistry, IFeedRegistry} from "../FeedRegistry.sol";
import {FeedRegistryStorage} from "../FeedRegistryStorage.sol";
import {IOracleAdapter} from "../IOracleAdapter.sol";
import {OracleAdapter} from "../OracleAdapter.sol";
import {IPriceRepository} from "../IPriceRepository.sol";
import {PriceRepository} from "../PriceRepository.sol";
import {PriceRepositoryStorage} from "../PriceRepositoryStorage.sol";
import {ETH_DECIMALS, FOREX_DECIMALS, Tokens} from "../Tokens.sol";

import {ChainlinkAdapterStorage} from "./ChainlinkAdapterStorage.sol";
import {IChainlinkAdapter} from "./IChainlinkAdapter.sol";

/// @title An implementation of IOracleAdapter that uses Chainlink feeds
/// @notice This oracle adapter will attempt to use all available feeds to determine prices between pairs
contract ChainlinkAdapter is IChainlinkAdapter, FeedRegistry, OracleAdapter, PriceRepository {
    using ChainlinkAdapterStorage for address;
    using ChainlinkAdapterStorage for ChainlinkAdapterStorage.Layout;
    using ChainlinkAdapterStorage for IChainlinkAdapter.PricingPath;
    using EnumerableSet for EnumerableSet.AddressSet;
    using FeedRegistryStorage for FeedRegistryStorage.Layout;
    using SafeCast for int256;
    using SafeCast for uint8;
    using Tokens for address;

    /// @dev If the difference between target and last update is greater than the
    ///      STALE_PRICE_THRESHOLD, the price is considered stale
    uint256 internal constant STALE_PRICE_THRESHOLD = 25 hours;

    constructor(
        address _wrappedNativeToken,
        address _wrappedBTCToken
    ) FeedRegistry(_wrappedNativeToken, _wrappedBTCToken) {}

    /// @inheritdoc IOracleAdapter
    function isPairSupported(address tokenA, address tokenB) external view returns (bool isCached, bool hasPath) {
        (PricingPath path, address mappedTokenA, address mappedTokenB) = _pricingPath(tokenA, tokenB);

        isCached = path != PricingPath.NONE;
        if (isCached) return (isCached, true);

        hasPath = _determinePricingPath(mappedTokenA, mappedTokenB) != PricingPath.NONE;
    }

    /// @inheritdoc IOracleAdapter
    function upsertPair(address tokenA, address tokenB) external nonReentrant {
        (address sortedA, address sortedB) = _mapToDenominationAndSort(tokenA, tokenB);

        PricingPath path = _determinePricingPath(sortedA, sortedB);
        bytes32 keyForPair = sortedA.keyForSortedPair(sortedB);

        ChainlinkAdapterStorage.Layout storage l = ChainlinkAdapterStorage.layout();

        if (path == PricingPath.NONE) {
            // Check if there is a current path. If there is, it means that the pair was supported and it
            // lost support. In that case, we will remove the current path and continue working as expected.
            // If there was no supported path, and there still isn't, then we will fail
            if (l.pricingPath[keyForPair] == PricingPath.NONE)
                revert OracleAdapter__PairCannotBeSupported(tokenA, tokenB);
        }

        if (l.pricingPath[keyForPair] == path) return;
        l.pricingPath[keyForPair] = path;

        if (!l.pairedTokens[sortedA].contains(sortedB)) l.pairedTokens[sortedA].add(sortedB);
        if (!l.pairedTokens[sortedB].contains(sortedA)) l.pairedTokens[sortedB].add(sortedA);

        emit UpdatedPathForPair(sortedA, sortedB, path);
    }

    /// @inheritdoc IOracleAdapter
    function getPrice(address tokenIn, address tokenOut) external view returns (UD60x18) {
        return _getPriceAt(tokenIn, tokenOut, 0);
    }

    /// @inheritdoc IOracleAdapter
    function getPriceAt(address tokenIn, address tokenOut, uint256 target) external view returns (UD60x18) {
        _revertIfTargetInvalid(target);
        return _getPriceAt(tokenIn, tokenOut, target);
    }

    /// @notice Returns a price based on the pricing path between `tokenIn` and `tokenOut`
    function _getPriceAt(address tokenIn, address tokenOut, uint256 target) internal view returns (UD60x18) {
        (PricingPath path, address mappedTokenIn, address mappedTokenOut) = _pricingPath(tokenIn, tokenOut);

        if (path == PricingPath.NONE) {
            path = _determinePricingPath(mappedTokenIn, mappedTokenOut);
            if (path == PricingPath.NONE) revert OracleAdapter__PairNotSupported(tokenIn, tokenOut);
        }
        if (path <= PricingPath.TOKEN_ETH) {
            return _getDirectPrice(path, mappedTokenIn, mappedTokenOut, target);
        } else if (path <= PricingPath.TOKEN_ETH_TOKEN) {
            return _getPriceSameDenomination(path, mappedTokenIn, mappedTokenOut, target);
        } else if (path <= PricingPath.A_ETH_USD_B) {
            return _getPriceDifferentDenomination(path, mappedTokenIn, mappedTokenOut, target);
        } else {
            return _getPriceWBTCPrice(mappedTokenIn, mappedTokenOut, target);
        }
    }

    /// @inheritdoc IOracleAdapter
    function describePricingPath(
        address token
    ) external view returns (AdapterType adapterType, address[][] memory path, uint8[] memory decimals) {
        adapterType = AdapterType.Chainlink;
        path = new address[][](2);
        decimals = new uint8[](2);

        token = _tokenToDenomination(token);

        if (token == Denominations.ETH) {
            address[] memory aggregator = new address[](1);
            aggregator[0] = Denominations.ETH;
            path[0] = aggregator;
        } else if (_feedExists(token, Denominations.ETH)) {
            path[0] = _aggregator(token, Denominations.ETH);
        } else if (_feedExists(token, Denominations.USD)) {
            path[0] = _aggregator(token, Denominations.USD);
            path[1] = _aggregator(Denominations.ETH, Denominations.USD);
        }

        if (path[0].length > 0) {
            decimals[0] = path[0][0] == Denominations.ETH ? ETH_DECIMALS : _aggregatorDecimals(path[0][0]);
        }

        if (path[1].length > 0) {
            decimals[1] = _aggregatorDecimals(path[1][0]);
        }

        if (path[0].length == 0) {
            address[][] memory temp = new address[][](0);
            path = temp;
        } else if (path[1].length == 0) {
            address[][] memory temp = new address[][](1);
            temp[0] = path[0];
            path = temp;
        }

        if (decimals[0] == 0) {
            ArrayUtils.resizeArray(decimals, 0);
        } else if (decimals[1] == 0) {
            ArrayUtils.resizeArray(decimals, 1);
        }
    }

    /// @inheritdoc IChainlinkAdapter
    function pricingPath(address tokenA, address tokenB) external view returns (PricingPath) {
        (PricingPath path, , ) = _pricingPath(tokenA, tokenB);
        return path;
    }

    /// @inheritdoc IFeedRegistry
    function batchRegisterFeedMappings(
        FeedMappingArgs[] memory args
    ) external override(FeedRegistry, IFeedRegistry) onlyOwner {
        for (uint256 i = 0; i < args.length; i++) {
            address token = _tokenToDenomination(args[i].token);
            address denomination = args[i].denomination;
            address feed = args[i].feed;

            _revertIfTokensAreSame(token, denomination);
            _revertIfZeroAddress(token, denomination);
            _revertIfInvalidDenomination(denomination);

            bytes32 keyForPair = token.keyForUnsortedPair(denomination);
            FeedRegistryStorage.layout().feeds[keyForPair] = feed;

            ChainlinkAdapterStorage.Layout storage l = ChainlinkAdapterStorage.layout();

            if (feed == address(0)) {
                for (uint256 j = 0; j < l.pairedTokens[token].length(); j++) {
                    address pairedToken = l.pairedTokens[token].at(j);
                    (address sortedA, address sortedB) = _mapToDenominationAndSort(token, pairedToken);
                    l.pricingPath[sortedA.keyForSortedPair(sortedB)] = PricingPath.NONE;
                }

                delete l.pairedTokens[token];
            }
        }

        emit FeedMappingsRegistered(args);
    }

    /// @inheritdoc IPriceRepository
    function setTokenPriceAt(
        address token,
        address denomination,
        uint256 timestamp,
        UD60x18 price
    ) external override(PriceRepository, IPriceRepository) nonReentrant {
        _revertIfTokensAreSame(token, denomination);
        _revertIfZeroAddress(token, denomination);

        _revertIfInvalidDenomination(denomination);
        _revertIfNotWhitelistedRelayer(msg.sender);

        PriceRepositoryStorage.layout().prices[token][denomination][timestamp] = price;
        emit PriceUpdate(token, denomination, timestamp, price);
    }

    /// @notice Returns the pricing path between `tokenA` and `tokenB` and the mapped tokens (unsorted)
    function _pricingPath(
        address tokenA,
        address tokenB
    ) internal view returns (PricingPath path, address mappedTokenA, address mappedTokenB) {
        (mappedTokenA, mappedTokenB) = _mapToDenomination(tokenA, tokenB);
        (address sortedA, address sortedB) = mappedTokenA.sortTokens(mappedTokenB);
        path = ChainlinkAdapterStorage.layout().pricingPath[sortedA.keyForSortedPair(sortedB)];
    }

    /// @notice Returns the price of `tokenIn` denominated in `tokenOut` when the pair is either ETH/USD, token/ETH or
    ///         token/USD
    function _getDirectPrice(
        PricingPath path,
        address tokenIn,
        address tokenOut,
        uint256 target
    ) internal view returns (UD60x18) {
        UD60x18 price;

        if (path == PricingPath.ETH_USD) {
            price = _getETHUSD(target);
        } else if (path == PricingPath.TOKEN_USD) {
            price = _getPriceAgainstUSD(tokenOut.isUSD() ? tokenIn : tokenOut, target);
        } else if (path == PricingPath.TOKEN_ETH) {
            price = _getPriceAgainstETH(tokenOut.isETH() ? tokenIn : tokenOut, target);
        }

        bool invert = tokenIn.isUSD() || (path == PricingPath.TOKEN_ETH && tokenIn.isETH());

        return invert ? price.inv() : price;
    }

    /// @notice Returns the price of `tokenIn` denominated in `tokenOut` when both tokens share the same token
    ///         denomination (either ETH or USD)
    function _getPriceSameDenomination(
        PricingPath path,
        address tokenIn,
        address tokenOut,
        uint256 target
    ) internal view returns (UD60x18) {
        int8 factor = PricingPath.TOKEN_USD_TOKEN == path ? int8(ETH_DECIMALS - FOREX_DECIMALS) : int8(0);
        address denomination = path == PricingPath.TOKEN_USD_TOKEN ? Denominations.USD : Denominations.ETH;

        uint256 tokenInToDenomination = _fetchPrice(tokenIn, denomination, target, factor);
        uint256 tokenOutToDenomination = _fetchPrice(tokenOut, denomination, target, factor);

        UD60x18 adjustedTokenInToDenomination = ud(_scale(tokenInToDenomination, factor));
        UD60x18 adjustedTokenOutToDenomination = ud(_scale(tokenOutToDenomination, factor));

        return adjustedTokenInToDenomination / adjustedTokenOutToDenomination;
    }

    /// @notice Returns the price of `tokenIn` denominated in `tokenOut` when one of the tokens uses ETH as the
    ///         denomination, and the other USD
    function _getPriceDifferentDenomination(
        PricingPath path,
        address tokenIn,
        address tokenOut,
        uint256 target
    ) internal view returns (UD60x18) {
        UD60x18 adjustedEthToUSDPrice = _getETHUSD(target);

        bool isTokenInUSD = (path == PricingPath.A_USD_ETH_B && tokenIn < tokenOut) ||
            (path == PricingPath.A_ETH_USD_B && tokenIn > tokenOut);

        if (isTokenInUSD) {
            UD60x18 adjustedTokenInToUSD = _getPriceAgainstUSD(tokenIn, target);
            UD60x18 tokenOutToETH = _getPriceAgainstETH(tokenOut, target);
            return adjustedTokenInToUSD / adjustedEthToUSDPrice / tokenOutToETH;
        } else {
            UD60x18 tokenInToETH = _getPriceAgainstETH(tokenIn, target);
            UD60x18 adjustedTokenOutToUSD = _getPriceAgainstUSD(tokenOut, target);
            return (tokenInToETH * adjustedEthToUSDPrice) / adjustedTokenOutToUSD;
        }
    }

    /// @notice Returns the price of `tokenIn` denominated in `tokenOut` when the pair is token/WBTC
    function _getPriceWBTCPrice(address tokenIn, address tokenOut, uint256 target) internal view returns (UD60x18) {
        bool isTokenInWBTC = tokenIn == WRAPPED_BTC_TOKEN;

        UD60x18 adjustedWBTCToUSDPrice = _getWBTCBTC(target) * _getBTCUSD(target);
        UD60x18 adjustedTokenToUSD = _getPriceAgainstUSD(!isTokenInWBTC ? tokenIn : tokenOut, target);

        UD60x18 price = adjustedWBTCToUSDPrice / adjustedTokenToUSD;
        return !isTokenInWBTC ? price.inv() : price;
    }

    /// @notice Returns the pricing path between `tokenA` and `tokenB`
    function _determinePricingPath(address tokenA, address tokenB) internal view virtual returns (PricingPath) {
        _revertIfTokensAreSame(tokenA, tokenB);
        _revertIfZeroAddress(tokenA, tokenB);

        (tokenA, tokenB) = tokenA.sortTokens(tokenB);

        bool isTokenAUSD = tokenA.isUSD();
        bool isTokenBUSD = tokenB.isUSD();
        bool isTokenAETH = tokenA.isETH();
        bool isTokenBETH = tokenB.isETH();
        bool isTokenAWBTC = tokenA == WRAPPED_BTC_TOKEN;
        bool isTokenBWBTC = tokenB == WRAPPED_BTC_TOKEN;

        if ((isTokenAETH && isTokenBUSD) || (isTokenAUSD && isTokenBETH)) {
            return PricingPath.ETH_USD;
        }

        address srcToken;
        ConversionType conversionType;
        PricingPath preferredPath;
        PricingPath fallbackPath;

        bool wbtcUSDFeedExists = _feedExists(isTokenAWBTC ? tokenA : tokenB, Denominations.USD);

        if ((isTokenAWBTC || isTokenBWBTC) && !wbtcUSDFeedExists) {
            // If one of the token is WBTC and there is no WBTC/USD feed, we want to convert the other token to WBTC
            // Note: If there is a WBTC/USD feed the preferred path is TOKEN_USD, TOKEN_USD_TOKEN, or A_USD_ETH_B
            srcToken = isTokenAWBTC ? tokenB : tokenA;
            conversionType = ConversionType.TO_BTC;
            // PricingPath used are same, but effective path slightly differs because of the 2 attempts in
            // `_tryToFindPath`
            preferredPath = PricingPath.TOKEN_USD_BTC_WBTC; // Token -> USD -> BTC -> WBTC
            fallbackPath = PricingPath.TOKEN_USD_BTC_WBTC; // Token -> BTC -> WBTC
        } else if (isTokenBUSD) {
            // If tokenB is USD, we want to convert tokenA to USD
            srcToken = tokenA;
            conversionType = ConversionType.TO_USD;
            preferredPath = PricingPath.TOKEN_USD;
            fallbackPath = PricingPath.A_ETH_USD_B; // USD -> B is skipped, if B == USD
        } else if (isTokenAUSD) {
            // If tokenA is USD, we want to convert tokenB to USD
            srcToken = tokenB;
            conversionType = ConversionType.TO_USD;
            preferredPath = PricingPath.TOKEN_USD;
            fallbackPath = PricingPath.A_USD_ETH_B; // A -> USD is skipped, if A == USD
        } else if (isTokenBETH) {
            // If tokenB is ETH, we want to convert tokenA to ETH
            srcToken = tokenA;
            conversionType = ConversionType.TO_ETH;
            preferredPath = PricingPath.TOKEN_ETH;
            fallbackPath = PricingPath.A_USD_ETH_B; // B -> ETH is skipped, if B == ETH
        } else if (isTokenAETH) {
            // If tokenA is ETH, we want to convert tokenB to ETH
            srcToken = tokenB;
            conversionType = ConversionType.TO_ETH;
            preferredPath = PricingPath.TOKEN_ETH;
            fallbackPath = PricingPath.A_ETH_USD_B; // A -> ETH is skipped, if A == ETH
        } else if (_feedExists(tokenA, Denominations.USD)) {
            // If tokenA has a USD feed, we want to convert tokenB to USD, and then use tokenA USD feed to effectively
            // convert tokenB -> tokenA
            srcToken = tokenB;
            conversionType = ConversionType.TO_USD_TO_TOKEN;
            preferredPath = PricingPath.TOKEN_USD_TOKEN;
            fallbackPath = PricingPath.A_USD_ETH_B;
        } else if (_feedExists(tokenA, Denominations.ETH)) {
            // If tokenA has an ETH feed, we want to convert tokenB to ETH, and then use tokenA ETH feed to effectively
            // convert tokenB -> tokenA
            srcToken = tokenB;
            conversionType = ConversionType.TO_ETH_TO_TOKEN;
            preferredPath = PricingPath.TOKEN_ETH_TOKEN;
            fallbackPath = PricingPath.A_ETH_USD_B;
        } else {
            return PricingPath.NONE;
        }

        return _tryToFindPath(srcToken, conversionType, preferredPath, fallbackPath);
    }

    /// @notice Attempts to find the best pricing path for `token` based on the `conversionType`, if a feed exists
    function _tryToFindPath(
        address token,
        ConversionType conversionType,
        PricingPath preferredPath,
        PricingPath fallbackPath
    ) internal view returns (PricingPath) {
        address preferredDenomination;
        address fallbackDenomination;

        if (conversionType == ConversionType.TO_BTC) {
            preferredDenomination = Denominations.USD;
            fallbackDenomination = Denominations.BTC;
        } else if (conversionType == ConversionType.TO_USD) {
            preferredDenomination = Denominations.USD;
            fallbackDenomination = Denominations.ETH;
        } else if (conversionType == ConversionType.TO_ETH) {
            preferredDenomination = Denominations.ETH;
            fallbackDenomination = Denominations.USD;
        } else if (conversionType == ConversionType.TO_USD_TO_TOKEN) {
            preferredDenomination = Denominations.USD;
            fallbackDenomination = Denominations.ETH;
        } else if (conversionType == ConversionType.TO_ETH_TO_TOKEN) {
            preferredDenomination = Denominations.ETH;
            fallbackDenomination = Denominations.USD;
        }

        if (_feedExists(token, preferredDenomination)) {
            return preferredPath;
        } else if (_feedExists(token, fallbackDenomination)) {
            return fallbackPath;
        } else {
            return PricingPath.NONE;
        }
    }

    /// @notice Returns the latest price of `token` denominated in `denomination`, if `target` is 0, otherwise we
    ///         algorithmically search for a price which meets our criteria
    function _fetchPrice(
        address token,
        address denomination,
        uint256 target,
        int8 factor
    ) internal view returns (uint256) {
        return
            target == 0 ? _fetchLatestPrice(token, denomination) : _fetchPriceAt(token, denomination, target, factor);
    }

    /// @notice Returns the latest price of `token` denominated in `denomination`
    function _fetchLatestPrice(address token, address denomination) internal view returns (uint256) {
        address feed = _feed(token, denomination);
        (, int256 price, , uint256 updatedAt, ) = _latestRoundData(feed);

        _revertIfPriceInvalid(price);
        _revertIfPriceLeftOfTargetStale(updatedAt, block.timestamp);

        return price.toUint256();
    }

    /// @notice Returns the price of `token` denominated in `denomination` at or left of `target`. If the price left of
    ///         target is stale, we revert and wait until a price override is set.
    function _fetchPriceAt(
        address token,
        address denomination,
        uint256 target,
        int8 factor
    ) internal view returns (uint256) {
        UD60x18 priceOverrideAtTarget = _getTokenPriceAt(token, denomination, target);
        // NOTE: The override prices are 18 decimals to maintain consistency across all adapters, because of this we need
        // to downscale the override price to the precision used by the feed before calculating the final price
        if (priceOverrideAtTarget > ZERO) return _scale(priceOverrideAtTarget.unwrap(), -int8(factor));

        address feed = _feed(token, denomination);
        (uint80 roundId, int256 price, , uint256 updatedAt, ) = _latestRoundData(feed);
        (uint16 phaseId, uint64 nextAggregatorRoundId) = ChainlinkAdapterStorage.parseRoundId(roundId);

        BinarySearchDataInternal memory binarySearchData;

        // if latest round data is on right side of target, search for round data at or left of target
        if (updatedAt > target) {
            binarySearchData.rightPrice = price;
            binarySearchData.rightUpdatedAt = updatedAt;

            binarySearchData = _performBinarySearchForRoundData(
                binarySearchData,
                feed,
                phaseId,
                nextAggregatorRoundId,
                target
            );

            if (binarySearchData.leftUpdatedAt == 0) {
                // if leftUpdatedAt is 0, it means that the target is not in the current phase, therefore, we must
                // revert and wait until a price override is set in PriceRepository
                revert ChainlinkAdapter__PriceAtOrLeftOfTargetNotFound(token, denomination, target);
            }

            price = binarySearchData.leftPrice;
            updatedAt = binarySearchData.leftUpdatedAt;
        }

        _revertIfPriceInvalid(price);
        _revertIfPriceLeftOfTargetStale(updatedAt, target);

        return price.toUint256();
    }

    /// @notice Performs a binary search to find the round data closest to the target timestamp
    function _performBinarySearchForRoundData(
        BinarySearchDataInternal memory binarySearchData,
        address feed,
        uint16 phaseId,
        uint64 nextAggregatorRoundId,
        uint256 target
    ) internal view returns (BinarySearchDataInternal memory) {
        uint64 lowestAggregatorRoundId = 0;
        uint64 highestAggregatorRoundId = nextAggregatorRoundId;

        uint80 roundId;
        int256 price;
        uint256 updatedAt;

        while (lowestAggregatorRoundId <= highestAggregatorRoundId) {
            nextAggregatorRoundId = lowestAggregatorRoundId + (highestAggregatorRoundId - lowestAggregatorRoundId) / 2;
            roundId = ChainlinkAdapterStorage.formatRoundId(phaseId, nextAggregatorRoundId);
            (, price, , updatedAt, ) = _getRoundData(feed, roundId);

            if (target == updatedAt) {
                binarySearchData.leftPrice = price;
                binarySearchData.leftUpdatedAt = updatedAt;
                break;
            }

            if (target > updatedAt) {
                binarySearchData.leftPrice = price;
                binarySearchData.leftUpdatedAt = updatedAt;
                lowestAggregatorRoundId = nextAggregatorRoundId + 1;
            } else {
                binarySearchData.rightPrice = price;
                binarySearchData.rightUpdatedAt = updatedAt;

                if (nextAggregatorRoundId == 0) break;
                highestAggregatorRoundId = nextAggregatorRoundId - 1;
            }
        }

        return binarySearchData;
    }

    /// @notice Try/Catch wrapper for Chainlink aggregator's latestRoundData() function
    function _latestRoundData(address feed) internal view returns (uint80, int256, uint256, uint256, uint80) {
        try AggregatorProxyInterface(feed).latestRoundData() returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) {
            return (roundId, answer, startedAt, updatedAt, answeredInRound);
        } catch Error(string memory reason) {
            revert(reason);
        } catch (bytes memory data) {
            revert ChainlinkAdapter__LatestRoundDataCallReverted(data);
        }
    }

    /// @notice Try/Catch wrapper for Chainlink aggregator's getRoundData() function
    function _getRoundData(
        address feed,
        uint80 roundId
    ) internal view returns (uint80, int256, uint256, uint256, uint80) {
        try AggregatorProxyInterface(feed).getRoundData(roundId) returns (
            uint80 _roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) {
            return (_roundId, answer, startedAt, updatedAt, answeredInRound);
        } catch Error(string memory reason) {
            revert(reason);
        } catch (bytes memory data) {
            revert ChainlinkAdapter__GetRoundDataCallReverted(data);
        }
    }

    /// @notice Returns the Chainlink aggregator for `token` / `denomination`
    function _aggregator(address token, address denomination) internal view returns (address[] memory aggregator) {
        address feed = _feed(token, denomination);
        aggregator = new address[](1);
        aggregator[0] = AggregatorProxyInterface(feed).aggregator();
    }

    /// @notice Returns decimals for `aggregator`
    function _aggregatorDecimals(address aggregator) internal view returns (uint8) {
        return AggregatorProxyInterface(aggregator).decimals();
    }

    /// @notice Returns the scaled price of `token` denominated in USD at `target`
    function _getPriceAgainstUSD(address token, uint256 target) internal view returns (UD60x18) {
        int8 factor = int8(ETH_DECIMALS - FOREX_DECIMALS);
        return token.isUSD() ? ONE : ud(_scale(_fetchPrice(token, Denominations.USD, target, factor), factor));
    }

    /// @notice Returns the scaled price of `token` denominated in ETH at `target`
    function _getPriceAgainstETH(address token, uint256 target) internal view returns (UD60x18) {
        return token.isETH() ? ONE : ud(_fetchPrice(token, Denominations.ETH, target, 0));
    }

    /// @notice Returns the scaled price of ETH denominated in USD at `target`
    function _getETHUSD(uint256 target) internal view returns (UD60x18) {
        int8 factor = int8(ETH_DECIMALS - FOREX_DECIMALS);
        return ud(_scale(_fetchPrice(Denominations.ETH, Denominations.USD, target, factor), factor));
    }

    /// @notice Returns the scaled price of BTC denominated in USD at `target`
    function _getBTCUSD(uint256 target) internal view returns (UD60x18) {
        int8 factor = int8(ETH_DECIMALS - FOREX_DECIMALS);
        return ud(_scale(_fetchPrice(Denominations.BTC, Denominations.USD, target, factor), factor));
    }

    /// @notice Returns the scaled price of WBTC denominated in BTC at `target`
    function _getWBTCBTC(uint256 target) internal view returns (UD60x18) {
        int8 factor = int8(ETH_DECIMALS - FOREX_DECIMALS);
        return ud(_scale(_fetchPrice(WRAPPED_BTC_TOKEN, Denominations.BTC, target, factor), factor));
    }

    /// @notice Revert if the difference between `target` and `updateAt` is greater than `STALE_PRICE_THRESHOLD`
    function _revertIfPriceLeftOfTargetStale(uint256 updatedAt, uint256 target) internal pure {
        if (target - updatedAt > STALE_PRICE_THRESHOLD)
            revert ChainlinkAdapter__PriceLeftOfTargetStale(updatedAt, target);
    }

    /// @notice Revert if `denomination` is not a valid
    function _revertIfInvalidDenomination(address denomination) internal pure {
        if (!denomination.isETH() && !denomination.isBTC() && !denomination.isUSD())
            revert ChainlinkAdapter__InvalidDenomination(denomination);
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {Denominations} from "@chainlink/contracts/src/v0.8/Denominations.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

import {IChainlinkAdapter} from "./IChainlinkAdapter.sol";

library ChainlinkAdapterStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.ChainlinkAdapter");

    struct Layout {
        mapping(bytes32 key => IChainlinkAdapter.PricingPath) pricingPath;
        mapping(address token => EnumerableSet.AddressSet tokens) pairedTokens;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function formatRoundId(uint16 phaseId, uint64 aggregatorRoundId) internal pure returns (uint80) {
        return uint80((uint256(phaseId) << 64) | aggregatorRoundId);
    }

    function parseRoundId(uint256 roundId) internal pure returns (uint16 phaseId, uint64 aggregatorRoundId) {
        phaseId = uint16(roundId >> 64);
        aggregatorRoundId = uint64(roundId);
    }

    function isUSD(address token) internal pure returns (bool) {
        return token == Denominations.USD;
    }

    function isBTC(address token) internal pure returns (bool) {
        return token == Denominations.BTC;
    }

    function isETH(address token) internal pure returns (bool) {
        return token == Denominations.ETH;
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {IOracleAdapter} from "../IOracleAdapter.sol";
import {IFeedRegistry} from "../IFeedRegistry.sol";
import {IPriceRepository} from "../../adapter/IPriceRepository.sol";

interface IChainlinkAdapter is IOracleAdapter, IFeedRegistry, IPriceRepository {
    // Note : The following enums do not follow regular style guidelines for the purpose of easier readability

    /// @notice The path that will be used to calculate quotes for a given pair
    enum PricingPath {
        // There is no path calculated
        NONE,
        // Will use the ETH/USD feed
        ETH_USD,
        // Will use a token/USD feed
        TOKEN_USD,
        // Will use a token/ETH feed
        TOKEN_ETH,
        // Will use tokenIn/USD and tokenOut/USD feeds
        TOKEN_USD_TOKEN,
        // Will use tokenIn/ETH and tokenOut/ETH feeds
        TOKEN_ETH_TOKEN,
        // Will use tokenA/USD, tokenB/ETH and ETH/USD feeds
        A_USD_ETH_B,
        // Will use tokenA/ETH, tokenB/USD and ETH/USD feeds
        A_ETH_USD_B,
        // Will use a token/USD, BTC/USD, WBTC/BTC feeds
        TOKEN_USD_BTC_WBTC
    }

    /// @notice The conversion type used when determining the token pair pricing path
    enum ConversionType {
        TO_BTC, // Token -> BTC
        TO_USD, // Token -> USD
        TO_ETH, // Token -> ETH
        TO_USD_TO_TOKEN, // Token -> USD -> Token
        TO_ETH_TO_TOKEN // Token -> ETH -> Token
    }

    /// @notice Thrown when the getRoundData call reverts without a reason
    error ChainlinkAdapter__GetRoundDataCallReverted(bytes data);

    /// @notice Thrown when the denomination is invalid
    error ChainlinkAdapter__InvalidDenomination(address denomination);

    /// @notice Thrown when the lastRoundData call reverts without a reason
    error ChainlinkAdapter__LatestRoundDataCallReverted(bytes data);

    /// @notice Thrown when a price at or to the left of target is not found
    error ChainlinkAdapter__PriceAtOrLeftOfTargetNotFound(address token, address denomination, uint256 target);

    /// @notice Thrown when price left of target is stale
    error ChainlinkAdapter__PriceLeftOfTargetStale(uint256 updatedAt, uint256 target);

    /// @notice Emitted when the adapter updates the pricing path for a pair
    /// @param tokenA One of the pair's tokens
    /// @param tokenB The other of the pair's tokens
    /// @param path The new path
    event UpdatedPathForPair(address tokenA, address tokenB, PricingPath path);

    struct BinarySearchDataInternal {
        int256 leftPrice;
        uint256 leftUpdatedAt;
        int256 rightPrice;
        uint256 rightUpdatedAt;
    }

    /// @notice Returns the pricing path that will be used when quoting the given pair
    /// @dev tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
    /// @param tokenA One of the pair's tokens
    /// @param tokenB The other of the pair's tokens
    /// @return The pricing path that will be used
    function pricingPath(address tokenA, address tokenB) external view returns (PricingPath);
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {Denominations} from "@chainlink/contracts/src/v0.8/Denominations.sol";

import {IFeedRegistry} from "./IFeedRegistry.sol";
import {FeedRegistryStorage} from "./FeedRegistryStorage.sol";
import {Tokens} from "./Tokens.sol";

/// @title Adapter feed registry implementation
abstract contract FeedRegistry is IFeedRegistry {
    using FeedRegistryStorage for FeedRegistryStorage.Layout;
    using Tokens for address;

    address internal immutable WRAPPED_NATIVE_TOKEN;
    address internal immutable WRAPPED_BTC_TOKEN;

    constructor(address _wrappedNativeToken, address _wrappedBTCToken) {
        WRAPPED_NATIVE_TOKEN = _wrappedNativeToken;
        WRAPPED_BTC_TOKEN = _wrappedBTCToken;
    }

    /// @inheritdoc IFeedRegistry
    function batchRegisterFeedMappings(FeedMappingArgs[] memory args) external virtual;

    /// @inheritdoc IFeedRegistry
    function feed(address token, address denomination) external view returns (address) {
        return _feed(_tokenToDenomination(token), denomination);
    }

    /// @notice Returns the feed for `token` and `denomination`
    function _feed(address token, address denomination) internal view returns (address) {
        return FeedRegistryStorage.layout().feeds[token.keyForUnsortedPair(denomination)];
    }

    /// @notice Returns true if a feed exists for `token` and `denomination`
    function _feedExists(address token, address denomination) internal view returns (bool) {
        return _feed(token, denomination) != address(0);
    }

    /// @notice Returns the denomination mapped to `token`, if it has one
    /// @dev Should only map wrapped tokens which are guaranteed to have a 1:1 ratio
    function _tokenToDenomination(address token) internal view returns (address) {
        return token == WRAPPED_NATIVE_TOKEN ? Denominations.ETH : token;
    }

    /// @notice Returns the sorted and mapped tokens for `tokenA` and `tokenB`
    function _mapToDenominationAndSort(address tokenA, address tokenB) internal view returns (address, address) {
        (address mappedTokenA, address mappedTokenB) = _mapToDenomination(tokenA, tokenB);
        return mappedTokenA.sortTokens(mappedTokenB);
    }

    /// @notice Returns the mapped tokens for `tokenA` and `tokenB`
    function _mapToDenomination(
        address tokenA,
        address tokenB
    ) internal view returns (address mappedTokenA, address mappedTokenB) {
        mappedTokenA = _tokenToDenomination(tokenA);
        mappedTokenB = _tokenToDenomination(tokenB);
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

library FeedRegistryStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.FeedRegistry");

    struct Layout {
        mapping(bytes32 key => address feed) feeds;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

interface IFeedRegistry {
    struct FeedMappingArgs {
        address token;
        address denomination;
        address feed;
    }

    /// @notice Emitted when new price feed mappings are registered
    /// @param args The arguments for the new mappings
    event FeedMappingsRegistered(FeedMappingArgs[] args);

    /// @notice Registers mappings of ERC20 token, and denomination (ETH, BTC, or USD) to feed
    /// @param args The arguments for the new mappings
    function batchRegisterFeedMappings(FeedMappingArgs[] memory args) external;

    /// @notice Returns the feed for `token` and `denomination`
    /// @param token The exchange token (ERC20 token)
    /// @param denomination The Chainlink token denomination to quote against (ETH, BTC, or USD)
    /// @return The feed address
    function feed(address token, address denomination) external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

interface IOracleAdapter {
    /// @notice The type of adapter
    enum AdapterType {
        None,
        Chainlink
    }

    /// @notice Thrown when attempting to increase array size
    error OracleAdapter__ArrayCannotExpand(uint256 arrayLength, uint256 size);

    /// @notice Thrown when the target is zero or before the current block timestamp
    error OracleAdapter__InvalidTarget(uint256 target, uint256 blockTimestamp);

    /// @notice Thrown when the price is non-positive
    error OracleAdapter__InvalidPrice(int256 price);

    /// @notice Thrown when trying to add support for a pair that cannot be supported
    error OracleAdapter__PairCannotBeSupported(address tokenA, address tokenB);

    /// @notice Thrown when trying to execute a quote with a pair that isn't supported
    error OracleAdapter__PairNotSupported(address tokenA, address tokenB);

    /// @notice Thrown when trying to add pair where addresses are the same
    error OracleAdapter__TokensAreSame(address tokenA, address tokenB);

    /// @notice Thrown when one of the parameters is a zero address
    error OracleAdapter__ZeroAddress();

    /// @notice Returns whether the pair has already been added to the adapter and if it supports the path required for
    ///         the pair
    ///         (true, true): Pair is fully supported
    ///         (false, true): Pair is not supported, but can be added
    ///         (false, false): Pair cannot be supported
    /// @dev tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
    /// @param tokenA One of the pair's tokens
    /// @param tokenB The other of the pair's tokens
    /// @return isCached True if the pair has been cached, false otherwise
    /// @return hasPath True if the pair has a valid path, false otherwise
    function isPairSupported(address tokenA, address tokenB) external view returns (bool isCached, bool hasPath);

    /// @notice Stores or updates the given token pair data provider configuration. This function will let the adapter
    ///         take some actions to configure the pair, in preparation for future quotes. Can be called many times in
    ///         order to let the adapter re-configure for a new context
    /// @param tokenA One of the pair's tokens
    /// @param tokenB The other of the pair's tokens
    function upsertPair(address tokenA, address tokenB) external;

    /// @notice Returns the most recent price for the given token pair
    /// @param tokenIn The exchange token (base token)
    /// @param tokenOut The token to quote against (quote token)
    /// @return The most recent price for the token pair (18 decimals)
    function getPrice(address tokenIn, address tokenOut) external view returns (UD60x18);

    /// @notice Returns the price closest to `target` for the given token pair
    /// @param tokenIn The exchange token (base token)
    /// @param tokenOut The token to quote against (quote token)
    /// @param target Reference timestamp of the quote
    /// @return Historical price for the token pair (18 decimals)
    function getPriceAt(address tokenIn, address tokenOut, uint256 target) external view returns (UD60x18);

    /// @notice Describes the pricing path used to convert the token to ETH
    /// @param token The token from where the pricing path starts
    /// @return adapterType The type of adapter
    /// @return path The path required to convert the token to ETH
    /// @return decimals The decimals of each token in the path
    function describePricingPath(
        address token
    ) external view returns (AdapterType adapterType, address[][] memory path, uint8[] memory decimals);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

interface IPriceRepository {
    event PriceUpdate(address indexed token, address indexed denomination, uint256 timestamp, UD60x18 price);

    /// @notice Set the price of `token` denominated in `denomination` at the given `timestamp`
    /// @param token The exchange token (ERC20 token)
    /// @param denomination The Chainlink token denomination to quote against (ETH, BTC, or USD)
    /// @param timestamp Reference timestamp (in seconds)
    /// @param price The amount of `token` denominated in `denomination` (18 decimals)
    function setTokenPriceAt(address token, address denomination, uint256 timestamp, UD60x18 price) external;
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {SafeCast} from "@solidstate/contracts/utils/SafeCast.sol";

import {IOracleAdapter} from "./IOracleAdapter.sol";

/// @title Base oracle adapter implementation
abstract contract OracleAdapter is IOracleAdapter {
    using SafeCast for int8;

    /// @notice Scales `amount` by `factor`
    function _scale(uint256 amount, int8 factor) internal pure returns (uint256) {
        if (factor == 0) return amount;

        if (factor < 0) {
            return amount / (10 ** (-factor).toUint256());
        } else {
            return amount * (10 ** factor.toUint256());
        }
    }

    /// @notice Revert if `target` is zero or after block.timestamp
    function _revertIfTargetInvalid(uint256 target) internal view {
        if (target == 0 || target > block.timestamp) revert OracleAdapter__InvalidTarget(target, block.timestamp);
    }

    /// @notice Revert if `price` is zero or negative
    function _revertIfPriceInvalid(int256 price) internal pure {
        if (price <= 0) revert OracleAdapter__InvalidPrice(price);
    }

    /// @notice Revert if `tokenA` has same address as `tokenB`
    function _revertIfTokensAreSame(address tokenA, address tokenB) internal pure {
        if (tokenA == tokenB) revert OracleAdapter__TokensAreSame(tokenA, tokenB);
    }

    /// @notice Revert if `tokenA` or `tokenB` are null addresses
    function _revertIfZeroAddress(address tokenA, address tokenB) internal pure {
        if (tokenA == address(0) || tokenB == address(0)) revert OracleAdapter__ZeroAddress();
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";

import {RelayerAccessManager} from "../relayer/RelayerAccessManager.sol";

import {IPriceRepository} from "./IPriceRepository.sol";
import {PriceRepositoryStorage} from "./PriceRepositoryStorage.sol";

abstract contract PriceRepository is IPriceRepository, ReentrancyGuard, RelayerAccessManager {
    /// @inheritdoc IPriceRepository
    function setTokenPriceAt(address token, address denomination, uint256 timestamp, UD60x18 price) external virtual;

    /// @notice Returns the price of `token` denominated in `denomination` at a given timestamp, if zero, a price has
    ///         not been recorded
    function _getTokenPriceAt(
        address token,
        address denomination,
        uint256 timestamp
    ) internal view returns (UD60x18 price) {
        price = PriceRepositoryStorage.layout().prices[token][denomination][timestamp];
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

library PriceRepositoryStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.PriceRepository");

    struct Layout {
        mapping(address token => mapping(address denomination => mapping(uint256 timestamp => UD60x18 price))) prices;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

uint8 constant FOREX_DECIMALS = 8;
uint8 constant ETH_DECIMALS = 18;

library Tokens {
    /// @notice Returns the key for the unsorted `tokenA` and `tokenB`
    function keyForUnsortedPair(address tokenA, address tokenB) internal pure returns (bytes32) {
        (address sortedA, address sortedTokenB) = sortTokens(tokenA, tokenB);
        return keyForSortedPair(sortedA, sortedTokenB);
    }

    /// @notice Returns the key for the sorted `tokenA` and `tokenB`
    function keyForSortedPair(address tokenA, address tokenB) internal pure returns (bytes32) {
        return keccak256(abi.encode(tokenA, tokenB));
    }

    /// @notice Returns the sorted `tokenA` and `tokenB`, where sortedA < sortedB
    function sortTokens(address tokenA, address tokenB) internal pure returns (address sortedA, address sortedB) {
        (sortedA, sortedB) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {IPoolFactoryEvents} from "./IPoolFactoryEvents.sol";

interface IPoolFactory is IPoolFactoryEvents {
    error PoolFactory__IdenticalAddresses();
    error PoolFactory__InitializationFeeIsZero();
    error PoolFactory__InitializationFeeRequired(uint256 msgValue, uint256 fee);
    error PoolFactory__InvalidInput();
    error PoolFactory__InvalidOracleAdapter();
    error PoolFactory__NotAuthorized();
    error PoolFactory__OptionExpired(uint256 maturity);
    error PoolFactory__OptionMaturityExceedsMax(uint256 maturity);
    error PoolFactory__OptionMaturityNot8UTC(uint256 maturity);
    error PoolFactory__OptionMaturityNotFriday(uint256 maturity);
    error PoolFactory__OptionMaturityNotLastFriday(uint256 maturity);
    error PoolFactory__OptionStrikeEqualsZero();
    error PoolFactory__OptionStrikeInvalid(UD60x18 strike, UD60x18 strikeInterval);
    error PoolFactory__PoolAlreadyDeployed(address poolAddress);
    error PoolFactory__PoolNotExpired();
    error PoolFactory__TransferNativeTokenFailed();
    error PoolFactory__ZeroAddress();

    struct PoolKey {
        // Address of base token
        address base;
        // Address of quote token
        address quote;
        // Address of oracle adapter
        address oracleAdapter;
        // The strike of the option (18 decimals)
        UD60x18 strike;
        // The maturity timestamp of the option
        uint256 maturity;
        // Whether the pool is for call or put options
        bool isCallPool;
    }

    /// @notice Returns whether the given address is a pool
    /// @param contractAddress The address to check
    /// @return Whether the given address is a pool
    function isPool(address contractAddress) external view returns (bool);

    /// @notice Returns the address of a valid pool, and whether it has been deployed. If the pool configuration is invalid
    ///         the transaction will revert.
    /// @param k The pool key
    /// @return pool The pool address
    /// @return isDeployed Whether the pool has been deployed
    function getPoolAddress(PoolKey calldata k) external view returns (address pool, bool isDeployed);

    /// @notice Set the discountPerPool for new pools - only callable by owner
    /// @param discountPerPool The new discount percentage (18 decimals)
    function setDiscountPerPool(UD60x18 discountPerPool) external;

    /// @notice Set the feeReceiver for initialization fees - only callable by owner
    /// @param feeReceiver The new fee receiver address
    function setFeeReceiver(address feeReceiver) external;

    /// @notice Deploy a new option pool
    /// @param k The pool key
    /// @return poolAddress The address of the deployed pool
    function deployPool(PoolKey calldata k) external payable returns (address poolAddress);

    /// @notice Removes the discount caused by an existing pool, can only be called by the pool after maturity
    /// @param k The pool key
    function removeDiscount(PoolKey calldata k) external;

    /// @notice Calculates the initialization fee for a pool
    /// @param k The pool key
    /// @return The initialization fee (18 decimals)
    function initializationFee(PoolKey calldata k) external view returns (UD60x18);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {IPoolFactory} from "./IPoolFactory.sol";

interface IPoolFactoryDeployer {
    error PoolFactoryDeployer__NotPoolFactory(address caller);

    /// @notice Deploy a new option pool
    /// @param k The pool key
    /// @return poolAddress The address of the deployed pool
    function deployPool(IPoolFactory.PoolKey calldata k) external returns (address poolAddress);

    /// @notice Calculate the deterministic address deployment of a pool
    function calculatePoolAddress(IPoolFactory.PoolKey calldata k) external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {IOracleAdapter} from "../adapter/IOracleAdapter.sol";

interface IPoolFactoryEvents {
    event SetDiscountPerPool(UD60x18 indexed discountPerPool);
    event SetFeeReceiver(address indexed feeReceiver);
    event PoolDeployed(
        address indexed base,
        address indexed quote,
        address oracleAdapter,
        UD60x18 strike,
        uint256 maturity,
        bool isCallPool,
        address poolAddress
    );

    event PricingPath(
        address pool,
        address[][] basePath,
        uint8[] basePathDecimals,
        IOracleAdapter.AdapterType baseAdapterType,
        address[][] quotePath,
        uint8[] quotePathDecimals,
        IOracleAdapter.AdapterType quoteAdapterType
    );
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {Denominations} from "@chainlink/contracts/src/v0.8/Denominations.sol";

import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {IPoolFactory} from "./IPoolFactory.sol";
import {IPoolFactoryDeployer} from "./IPoolFactoryDeployer.sol";
import {PoolFactoryStorage} from "./PoolFactoryStorage.sol";
import {PoolStorage} from "../pool/PoolStorage.sol";
import {IOracleAdapter} from "../adapter/IOracleAdapter.sol";

import {OptionMath} from "../libraries/OptionMath.sol";
import {ZERO, ONE} from "../libraries/Constants.sol";

contract PoolFactory is IPoolFactory, OwnableInternal, ReentrancyGuard {
    using PoolFactoryStorage for PoolFactoryStorage.Layout;
    using PoolFactoryStorage for PoolKey;
    using PoolStorage for PoolStorage.Layout;

    address internal immutable DIAMOND;
    // Chainlink price oracle for the WrappedNative/USD pair
    address internal immutable CHAINLINK_ADAPTER;
    // Wrapped native token address (eg WETH, WFTM, etc)
    address internal immutable WRAPPED_NATIVE_TOKEN;
    // Address of the contract handling the proxy deployment.
    // This is in a separate contract so that we can upgrade this contract without having deterministic address calculation change
    address internal immutable POOL_FACTORY_DEPLOYER;

    constructor(address diamond, address chainlinkAdapter, address wrappedNativeToken, address poolFactoryDeployer) {
        DIAMOND = diamond;
        CHAINLINK_ADAPTER = chainlinkAdapter;
        WRAPPED_NATIVE_TOKEN = wrappedNativeToken;
        POOL_FACTORY_DEPLOYER = poolFactoryDeployer;
    }

    /// @inheritdoc IPoolFactory
    function isPool(address contractAddress) external view returns (bool) {
        return PoolFactoryStorage.layout().isPool[contractAddress];
    }

    /// @inheritdoc IPoolFactory
    function getPoolAddress(PoolKey calldata k) external view returns (address pool, bool isDeployed) {
        pool = _getPoolAddress(k.poolKey());
        isDeployed = true;

        if (pool == address(0)) {
            _revertIfAddressInvalid(k);
            _revertIfOptionStrikeInvalid(k.strike);
            _revertIfOptionMaturityInvalid(k.maturity);

            pool = IPoolFactoryDeployer(POOL_FACTORY_DEPLOYER).calculatePoolAddress(k);
            isDeployed = false;
        }
    }

    /// @notice Returns the address of a pool using the encoded `poolKey`
    function _getPoolAddress(bytes32 poolKey) internal view returns (address) {
        return PoolFactoryStorage.layout().pools[poolKey];
    }

    /// @inheritdoc IPoolFactory
    function setDiscountPerPool(UD60x18 discountPerPool) external onlyOwner {
        if (discountPerPool == ZERO || discountPerPool >= ONE) revert PoolFactory__InvalidInput();
        PoolFactoryStorage.Layout storage l = PoolFactoryStorage.layout();
        l.discountPerPool = discountPerPool;
        emit SetDiscountPerPool(discountPerPool);
    }

    /// @inheritdoc IPoolFactory
    function setFeeReceiver(address feeReceiver) external onlyOwner {
        PoolFactoryStorage.Layout storage l = PoolFactoryStorage.layout();
        l.feeReceiver = feeReceiver;
        emit SetFeeReceiver(feeReceiver);
    }

    /// @inheritdoc IPoolFactory
    function deployPool(PoolKey calldata k) external payable nonReentrant returns (address poolAddress) {
        if (k.oracleAdapter != CHAINLINK_ADAPTER) revert PoolFactory__InvalidOracleAdapter();

        _revertIfAddressInvalid(k);

        IOracleAdapter(k.oracleAdapter).upsertPair(k.base, k.quote);

        _revertIfOptionStrikeInvalid(k.strike);
        _revertIfOptionMaturityInvalid(k.maturity);

        bytes32 poolKey = k.poolKey();
        uint256 fee = initializationFee(k).unwrap();

        if (fee == 0) revert PoolFactory__InitializationFeeIsZero();
        if (msg.value < fee) revert PoolFactory__InitializationFeeRequired(msg.value, fee);

        address _poolAddress = _getPoolAddress(poolKey);
        if (_poolAddress != address(0)) revert PoolFactory__PoolAlreadyDeployed(_poolAddress);

        _safeTransferNativeToken(PoolFactoryStorage.layout().feeReceiver, fee);
        if (msg.value > fee) _safeTransferNativeToken(msg.sender, msg.value - fee);

        poolAddress = IPoolFactoryDeployer(POOL_FACTORY_DEPLOYER).deployPool(k);

        PoolFactoryStorage.Layout storage l = PoolFactoryStorage.layout();
        l.pools[poolKey] = poolAddress;
        l.isPool[poolAddress] = true;
        l.strikeCount[k.strikeKey()] += 1;
        l.maturityCount[k.maturityKey()] += 1;

        emit PoolDeployed(k.base, k.quote, k.oracleAdapter, k.strike, k.maturity, k.isCallPool, poolAddress);

        {
            (
                IOracleAdapter.AdapterType baseAdapterType,
                address[][] memory basePath,
                uint8[] memory basePathDecimals
            ) = IOracleAdapter(k.oracleAdapter).describePricingPath(k.base);

            (
                IOracleAdapter.AdapterType quoteAdapterType,
                address[][] memory quotePath,
                uint8[] memory quotePathDecimals
            ) = IOracleAdapter(k.oracleAdapter).describePricingPath(k.quote);

            emit PricingPath(
                poolAddress,
                basePath,
                basePathDecimals,
                baseAdapterType,
                quotePath,
                quotePathDecimals,
                quoteAdapterType
            );
        }
    }

    /// @inheritdoc IPoolFactory
    function removeDiscount(PoolKey calldata k) external nonReentrant {
        if (block.timestamp < k.maturity) revert PoolFactory__PoolNotExpired();

        if (PoolFactoryStorage.layout().pools[k.poolKey()] != msg.sender) revert PoolFactory__NotAuthorized();

        PoolFactoryStorage.layout().strikeCount[k.strikeKey()] -= 1;
        PoolFactoryStorage.layout().maturityCount[k.maturityKey()] -= 1;
    }

    /// @inheritdoc IPoolFactory
    function initializationFee(IPoolFactory.PoolKey calldata k) public view returns (UD60x18) {
        PoolFactoryStorage.Layout storage l = PoolFactoryStorage.layout();

        uint256 discountFactor = l.maturityCount[k.maturityKey()] + l.strikeCount[k.strikeKey()];
        UD60x18 discount = (ONE - l.discountPerPool).intoSD59x18().powu(discountFactor).intoUD60x18();

        UD60x18 spot = _getSpotPrice(k.oracleAdapter, k.base, k.quote);
        UD60x18 fee = OptionMath.initializationFee(spot, k.strike, k.maturity);

        return (fee * discount) / _getWrappedNativeUSDSpotPrice();
    }

    /// @notice We use the given oracle adapter to fetch the spot price of the base/quote pair.
    ///         This is used in the calculation of the initializationFee
    function _getSpotPrice(address oracleAdapter, address base, address quote) internal view returns (UD60x18) {
        return IOracleAdapter(oracleAdapter).getPrice(base, quote);
    }

    /// @notice We use the Premia Chainlink Adapter to fetch the spot price of the wrapped native token in USD.
    ///         This is used to convert the initializationFee from USD to native token
    function _getWrappedNativeUSDSpotPrice() internal view returns (UD60x18) {
        return IOracleAdapter(CHAINLINK_ADAPTER).getPrice(WRAPPED_NATIVE_TOKEN, Denominations.USD);
    }

    /// @notice Safely transfer native token to the given address
    function _safeTransferNativeToken(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        if (!success) revert PoolFactory__TransferNativeTokenFailed();
    }

    /// @notice Revert if the base and quote are identical or if the base, quote, or oracle adapter are zero
    function _revertIfAddressInvalid(PoolKey calldata k) internal pure {
        if (k.base == k.quote) revert PoolFactory__IdenticalAddresses();
        if (k.base == address(0) || k.quote == address(0) || k.oracleAdapter == address(0))
            revert PoolFactory__ZeroAddress();
    }

    /// @notice Revert if the strike price is not a multiple of the strike interval
    function _revertIfOptionStrikeInvalid(UD60x18 strike) internal pure {
        if (strike == ZERO) revert PoolFactory__OptionStrikeEqualsZero();
        UD60x18 strikeInterval = OptionMath.calculateStrikeInterval(strike);
        if (strike % strikeInterval != ZERO) revert PoolFactory__OptionStrikeInvalid(strike, strikeInterval);
    }

    /// @notice Revert if the maturity is invalid
    function _revertIfOptionMaturityInvalid(uint256 maturity) internal view {
        if (maturity <= block.timestamp) revert PoolFactory__OptionExpired(maturity);
        if (!OptionMath.is8AMUTC(maturity)) revert PoolFactory__OptionMaturityNot8UTC(maturity);

        uint256 ttm = OptionMath.calculateTimeToMaturity(maturity);

        if (ttm >= 3 days && ttm <= 30 days) {
            if (!OptionMath.isFriday(maturity)) revert PoolFactory__OptionMaturityNotFriday(maturity);
        }

        if (ttm > 30 days) {
            if (!OptionMath.isLastFriday(maturity)) revert PoolFactory__OptionMaturityNotLastFriday(maturity);
        }

        if (ttm > 365 days) revert PoolFactory__OptionMaturityExceedsMax(maturity);
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";

import {PoolProxy} from "../pool/PoolProxy.sol";
import {IPoolFactoryDeployer} from "./IPoolFactoryDeployer.sol";
import {IPoolFactory} from "./IPoolFactory.sol";

contract PoolFactoryDeployer is IPoolFactoryDeployer, ReentrancyGuard {
    address public immutable DIAMOND;
    address public immutable POOL_FACTORY;

    constructor(address diamond, address poolFactory) {
        DIAMOND = diamond;
        POOL_FACTORY = poolFactory;
    }

    /// @inheritdoc IPoolFactoryDeployer
    function deployPool(IPoolFactory.PoolKey calldata k) external nonReentrant returns (address poolAddress) {
        _revertIfNotPoolFactory(msg.sender);

        bytes32 salt = keccak256(_encodePoolProxyArgs(k));
        poolAddress = address(
            new PoolProxy{salt: salt}(DIAMOND, k.base, k.quote, k.oracleAdapter, k.strike, k.maturity, k.isCallPool)
        );
    }

    /// @inheritdoc IPoolFactoryDeployer
    function calculatePoolAddress(IPoolFactory.PoolKey calldata k) external view returns (address) {
        _revertIfNotPoolFactory(msg.sender);

        bytes memory args = _encodePoolProxyArgs(k);

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), // 255
                address(this), // address of factory contract
                keccak256(args), // salt
                // The contract bytecode
                keccak256(abi.encodePacked(type(PoolProxy).creationCode, args))
            )
        );

        // Cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    /// @notice Returns the encoded arguments for the pool proxy using pool key `k`
    function _encodePoolProxyArgs(IPoolFactory.PoolKey calldata k) internal view returns (bytes memory) {
        return abi.encode(DIAMOND, k.base, k.quote, k.oracleAdapter, k.strike, k.maturity, k.isCallPool);
    }

    function _revertIfNotPoolFactory(address caller) internal view {
        if (caller != POOL_FACTORY) revert PoolFactoryDeployer__NotPoolFactory(caller);
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {IPoolFactory} from "./IPoolFactory.sol";
import {IPoolFactoryEvents} from "./IPoolFactoryEvents.sol";

import {PoolFactoryStorage} from "./PoolFactoryStorage.sol";

import {ProxyUpgradeableOwnable} from "../proxy/ProxyUpgradeableOwnable.sol";
import {ZERO, ONE} from "../libraries/Constants.sol";

contract PoolFactoryProxy is IPoolFactoryEvents, ProxyUpgradeableOwnable {
    using PoolFactoryStorage for PoolFactoryStorage.Layout;

    constructor(
        address implementation,
        UD60x18 discountPerPool,
        address feeReceiver
    ) ProxyUpgradeableOwnable(implementation) {
        PoolFactoryStorage.Layout storage l = PoolFactoryStorage.layout();

        if (discountPerPool == ZERO || discountPerPool >= ONE) revert IPoolFactory.PoolFactory__InvalidInput();
        l.discountPerPool = discountPerPool;
        emit SetDiscountPerPool(discountPerPool);

        l.feeReceiver = feeReceiver;
        emit SetFeeReceiver(feeReceiver);
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {IPoolFactory} from "./IPoolFactory.sol";

library PoolFactoryStorage {
    using PoolFactoryStorage for PoolFactoryStorage.Layout;

    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.PoolFactory");

    struct Layout {
        mapping(bytes32 key => address pool) pools;
        mapping(address pool => bool) isPool;
        mapping(bytes32 key => uint256 count) strikeCount;
        mapping(bytes32 key => uint256 count) maturityCount;
        // Discount % per neighboring strike/maturity (18 decimals)
        UD60x18 discountPerPool;
        // Initialization fee receiver
        address feeReceiver;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice Returns the encoded pool key using the pool key `k`
    function poolKey(IPoolFactory.PoolKey memory k) internal pure returns (bytes32) {
        return keccak256(abi.encode(k.base, k.quote, k.oracleAdapter, k.strike, k.maturity, k.isCallPool));
    }

    /// @notice Returns the encoded strike key using the pool key `k`
    function strikeKey(IPoolFactory.PoolKey memory k) internal pure returns (bytes32) {
        return keccak256(abi.encode(k.base, k.quote, k.oracleAdapter, k.strike, k.isCallPool));
    }

    /// @notice Returns the encoded maturity key using the pool key `k`
    function maturityKey(IPoolFactory.PoolKey memory k) internal pure returns (bytes32) {
        return keccak256(abi.encode(k.base, k.quote, k.oracleAdapter, k.maturity, k.isCallPool));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ILayerZeroUserApplicationConfig} from "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    /// @notice Send a LayerZero message to the specified address at a LayerZero endpoint.
    /// @param dstChainId The destination chain identifier
    /// @param destination The address on destination chain (in bytes). address length/format may vary by chains
    /// @param payload A custom bytes payload to send to the destination contract
    /// @param refundAddress If the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    /// @param zroPaymentAddress The address of the ZRO token holder who would pay for the transaction
    /// @param adapterParams Parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 dstChainId,
        bytes calldata destination,
        bytes calldata payload,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) external payable;

    /// @notice Used by the messaging library to publish verified payload
    /// @param srcChainId The source chain identifier
    /// @param srcAddress The source contract (as bytes) at the source chain
    /// @param dstAddress The address on destination chain
    /// @param nonce The unbound message ordering nonce
    /// @param gasLimit The gas limit for external contract execution
    /// @param payload Verified payload to send to the destination contract
    function receivePayload(
        uint16 srcChainId,
        bytes calldata srcAddress,
        address dstAddress,
        uint64 nonce,
        uint256 gasLimit,
        bytes calldata payload
    ) external;

    /// @notice Get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    /// @param srcChainId The source chain identifier
    /// @param srcAddress The source chain contract address
    function getInboundNonce(uint16 srcChainId, bytes calldata srcAddress) external view returns (uint64);

    /// @notice Get the outboundNonce from this source chain which, consequently, is always an EVM
    /// @param srcAddress The source chain contract address
    function getOutboundNonce(uint16 dstChainId, address srcAddress) external view returns (uint64);

    /// @notice Gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    /// @param dstChainId The destination chain identifier
    /// @param userApplication The user app address on this EVM chain
    /// @param payload The custom message to send over LayerZero
    /// @param payInZRO If false, user app pays the protocol fee in native token
    /// @param adapterParam Parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 dstChainId,
        address userApplication,
        bytes calldata payload,
        bool payInZRO,
        bytes calldata adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    /// @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    /// @notice The interface to retry failed message on this Endpoint destination
    /// @param srcChainId The source chain identifier
    /// @param srcAddress The source chain contract address
    /// @param payload The payload to be retried
    function retryPayload(uint16 srcChainId, bytes calldata srcAddress, bytes calldata payload) external;

    /// @notice Query if any STORED payload (message blocking) at the endpoint.
    /// @param srcChainId The source chain identifier
    /// @param srcAddress The source chain contract address
    function hasStoredPayload(uint16 srcChainId, bytes calldata srcAddress) external view returns (bool);

    /// @notice Query if the libraryAddress is valid for sending msgs.
    /// @param userApplication The user app address on this EVM chain
    function getSendLibraryAddress(address userApplication) external view returns (address);

    /// @notice Query if the libraryAddress is valid for receiving msgs.
    /// @param userApplication The user app address on this EVM chain
    function getReceiveLibraryAddress(address userApplication) external view returns (address);

    /// @notice Query if the non-reentrancy guard for send() is on
    /// @return True if the guard is on. False otherwise
    function isSendingPayload() external view returns (bool);

    /// @notice Query if the non-reentrancy guard for receive() is on
    /// @return True if the guard is on. False otherwise
    function isReceivingPayload() external view returns (bool);

    /// @notice Get the configuration of the LayerZero messaging library of the specified version
    /// @param version Messaging library version
    /// @param chainId The chainId for the pending config change
    /// @param userApplication The contract address of the user application
    /// @param configType Type of configuration. every messaging library has its own convention.
    function getConfig(
        uint16 version,
        uint16 chainId,
        address userApplication,
        uint256 configType
    ) external view returns (bytes memory);

    /// @notice Get the send() LayerZero messaging library version
    /// @param userApplication The contract address of the user application
    function getSendVersion(address userApplication) external view returns (uint16);

    /// @notice Get the lzReceive() LayerZero messaging library version
    /// @param userApplication The contract address of the user application
    function getReceiveVersion(address userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ILayerZeroReceiver {
    /// @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    /// @param srcChainId The source endpoint identifier
    /// @param srcAddress The source sending contract address from the source chain
    /// @param nonce The ordered message nonce
    /// @param payload The signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 srcChainId, bytes calldata srcAddress, uint64 nonce, bytes calldata payload) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ILayerZeroUserApplicationConfig {
    /// @notice Set the configuration of the LayerZero messaging library of the specified version
    /// @param version Messaging library version
    /// @param chainId The chainId for the pending config change
    /// @param configType Type of configuration. every messaging library has its own convention.
    /// @param config Configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 version, uint16 chainId, uint256 configType, bytes calldata config) external;

    /// @notice Set the send() LayerZero messaging library version to version
    /// @param version New messaging library version
    function setSendVersion(uint16 version) external;

    /// @notice Set the lzReceive() LayerZero messaging library version to version
    /// @param version NMew messaging library version
    function setReceiveVersion(uint16 version) external;

    /// @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    /// @param srcChainId The chainId of the source chain
    /// @param srcAddress The contract address of the source contract at the source chain
    function forceResumeReceive(uint16 srcChainId, bytes calldata srcAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";

import {ILayerZeroReceiver} from "../interfaces/ILayerZeroReceiver.sol";
import {ILayerZeroUserApplicationConfig} from "../interfaces/ILayerZeroUserApplicationConfig.sol";
import {ILayerZeroEndpoint} from "../interfaces/ILayerZeroEndpoint.sol";
import {LzAppStorage} from "./LzAppStorage.sol";
import {BytesLib} from "../util/BytesLib.sol";

// A generic LzReceiver implementation
abstract contract LzApp is OwnableInternal, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    using BytesLib for bytes;

    ILayerZeroEndpoint public immutable lzEndpoint;

    //    event SetPrecrime(address precrime);
    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);

    error LzApp__InvalidEndpointCaller();
    error LzApp__InvalidSource();
    error LzApp__NotTrustedSource();
    error LzApp__NoTrustedPathRecord();

    constructor(address endpoint) {
        lzEndpoint = ILayerZeroEndpoint(endpoint);
    }

    /// @inheritdoc ILayerZeroReceiver
    function lzReceive(uint16 srcChainId, bytes memory srcAddress, uint64 nonce, bytes memory payload) public virtual {
        // lzReceive must be called by the endpoint for security
        if (msg.sender != address(lzEndpoint)) revert LzApp__InvalidEndpointCaller();

        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        if (!_isTrustedRemote(srcChainId, srcAddress)) revert LzApp__InvalidSource();

        _blockingLzReceive(srcChainId, srcAddress, nonce, payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) internal virtual;

    function _lzSend(
        uint16 dstChainId,
        bytes memory payload,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes memory adapterParams,
        uint256 nativeFee
    ) internal virtual {
        bytes memory trustedRemote = LzAppStorage.layout().trustedRemote[dstChainId];
        if (trustedRemote.length == 0) revert LzApp__NotTrustedSource();
        lzEndpoint.send{value: nativeFee}(
            dstChainId,
            trustedRemote,
            payload,
            refundAddress,
            zroPaymentAddress,
            adapterParams
        );
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(
        uint16 version,
        uint16 chainId,
        address,
        uint256 configType
    ) external view returns (bytes memory) {
        return lzEndpoint.getConfig(version, chainId, address(this), configType);
    }

    /// @inheritdoc ILayerZeroUserApplicationConfig
    function setConfig(uint16 version, uint16 chainId, uint256 configType, bytes calldata config) external onlyOwner {
        lzEndpoint.setConfig(version, chainId, configType, config);
    }

    /// @inheritdoc ILayerZeroUserApplicationConfig
    function setSendVersion(uint16 version) external onlyOwner {
        lzEndpoint.setSendVersion(version);
    }

    /// @inheritdoc ILayerZeroUserApplicationConfig
    function setReceiveVersion(uint16 version) external onlyOwner {
        lzEndpoint.setReceiveVersion(version);
    }

    /// @inheritdoc ILayerZeroUserApplicationConfig
    function forceResumeReceive(uint16 srcChainId, bytes calldata srcAddress) external onlyOwner {
        lzEndpoint.forceResumeReceive(srcChainId, srcAddress);
    }

    function setTrustedRemoteAddress(uint16 remoteChainId, bytes calldata remoteAddress) external onlyOwner {
        LzAppStorage.layout().trustedRemote[remoteChainId] = abi.encodePacked(remoteAddress, address(this));
        emit SetTrustedRemoteAddress(remoteChainId, remoteAddress);
    }

    function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory) {
        bytes memory path = LzAppStorage.layout().trustedRemote[_remoteChainId];
        if (path.length == 0) revert LzApp__NoTrustedPathRecord();
        return path.slice(0, path.length - 20); // the last 20 bytes should be address(this)
    }

    //    function setPrecrime(address _precrime) external onlyOwner {
    //        LzAppStorage.layout().precrime = _precrime;
    //        emit SetPrecrime(_precrime);
    //    }

    //--------------------------- VIEW FUNCTION ----------------------------------------

    function isTrustedRemote(uint16 srcChainId, bytes memory srcAddress) external view returns (bool) {
        return _isTrustedRemote(srcChainId, srcAddress);
    }

    function _isTrustedRemote(uint16 srcChainId, bytes memory srcAddress) internal view returns (bool) {
        bytes memory trustedRemote = LzAppStorage.layout().trustedRemote[srcChainId];

        return
            srcAddress.length == trustedRemote.length &&
            trustedRemote.length > 0 &&
            keccak256(trustedRemote) == keccak256(srcAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LzAppStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.LzApp");

    struct Layout {
        mapping(uint16 => bytes) trustedRemote;
        address precrime;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {LzApp} from "./LzApp.sol";
import {NonblockingLzAppStorage} from "./NonblockingLzAppStorage.sol";
import {ExcessivelySafeCall} from "../util/ExcessivelySafeCall.sol";

// the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
// this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
// NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
abstract contract NonblockingLzApp is LzApp {
    using ExcessivelySafeCall for address;

    error NonblockingLzApp__CallerNotLzApp();
    error NonblockingLzApp__InvalidPayload();
    error NonblockingLzApp__NoStoredMessage();

    constructor(address endpoint) LzApp(endpoint) {}

    event MessageFailed(uint16 srcChainId, bytes srcAddress, uint64 nonce, bytes payload, bytes reason);
    event RetryMessageSuccess(uint16 srcChainId, bytes srcAddress, uint64 nonce, bytes32 payloadHash);

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) internal virtual override {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(
            gasleft(),
            150,
            abi.encodeWithSelector(this.nonblockingLzReceive.selector, srcChainId, srcAddress, nonce, payload)
        );
        // try-catch all errors/exceptions
        if (!success) {
            NonblockingLzAppStorage.layout().failedMessages[srcChainId][srcAddress][nonce] = keccak256(payload);
            emit MessageFailed(srcChainId, srcAddress, nonce, payload, reason);
        }
    }

    function nonblockingLzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) public virtual {
        // only internal transaction
        if (msg.sender != address(this)) revert NonblockingLzApp__CallerNotLzApp();
        _nonblockingLzReceive(srcChainId, srcAddress, nonce, payload);
    }

    // override this function
    function _nonblockingLzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) internal virtual;

    function retryMessage(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) public payable virtual {
        NonblockingLzAppStorage.Layout storage l = NonblockingLzAppStorage.layout();

        // assert there is message to retry
        bytes32 payloadHash = l.failedMessages[srcChainId][srcAddress][nonce];

        if (payloadHash == bytes32(0)) revert NonblockingLzApp__NoStoredMessage();

        if (keccak256(payload) != payloadHash) revert NonblockingLzApp__InvalidPayload();

        // clear the stored message
        delete l.failedMessages[srcChainId][srcAddress][nonce];
        // execute the message. revert if it fails again
        _nonblockingLzReceive(srcChainId, srcAddress, nonce, payload);
        emit RetryMessageSuccess(srcChainId, srcAddress, nonce, payloadHash);
    }

    function failedMessages(uint16 srcChainId, bytes memory srcAddress, uint64 nonce) external view returns (bytes32) {
        return NonblockingLzAppStorage.layout().failedMessages[srcChainId][srcAddress][nonce];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library NonblockingLzAppStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.NonblockingLzApp");

    struct Layout {
        mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) failedMessages;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IOFTCore} from "./IOFTCore.sol";
import {ISolidStateERC20} from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";

/// @dev Interface of the OFT standard
interface IOFT is IOFTCore, ISolidStateERC20 {
    error OFT_InsufficientAllowance();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";

/// @dev Interface of the IOFT core standard
interface IOFTCore is IERC165 {
    /// @dev Estimate send token `tokenId` to (`dstChainId`, `toAddress`)
    /// @param dstChainId L0 defined chain id to send tokens too
    /// @param toAddress Dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
    /// @param amount Amount of the tokens to transfer
    /// @param useZro Indicates to use zro to pay L0 fees
    /// @param adapterParams Flexible bytes array to indicate messaging adapter services in L0
    function estimateSendFee(
        uint16 dstChainId,
        bytes calldata toAddress,
        uint256 amount,
        bool useZro,
        bytes calldata adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    /// @dev Send `amount` amount of token to (`dstChainId`, `toAddress`) from `from`
    /// @param from The owner of token
    /// @param dstChainId The destination chain identifier
    /// @param toAddress Can be any size depending on the `dstChainId`.
    /// @param amount The quantity of tokens in wei
    /// @param refundAddress The address LayerZero refunds if too much message fee is sent
    /// @param zroPaymentAddress Set to address(0x0) if not paying in ZRO (LayerZero Token)
    /// @param adapterParams Flexible bytes array to indicate messaging adapter services
    function sendFrom(
        address from,
        uint16 dstChainId,
        bytes calldata toAddress,
        uint256 amount,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) external payable;

    /// @dev Returns the circulating amount of tokens on current chain
    function circulatingSupply() external view returns (uint256);

    /// @dev Emitted when `amount` tokens are moved from the `sender` to (`dstChainId`, `toAddress`)
    event SendToChain(address indexed sender, uint16 indexed dstChainId, bytes indexed toAddress, uint256 amount);

    /// @dev Emitted when `amount` tokens are received from `srcChainId` into the `toAddress` on the local chain.
    event ReceiveFromChain(
        uint16 indexed srcChainId,
        bytes indexed srcAddress,
        address indexed toAddress,
        uint256 amount
    );

    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {ERC20Base, ERC20BaseStorage} from "@solidstate/contracts/token/ERC20/base/ERC20Base.sol";
import {SolidStateERC20} from "@solidstate/contracts/token/ERC20/SolidStateERC20.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";

import {OFTCore} from "./OFTCore.sol";
import {IOFT} from "./IOFT.sol";

// override decimal() function is needed
contract OFT is OFTCore, SolidStateERC20, IOFT {
    constructor(address lzEndpoint) OFTCore(lzEndpoint) {}

    function circulatingSupply() public view virtual override returns (uint256) {
        return _totalSupply();
    }

    function _debitFrom(address from, uint16, bytes memory, uint256 amount) internal virtual override {
        address spender = msg.sender;

        if (from != spender) {
            unchecked {
                mapping(address => uint256) storage allowances = ERC20BaseStorage.layout().allowances[from];

                uint256 allowance = allowances[spender];
                if (amount > allowance) revert OFT_InsufficientAllowance();

                _approve(from, spender, allowances[spender] = allowance - amount);
            }
        }

        _burn(from, amount);
    }

    function _creditTo(uint16, address toAddress, uint256 amount) internal virtual override {
        _mint(toAddress, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {NonblockingLzApp} from "../../lzApp/NonblockingLzApp.sol";
import {IOFTCore} from "./IOFTCore.sol";
import {ERC165Base, IERC165} from "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import {BytesLib} from "../../util/BytesLib.sol";

abstract contract OFTCore is NonblockingLzApp, ERC165Base, IOFTCore {
    using BytesLib for bytes;

    // packet type
    uint16 public constant PT_SEND = 0;

    constructor(address lzEndpoint) NonblockingLzApp(lzEndpoint) {}

    function estimateSendFee(
        uint16 dstChainId,
        bytes memory toAddress,
        uint256 amount,
        bool useZro,
        bytes memory adapterParams
    ) public view virtual override returns (uint256 nativeFee, uint256 zroFee) {
        // mock the payload for send()
        bytes memory payload = abi.encode(PT_SEND, abi.encodePacked(msg.sender), toAddress, amount);
        return lzEndpoint.estimateFees(dstChainId, address(this), payload, useZro, adapterParams);
    }

    function sendFrom(
        address from,
        uint16 dstChainId,
        bytes memory toAddress,
        uint256 amount,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes memory adapterParams
    ) public payable virtual override {
        _send(from, dstChainId, toAddress, amount, refundAddress, zroPaymentAddress, adapterParams);
    }

    function _nonblockingLzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) internal virtual override {
        uint16 packetType;
        assembly {
            packetType := mload(add(payload, 32))
        }

        if (packetType == PT_SEND) {
            _sendAck(srcChainId, srcAddress, nonce, payload);
        } else {
            revert("OFTCore: unknown packet type");
        }
    }

    function _send(
        address from,
        uint16 dstChainId,
        bytes memory toAddress,
        uint256 amount,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes memory adapterParams
    ) internal virtual {
        _debitFrom(from, dstChainId, toAddress, amount);

        bytes memory payload = abi.encode(PT_SEND, abi.encodePacked(from), toAddress, amount);

        _lzSend(dstChainId, payload, refundAddress, zroPaymentAddress, adapterParams, msg.value);

        emit SendToChain(from, dstChainId, toAddress, amount);
    }

    function _sendAck(uint16 srcChainId, bytes memory, uint64, bytes memory payload) internal virtual {
        (, bytes memory from, bytes memory toAddressBytes, uint256 amount) = abi.decode(
            payload,
            (uint16, bytes, bytes, uint256)
        );

        address to = toAddressBytes.toAddress(0);

        _creditTo(srcChainId, to, amount);
        emit ReceiveFromChain(srcChainId, from, to, amount);
    }

    function _debitFrom(address from, uint16 dstChainId, bytes memory toAddress, uint256 amount) internal virtual;

    function _creditTo(uint16 srcChainId, address toAddress, uint256 amount) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library OFTCoreStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.OFTCore");

    struct Layout {
        bool useCustomAdapterParams;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {ERC165BaseInternal} from "@solidstate/contracts/introspection/ERC165/base/ERC165BaseInternal.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";

import {ProxyUpgradeableOwnable} from "../../../proxy/ProxyUpgradeableOwnable.sol";
import {IOFT} from "./IOFT.sol";
import {IOFTCore} from "./IOFTCore.sol";

contract OFTProxy is ProxyUpgradeableOwnable, ERC165BaseInternal {
    constructor(address implementation) ProxyUpgradeableOwnable(implementation) {
        {
            _setSupportsInterface(type(IERC165).interfaceId, true);
            _setSupportsInterface(type(IERC20).interfaceId, true);
            _setSupportsInterface(type(IOFTCore).interfaceId, true);
            _setSupportsInterface(type(IOFT).interfaceId, true);
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

/// @title Solidity Bytes Arrays Utils
/// @author Gonçalo Sá <[email protected]>
/// @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
///      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
library BytesLib {
    error BytesLib__Overflow();
    error BytesLib__OutOfBounds();

    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        if (_length + 31 < _length) revert BytesLib__Overflow();
        if (_bytes.length < _start + _length) revert BytesLib__OutOfBounds();

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        if (_bytes.length < _start + 20) revert BytesLib__OutOfBounds();
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        if (_bytes.length < _start + 1) revert BytesLib__OutOfBounds();
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        if (_bytes.length < _start + 2) revert BytesLib__OutOfBounds();
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        if (_bytes.length < _start + 4) revert BytesLib__OutOfBounds();
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        if (_bytes.length < _start + 8) revert BytesLib__OutOfBounds();
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        if (_bytes.length < _start + 12) revert BytesLib__OutOfBounds();
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        if (_bytes.length < _start + 16) revert BytesLib__OutOfBounds();
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        if (_bytes.length < _start + 32) revert BytesLib__OutOfBounds();
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        if (_bytes.length < _start + 32) revert BytesLib__OutOfBounds();
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                0, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
                _gas, // gas
                _target, // recipient
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Swaps function selectors in encoded contract calls
    /// @dev Allows reuse of encoded calldata for functions with identical
    /// argument types but different names. It simply swaps out the first 4 bytes
    /// for the new selector. This function modifies memory in place, and should
    /// only be used with caution.
    /// @param _newSelector The new 4-byte selector
    /// @param _buf The encoded contract args
    function swapSelector(bytes4 _newSelector, bytes memory _buf) internal pure {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

library ArrayUtils {
    /// @notice Thrown when attempting to increase array size
    error ArrayUtils__ArrayCannotExpand(uint256 arrayLength, uint256 size);

    /// @notice Resizes the `array` to `size`, reverts if size > array.length
    /// @dev It is not safe to increase array size this way
    function resizeArray(uint8[] memory array, uint256 size) internal pure {
        revertIfTryingToExpand(array.length, size);

        assembly {
            mstore(array, size)
        }
    }

    /// @notice Resizes the `array` to `size`, reverts if size > array.length
    /// @dev It is not safe to increase array size this way
    function resizeArray(uint256[] memory array, uint256 size) internal pure {
        revertIfTryingToExpand(array.length, size);

        assembly {
            mstore(array, size)
        }
    }

    /// @notice Resizes the `array` to `size`, reverts if size > array.length
    /// @dev It is not safe to increase array size this way
    function resizeArray(address[] memory array, uint256 size) internal pure {
        revertIfTryingToExpand(array.length, size);

        assembly {
            mstore(array, size)
        }
    }

    /// @notice Reverts if trying to expand array size, as increasing array size through inline assembly is not safe
    function revertIfTryingToExpand(uint256 currentLength, uint256 targetSize) internal pure {
        if (currentLength == targetSize) return;
        if (currentLength < targetSize) revert ArrayUtils__ArrayCannotExpand(currentLength, targetSize);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {SD59x18} from "lib/prb-math/src/SD59x18.sol";
import {UD50x28} from "./UD50x28.sol";
import {SD49x28} from "./SD49x28.sol";

UD60x18 constant ZERO = UD60x18.wrap(0);
UD60x18 constant ONE_HALF = UD60x18.wrap(0.5e18);
UD60x18 constant ONE = UD60x18.wrap(1e18);
UD60x18 constant TWO = UD60x18.wrap(2e18);
UD60x18 constant THREE = UD60x18.wrap(3e18);
UD60x18 constant FIVE = UD60x18.wrap(5e18);

SD59x18 constant iZERO = SD59x18.wrap(0);
SD59x18 constant iONE = SD59x18.wrap(1e18);
SD59x18 constant iTWO = SD59x18.wrap(2e18);
SD59x18 constant iFOUR = SD59x18.wrap(4e18);
SD59x18 constant iNINE = SD59x18.wrap(9e18);

UD50x28 constant UD50_ZERO = UD50x28.wrap(0);
UD50x28 constant UD50_ONE = UD50x28.wrap(1e28);
UD50x28 constant UD50_TWO = UD50x28.wrap(2e28);

SD49x28 constant SD49_ZERO = SD49x28.wrap(0);
SD49x28 constant SD49_ONE = SD49x28.wrap(1e28);
SD49x28 constant SD49_TWO = SD49x28.wrap(2e28);

uint256 constant WAD = 1e18;

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";

import {DoublyLinkedList} from "@solidstate/contracts/data/DoublyLinkedList.sol";

library DoublyLinkedListUD60x18 {
    using DoublyLinkedList for DoublyLinkedList.Bytes32List;

    /// @notice Returns true if the doubly linked list `self` contains the `value`
    function contains(DoublyLinkedList.Bytes32List storage self, UD60x18 value) internal view returns (bool) {
        return self.contains(bytes32(value.unwrap()));
    }

    /// @notice Returns the stored element before `value` in the doubly linked list `self`
    function prev(DoublyLinkedList.Bytes32List storage self, UD60x18 value) internal view returns (UD60x18) {
        return ud(uint256(self.prev(bytes32(value.unwrap()))));
    }

    /// @notice Returns the stored element after `value` in the doubly linked list `self`
    function next(DoublyLinkedList.Bytes32List storage self, UD60x18 value) internal view returns (UD60x18) {
        return ud(uint256(self.next(bytes32(value.unwrap()))));
    }

    /// @notice Returns true if `newValue` was successfully inserted before `nextValue` in the doubly linked list `self`
    function insertBefore(
        DoublyLinkedList.Bytes32List storage self,
        UD60x18 nextValue,
        UD60x18 newValue
    ) internal returns (bool status) {
        status = self.insertBefore(bytes32(nextValue.unwrap()), bytes32(newValue.unwrap()));
    }

    /// @notice Returns true if `newValue` was successfully inserted after `prevValue` in the doubly linked list `self`
    function insertAfter(
        DoublyLinkedList.Bytes32List storage self,
        UD60x18 prevValue,
        UD60x18 newValue
    ) internal returns (bool status) {
        status = self.insertAfter(bytes32(prevValue.unwrap()), bytes32(newValue.unwrap()));
    }

    /// @notice Returns true if `value` was successfully inserted at the end of the doubly linked list `self`
    function push(DoublyLinkedList.Bytes32List storage self, UD60x18 value) internal returns (bool status) {
        status = self.push(bytes32(value.unwrap()));
    }

    /// @notice Removes the first element in the doubly linked list `self`, returns the removed element `value`
    function pop(DoublyLinkedList.Bytes32List storage self) internal returns (UD60x18 value) {
        value = ud(uint256(self.pop()));
    }

    /// @notice Removes the last element in the doubly linked list `self`, returns the removed element `value`
    function shift(DoublyLinkedList.Bytes32List storage self) internal returns (UD60x18 value) {
        value = ud(uint256(self.shift()));
    }

    /// @notice Returns true if `value` was successfully inserted at the front of the doubly linked list `self`
    function unshift(DoublyLinkedList.Bytes32List storage self, UD60x18 value) internal returns (bool status) {
        status = self.unshift(bytes32(value.unwrap()));
    }

    /// @notice Returns true if `value` was successfully removed from the doubly linked list `self`
    function remove(DoublyLinkedList.Bytes32List storage self, UD60x18 value) internal returns (bool status) {
        status = self.remove(bytes32(value.unwrap()));
    }

    /// @notice Returns true if `oldValue` was successfully replaced with `newValue` in the doubly linked list `self`
    function replace(
        DoublyLinkedList.Bytes32List storage self,
        UD60x18 oldValue,
        UD60x18 newValue
    ) internal returns (bool status) {
        status = self.replace(bytes32(oldValue.unwrap()), bytes32(newValue.unwrap()));
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

library EnumerableSetUD60x18 {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Returns the element at a given index `i` in the enumerable set `self`
    function at(EnumerableSet.Bytes32Set storage self, uint256 i) internal view returns (UD60x18) {
        return UD60x18.wrap(uint256(self.at(i)));
    }

    /// @notice Returns true if the enumerable set `self` contains `value`
    function contains(EnumerableSet.Bytes32Set storage self, UD60x18 value) internal view returns (bool) {
        return self.contains(bytes32(value.unwrap()));
    }

    /// @notice Returns the index of `value` in the enumerable set `self`
    function indexOf(EnumerableSet.Bytes32Set storage self, UD60x18 value) internal view returns (uint256) {
        return self.indexOf(bytes32(value.unwrap()));
    }

    /// @notice Returns the number of elements in the enumerable set `self`
    function length(EnumerableSet.Bytes32Set storage self) internal view returns (uint256) {
        return self.length();
    }

    /// @notice Returns true if `value` is added to the enumerable set `self`
    function add(EnumerableSet.Bytes32Set storage self, UD60x18 value) internal returns (bool) {
        return self.add(bytes32(value.unwrap()));
    }

    /// @notice Returns true if `value` is removed from the enumerable set `self`
    function remove(EnumerableSet.Bytes32Set storage self, UD60x18 value) internal returns (bool) {
        return self.remove(bytes32(value.unwrap()));
    }

    /// @notice Returns an array of all elements in the enumerable set `self`
    function toArray(EnumerableSet.Bytes32Set storage self) internal view returns (UD60x18[] memory) {
        bytes32[] memory src = self.toArray();
        UD60x18[] memory tgt = new UD60x18[](src.length);
        for (uint256 i = 0; i < src.length; i++) {
            tgt[i] = UD60x18.wrap(uint256(src[i]));
        }
        return tgt;
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {SD59x18} from "lib/prb-math/src/SD59x18.sol";
import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

interface IPosition {
    error Position__InvalidOrderType();
    error Position__InvalidPositionUpdate(UD60x18 currentBalance, SD59x18 amount);
    error Position__LowerGreaterOrEqualUpper(UD60x18 lower, UD60x18 upper);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

interface IPricing {
    error Pricing__PriceCannotBeComputedWithinTickRange();
    error Pricing__PriceOutOfRange(UD60x18 lower, UD60x18 upper, UD60x18 marketPrice);
    error Pricing__UpperNotGreaterThanLower(UD60x18 lower, UD60x18 upper);
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {BokkyPooBahsDateTimeLibrary as DateTime} from "lib/BokkyPooBahsDateTimeLibrary/contracts/BokkyPooBahsDateTimeLibrary.sol";
import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";
import {SD59x18} from "lib/prb-math/src/SD59x18.sol";

import {ZERO, ONE, TWO, iZERO, iONE, iTWO, iFOUR, iNINE} from "./Constants.sol";

library OptionMath {
    struct BlackScholesPriceVarsInternal {
        int256 discountFactor;
        int256 timeScaledVol;
        int256 timeScaledVar;
        int256 timeScaledRiskFreeRate;
    }

    UD60x18 internal constant INITIALIZATION_ALPHA = UD60x18.wrap(5e18);
    UD60x18 internal constant ATM_MONEYNESS = UD60x18.wrap(0.5e18);
    uint256 internal constant NEAR_TERM_TTM = 14 days;
    uint256 internal constant ONE_YEAR_TTM = 365 days;
    UD60x18 internal constant FEE_SCALAR = UD60x18.wrap(100e18);

    SD59x18 internal constant ALPHA = SD59x18.wrap(-6.37309208e18);
    SD59x18 internal constant LAMBDA = SD59x18.wrap(-0.61228883e18);
    SD59x18 internal constant S1 = SD59x18.wrap(-0.11105481e18);
    SD59x18 internal constant S2 = SD59x18.wrap(0.44334159e18);
    int256 internal constant SQRT_2PI = 2_506628274631000502;

    UD60x18 internal constant MIN_INPUT_PRICE = UD60x18.wrap(1e1);
    UD60x18 internal constant MAX_INPUT_PRICE = UD60x18.wrap(1e34);

    error OptionMath__NonPositiveVol();
    error OptionMath__OutOfBoundsPrice(UD60x18 min, UD60x18 max, UD60x18 price);
    error OptionMath__Underflow();

    /// @notice Helper function to evaluate used to compute the normal CDF approximation
    /// @param x The input to the normal CDF (18 decimals)
    /// @return result The value of the evaluated helper function (18 decimals)
    function helperNormal(SD59x18 x) internal pure returns (SD59x18 result) {
        SD59x18 a = (ALPHA / LAMBDA) * S1;
        SD59x18 b = (S1 * x + iONE).pow(LAMBDA / S1) - iONE;
        result = ((a * b + S2 * x).exp() * (-iTWO.ln())).exp();
    }

    /// @notice Approximation of the normal CDF
    /// @dev The approximation implemented is based on the paper 'Accurate RMM-Based Approximations for the CDF of the
    ///      Normal Distribution' by Haim Shore
    /// @param x input value to evaluate the normal CDF on, F(Z<=x) (18 decimals)
    /// @return result The normal CDF evaluated at x (18 decimals)
    function normalCdf(SD59x18 x) internal pure returns (SD59x18 result) {
        if (x <= -iNINE) {
            result = iZERO;
        } else if (x >= iNINE) {
            result = iONE;
        } else {
            result = ((iONE + helperNormal(-x)) - helperNormal(x)) / iTWO;
        }
    }

    /// @notice Normal Distribution Probability Density Function.
    /// @dev Equal to `Z(x) = (1 / σ√2π)e^( (-(x - µ)^2) / 2σ^2 )`. Only computes pdf of a distribution with `µ = 0` and
    ///      `σ = 1`.
    /// @custom:error Maximum error of 1.2e-7.
    /// @custom:source https://mathworld.wolfram.com/ProbabilityDensityFunction.html.
    /// @param x Number to get PDF for (18 decimals)
    /// @return z z-number (18 decimals)
    function normalPdf(SD59x18 x) internal pure returns (SD59x18 z) {
        SD59x18 e;
        int256 one = iONE.unwrap();
        uint256 two = TWO.unwrap();

        assembly {
            e := sdiv(mul(add(not(x), 1), x), two) // (-x * x) / 2.
        }
        e = e.exp();
        assembly {
            z := sdiv(mul(e, one), SQRT_2PI)
        }
    }

    /// @notice Implementation of the ReLu function `f(x)=(x)^+` to compute call / put payoffs
    /// @param x Input value (18 decimals)
    /// @return result Output of the relu function (18 decimals)
    function relu(SD59x18 x) internal pure returns (UD60x18) {
        if (x >= iZERO) {
            return x.intoUD60x18();
        }
        return ZERO;
    }

    /// @notice Returns the terms `d1` and `d2` from the Black-Scholes formula that are used to compute the price of a
    ///         call / put option.
    /// @param spot The spot price. (18 decimals)
    /// @param strike The strike price of the option. (18 decimals)
    /// @param timeToMaturity The time until the option expires. (18 decimals)
    /// @param volAnnualized The percentage volatility of the geometric Brownian motion. (18 decimals)
    /// @param riskFreeRate The rate of the risk-less asset, i.e. the risk-free interest rate. (18 decimals)
    /// @return d1 The term d1 from the Black-Scholes formula. (18 decimals)
    /// @return d2 The term d2 from the Black-Scholes formula. (18 decimals)
    function d1d2(
        UD60x18 spot,
        UD60x18 strike,
        UD60x18 timeToMaturity,
        UD60x18 volAnnualized,
        UD60x18 riskFreeRate
    ) internal pure returns (SD59x18 d1, SD59x18 d2) {
        UD60x18 timeScaledRiskFreeRate = riskFreeRate * timeToMaturity;
        UD60x18 timeScaledVariance = (volAnnualized.powu(2) / TWO) * timeToMaturity;
        UD60x18 timeScaledStd = volAnnualized * timeToMaturity.sqrt();
        SD59x18 lnSpot = (spot / strike).intoSD59x18().ln();

        d1 =
            (lnSpot + timeScaledVariance.intoSD59x18() + timeScaledRiskFreeRate.intoSD59x18()) /
            timeScaledStd.intoSD59x18();

        d2 = d1 - timeScaledStd.intoSD59x18();
    }

    /// @notice Calculate option delta
    /// @param spot Spot price
    /// @param strike Strike price
    /// @param timeToMaturity Duration of option contract (in years)
    /// @param volAnnualized Annualized volatility
    /// @param isCall whether to price "call" or "put" option
    /// @return price Option delta
    function optionDelta(
        UD60x18 spot,
        UD60x18 strike,
        UD60x18 timeToMaturity,
        UD60x18 volAnnualized,
        UD60x18 riskFreeRate,
        bool isCall
    ) internal pure returns (SD59x18) {
        (SD59x18 d1, ) = d1d2(spot, strike, timeToMaturity, volAnnualized, riskFreeRate);

        if (isCall) {
            return normalCdf(d1);
        } else {
            return -normalCdf(-d1);
        }
    }

    /// @notice Calculate the price of an option using the Black-Scholes model
    /// @dev this implementation assumes zero interest
    /// @param spot Spot price (18 decimals)
    /// @param strike Strike price (18 decimals)
    /// @param timeToMaturity Duration of option contract (in years) (18 decimals)
    /// @param volAnnualized Annualized volatility (18 decimals)
    /// @param riskFreeRate The risk-free rate (18 decimals)
    /// @param isCall whether to price "call" or "put" option
    /// @return price The Black-Scholes option price (18 decimals)
    function blackScholesPrice(
        UD60x18 spot,
        UD60x18 strike,
        UD60x18 timeToMaturity,
        UD60x18 volAnnualized,
        UD60x18 riskFreeRate,
        bool isCall
    ) internal pure returns (UD60x18) {
        SD59x18 _spot = spot.intoSD59x18();
        SD59x18 _strike = strike.intoSD59x18();
        if (volAnnualized == ZERO) revert OptionMath__NonPositiveVol();

        if (timeToMaturity == ZERO) {
            if (isCall) {
                return relu(_spot - _strike);
            }
            return relu(_strike - _spot);
        }

        SD59x18 discountFactor;
        if (riskFreeRate > ZERO) {
            discountFactor = (riskFreeRate * timeToMaturity).intoSD59x18().exp();
        } else {
            discountFactor = iONE;
        }

        (SD59x18 d1, SD59x18 d2) = d1d2(spot, strike, timeToMaturity, volAnnualized, riskFreeRate);
        SD59x18 sign = isCall ? iONE : -iONE;
        SD59x18 a = (_spot / _strike) * normalCdf(d1 * sign);
        SD59x18 b = normalCdf(d2 * sign) / discountFactor;
        SD59x18 scaledPrice = (a - b) * sign;

        if (scaledPrice < SD59x18.wrap(-1e12)) revert OptionMath__Underflow();
        if (scaledPrice >= SD59x18.wrap(-1e12) && scaledPrice <= iZERO) scaledPrice = iZERO;

        return (scaledPrice * _strike).intoUD60x18();
    }

    /// @notice Returns true if the maturity time is 8AM UTC
    /// @param maturity The maturity timestamp of the option
    /// @return True if the maturity time is 8AM UTC, false otherwise
    function is8AMUTC(uint256 maturity) internal pure returns (bool) {
        return maturity % 24 hours == 8 hours;
    }

    /// @notice Returns true if the maturity day is Friday
    /// @param maturity The maturity timestamp of the option
    /// @return True if the maturity day is Friday, false otherwise
    function isFriday(uint256 maturity) internal pure returns (bool) {
        return DateTime.getDayOfWeek(maturity) == DateTime.DOW_FRI;
    }

    /// @notice Returns true if the maturity day is the last Friday of the month
    /// @param maturity The maturity timestamp of the option
    /// @return True if the maturity day is the last Friday of the month, false otherwise
    function isLastFriday(uint256 maturity) internal pure returns (bool) {
        uint256 dayOfMonth = DateTime.getDay(maturity);
        uint256 lastDayOfMonth = DateTime.getDaysInMonth(maturity);
        if (lastDayOfMonth - dayOfMonth >= 7) return false;
        return isFriday(maturity);
    }

    /// @notice Calculates the time to maturity in seconds
    /// @param maturity The maturity timestamp of the option
    /// @return Time to maturity in seconds
    function calculateTimeToMaturity(uint256 maturity) internal view returns (uint256) {
        return maturity - block.timestamp;
    }

    /// @notice Calculates the strike interval for `strike`
    /// @param strike The price to calculate strike interval for (18 decimals)
    /// @return The strike interval (18 decimals)
    function calculateStrikeInterval(UD60x18 strike) internal pure returns (UD60x18) {
        if (strike < MIN_INPUT_PRICE || strike > MAX_INPUT_PRICE)
            revert OptionMath__OutOfBoundsPrice(MIN_INPUT_PRICE, MAX_INPUT_PRICE, strike);

        uint256 _strike = strike.unwrap();
        uint256 exponent = log10Floor(_strike);
        uint256 multiplier = (_strike >= 5 * 10 ** exponent) ? 5 : 1;
        return ud(multiplier * 10 ** (exponent - 1));
    }

    /// @notice Rounds `strike` using the calculated strike interval
    /// @param strike The price to round (18 decimals)
    /// @return The rounded strike price (18 decimals)
    function roundToStrikeInterval(UD60x18 strike) internal pure returns (UD60x18) {
        uint256 _strike = strike.div(ONE).unwrap();
        uint256 interval = calculateStrikeInterval(strike).div(ONE).unwrap();
        uint256 lower = interval * (_strike / interval);
        uint256 upper = interval * ((_strike / interval) + 1);
        return (_strike - lower < upper - _strike) ? ud(lower) : ud(upper);
    }

    /// @notice Calculate the log moneyness of a strike/spot price pair
    /// @param spot The spot price (18 decimals)
    /// @param strike The strike price (18 decimals)
    /// @return The log moneyness of the strike price (18 decimals)
    function logMoneyness(UD60x18 spot, UD60x18 strike) internal pure returns (UD60x18) {
        return (spot / strike).intoSD59x18().ln().abs().intoUD60x18();
    }

    /// @notice Calculate the initialization fee for a pool
    /// @param spot The spot price (18 decimals)
    /// @param strike The strike price (18 decimals)
    /// @param maturity The maturity timestamp of the option
    /// @return The initialization fee (18 decimals)
    function initializationFee(UD60x18 spot, UD60x18 strike, uint256 maturity) internal view returns (UD60x18) {
        UD60x18 moneyness = logMoneyness(spot, strike);
        uint256 timeToMaturity = calculateTimeToMaturity(maturity);
        UD60x18 kBase = moneyness < ATM_MONEYNESS
            ? (ATM_MONEYNESS - moneyness).intoSD59x18().pow(iFOUR).intoUD60x18()
            : moneyness - ATM_MONEYNESS;
        uint256 tBase = timeToMaturity < NEAR_TERM_TTM
            ? 3 * (NEAR_TERM_TTM - timeToMaturity) + NEAR_TERM_TTM
            : timeToMaturity;
        UD60x18 scaledT = (ud(tBase * 1e18) / ud(ONE_YEAR_TTM * 1e18)).sqrt();

        return INITIALIZATION_ALPHA * (kBase + scaledT) * scaledT * FEE_SCALAR;
    }

    /// @notice Converts a number with `inputDecimals`, to a number with given amount of decimals
    /// @param value The value to convert
    /// @param inputDecimals The amount of decimals the input value has
    /// @param targetDecimals The amount of decimals to convert to
    /// @return The converted value
    function scaleDecimals(uint256 value, uint8 inputDecimals, uint8 targetDecimals) internal pure returns (uint256) {
        if (targetDecimals == inputDecimals) return value;
        if (targetDecimals > inputDecimals) return value * (10 ** (targetDecimals - inputDecimals));

        return value / (10 ** (inputDecimals - targetDecimals));
    }

    /// @notice Converts a number with `inputDecimals`, to a number with given amount of decimals
    /// @param value The value to convert
    /// @param inputDecimals The amount of decimals the input value has
    /// @param targetDecimals The amount of decimals to convert to
    /// @return The converted value
    function scaleDecimals(int256 value, uint8 inputDecimals, uint8 targetDecimals) internal pure returns (int256) {
        if (targetDecimals == inputDecimals) return value;
        if (targetDecimals > inputDecimals) return value * int256(10 ** (targetDecimals - inputDecimals));

        return value / int256(10 ** (inputDecimals - targetDecimals));
    }

    /// @notice Performs a naive log10 calculation on `input` returning the floor of the result
    function log10Floor(uint256 input) internal pure returns (uint256 count) {
        while (input >= 10) {
            input /= 10;
            count++;
        }

        return count;
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {SD59x18} from "lib/prb-math/src/SD59x18.sol";

import {OptionMath} from "./OptionMath.sol";

library OptionMathExternal {
    /// @notice Calculate option delta
    /// @param spot Spot price
    /// @param strike Strike price
    /// @param timeToMaturity Duration of option contract (in years)
    /// @param volAnnualized Annualized volatility
    /// @param isCall whether to price "call" or "put" option
    /// @return price Option delta
    function optionDelta(
        UD60x18 spot,
        UD60x18 strike,
        UD60x18 timeToMaturity,
        UD60x18 volAnnualized,
        UD60x18 riskFreeRate,
        bool isCall
    ) public pure returns (SD59x18) {
        return OptionMath.optionDelta(spot, strike, timeToMaturity, volAnnualized, riskFreeRate, isCall);
    }

    /// @notice Calculate the price of an option using the Black-Scholes model
    /// @dev this implementation assumes zero interest
    /// @param spot Spot price (18 decimals)
    /// @param strike Strike price (18 decimals)
    /// @param timeToMaturity Duration of option contract (in years) (18 decimals)
    /// @param volAnnualized Annualized volatility (18 decimals)
    /// @param riskFreeRate The risk-free rate (18 decimals)
    /// @param isCall whether to price "call" or "put" option
    /// @return price The Black-Scholes option price (18 decimals)
    function blackScholesPrice(
        UD60x18 spot,
        UD60x18 strike,
        UD60x18 timeToMaturity,
        UD60x18 volAnnualized,
        UD60x18 riskFreeRate,
        bool isCall
    ) public pure returns (UD60x18) {
        return OptionMath.blackScholesPrice(spot, strike, timeToMaturity, volAnnualized, riskFreeRate, isCall);
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {BokkyPooBahsDateTimeLibrary as DateTime} from "lib/BokkyPooBahsDateTimeLibrary/contracts/BokkyPooBahsDateTimeLibrary.sol";
import {IERC20Metadata} from "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";
import {UintUtils} from "@solidstate/contracts/utils/UintUtils.sol";

import {IPoolInternal} from "../pool/IPoolInternal.sol";

import {WAD} from "./Constants.sol";

library PoolName {
    using UintUtils for uint256;

    /// @notice Returns pool parameters as human-readable text
    function name(
        address base,
        address quote,
        uint256 maturity,
        uint256 strike,
        bool isCallPool
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    IERC20Metadata(base).symbol(),
                    "-",
                    IERC20Metadata(quote).symbol(),
                    "-",
                    maturityToString(maturity),
                    "-",
                    strikeToString(strike),
                    "-",
                    isCallPool ? "C" : "P"
                )
            );
    }

    /// @notice Converts the `strike` into a string
    function strikeToString(uint256 strike) internal pure returns (string memory) {
        bytes memory strikeBytes;
        if (strike >= WAD) {
            strikeBytes = abi.encodePacked((strike / WAD).toString());

            strike = ((strike * 100) / WAD) % 100;
            if (strike > 0) {
                if (strike % 10 == 0) {
                    strikeBytes = abi.encodePacked(strikeBytes, ".", (strike / 10).toString());
                } else {
                    strikeBytes = abi.encodePacked(strikeBytes, ".", strike < 10 ? "0" : "", strike.toString());
                }
            }
        } else {
            strikeBytes = abi.encodePacked("0.");
            strike *= 10;

            while (strike < WAD) {
                strikeBytes = abi.encodePacked(strikeBytes, "0");
                strike *= 10;
            }

            strikeBytes = abi.encodePacked(strikeBytes, (strike / WAD).toString());

            uint256 lastDecimal = (strike * 10) / WAD - (strike / WAD) * 10;
            if (lastDecimal != 0) {
                strikeBytes = abi.encodePacked(strikeBytes, lastDecimal.toString());
            }
        }

        return string(strikeBytes);
    }

    /// @notice Converts the `maturity` into a string
    function maturityToString(uint256 maturity) internal pure returns (string memory) {
        (uint256 year, uint256 month, uint256 day) = DateTime.timestampToDate(maturity);

        return string(abi.encodePacked(day < 10 ? "0" : "", day.toString(), monthToString(month), year.toString()));
    }

    /// @notice Converts the `month` into a string
    function monthToString(uint256 month) internal pure returns (string memory) {
        if (month == 1) return "JAN";
        if (month == 2) return "FEB";
        if (month == 3) return "MAR";
        if (month == 4) return "APR";
        if (month == 5) return "MAY";
        if (month == 6) return "JUN";
        if (month == 7) return "JUL";
        if (month == 8) return "AUG";
        if (month == 9) return "SEP";
        if (month == 10) return "OCT";
        if (month == 11) return "NOV";
        if (month == 12) return "DEC";

        revert IPoolInternal.Pool__InvalidMonth(month);
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {Math} from "@solidstate/contracts/utils/Math.sol";

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {SD59x18, sd} from "lib/prb-math/src/SD59x18.sol";

import {iZERO, ZERO, UD50_ZERO, UD50_ONE, UD50_TWO} from "./Constants.sol";
import {IPosition} from "./IPosition.sol";
import {Pricing} from "./Pricing.sol";
import {UD50x28} from "./UD50x28.sol";
import {SD49x28} from "./SD49x28.sol";
import {PRBMathExtra} from "./PRBMathExtra.sol";

/// @notice Keeps track of LP positions.
///         Stores the lower and upper Ticks of a user's range order, and tracks the pro-rata exposure of the order.
library Position {
    using Math for int256;
    using Position for Position.Key;
    using Position for Position.KeyInternal;
    using Position for Position.OrderType;
    using PRBMathExtra for UD60x18;

    struct Key {
        // The Agent that owns the exposure change of the Position
        address owner;
        // The Agent that can control modifications to the Position
        address operator;
        // The lower tick normalized price of the range order (18 decimals)
        UD60x18 lower;
        // The upper tick normalized price of the range order (18 decimals)
        UD60x18 upper;
        OrderType orderType;
    }

    /// @notice All the data used to calculate the key of the position
    struct KeyInternal {
        // The Agent that owns the exposure change of the Position
        address owner;
        // The Agent that can control modifications to the Position
        address operator;
        // The lower tick normalized price of the range order (18 decimals)
        UD60x18 lower;
        // The upper tick normalized price of the range order (18 decimals)
        UD60x18 upper;
        OrderType orderType;
        // ---- Values under are not used to compute the key hash but are included in this struct to reduce stack depth
        bool isCall;
        // The option strike (18 decimals)
        UD60x18 strike;
    }

    /// @notice The order type of a position
    enum OrderType {
        CSUP, // Collateral <-> Short - Use Premiums
        CS, // Collateral <-> Short
        LC // Long <-> Collateral
    }

    /// @notice All the data required to be saved in storage
    struct Data {
        // Used to track claimable fees over time (28 decimals)
        SD49x28 lastFeeRate;
        // The amount of fees a user can claim now. Resets after claim (18 decimals)
        UD60x18 claimableFees;
        // The timestamp of the last deposit. Used to enforce withdrawal delay
        uint256 lastDeposit;
    }

    struct Delta {
        SD59x18 collateral;
        SD59x18 longs;
        SD59x18 shorts;
    }

    /// @notice Returns the position key hash for `self`
    function keyHash(Key memory self) internal pure returns (bytes32) {
        return keccak256(abi.encode(self.owner, self.operator, self.lower, self.upper, self.orderType));
    }

    /// @notice Returns the position key hash for `self`
    function keyHash(KeyInternal memory self) internal pure returns (bytes32) {
        return
            keyHash(
                Key({
                    owner: self.owner,
                    operator: self.operator,
                    lower: self.lower,
                    upper: self.upper,
                    orderType: self.orderType
                })
            );
    }

    /// @notice Returns the internal position key for `self`
    /// @param strike The strike of the option (18 decimals)
    function toKeyInternal(Key memory self, UD60x18 strike, bool isCall) internal pure returns (KeyInternal memory) {
        return
            KeyInternal({
                owner: self.owner,
                operator: self.operator,
                lower: self.lower,
                upper: self.upper,
                orderType: self.orderType,
                strike: strike,
                isCall: isCall
            });
    }

    /// @notice Returns true if the position `orderType` is short
    function isShort(OrderType orderType) internal pure returns (bool) {
        return orderType == OrderType.CS || orderType == OrderType.CSUP;
    }

    /// @notice Returns true if the position `orderType` is long
    function isLong(OrderType orderType) internal pure returns (bool) {
        return orderType == OrderType.LC;
    }

    /// @notice Returns the percentage by which the market price has passed through the lower and upper prices
    ///         from left to right.
    ///         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ///         Usage:
    ///         CS order: f(x) defines the amount of shorts of a CS order holding one unit of liquidity.
    ///         LC order: (1 - f(x)) defines the amount of longs of a LC order holding one unit of liquidity.
    ///
    ///         Function definition:
    ///         case 1. f(x) = 0                                for x < lower
    ///         case 2. f(x) = (x - lower) / (upper - lower)    for lower <= x <= upper
    ///         case 3. f(x) = 1                                for x > upper
    ///         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function pieceWiseLinear(KeyInternal memory self, UD50x28 price) internal pure returns (UD50x28) {
        revertIfLowerGreaterOrEqualUpper(self.lower, self.upper);

        if (price <= self.lower.intoUD50x28()) return UD50_ZERO;
        else if (self.lower.intoUD50x28() < price && price < self.upper.intoUD50x28())
            return Pricing.proportion(self.lower, self.upper, price);
        else return UD50_ONE;
    }

    /// @notice Returns the amount of 'bid-side' collateral associated to a range order with one unit of liquidity.
    ///         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ///         Usage:
    ///         CS order: bid-side collateral defines the premiums generated from selling options.
    ///         LC order: bid-side collateral defines the collateral used to pay for buying long options.
    ///
    ///         Function definition:
    ///         case 1. f(x) = 0                                            for x < lower
    ///         case 2. f(x) = (price**2 - lower) / [2 * (upper - lower)]   for lower <= x <= upper
    ///         case 3. f(x) = (upper + lower) / 2                          for x > upper
    ///         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function pieceWiseQuadratic(KeyInternal memory self, UD50x28 price) internal pure returns (UD50x28) {
        revertIfLowerGreaterOrEqualUpper(self.lower, self.upper);

        UD50x28 lowerUD50 = self.lower.intoUD50x28();
        UD50x28 upperUD50 = self.upper.intoUD50x28();

        UD50x28 a;
        if (price <= lowerUD50) {
            return UD50_ZERO;
        } else if (lowerUD50 < price && price < upperUD50) {
            a = price;
        } else {
            a = upperUD50;
        }

        UD50x28 numerator = (a * a - lowerUD50 * lowerUD50);
        UD50x28 denominator = UD50_TWO * (upperUD50 - lowerUD50);

        return (numerator / denominator);
    }

    /// @notice Converts `_collateral` to the amount of contracts normalized to 18 decimals
    /// @param strike The strike price (18 decimals)
    function collateralToContracts(UD60x18 _collateral, UD60x18 strike, bool isCall) internal pure returns (UD60x18) {
        return isCall ? _collateral : _collateral / strike;
    }

    /// @notice Converts `_contracts` to the amount of collateral normalized to 18 decimals
    /// @dev WARNING: Decimals needs to be scaled before using this amount for collateral transfers
    /// @param strike The strike price (18 decimals)
    function contractsToCollateral(UD60x18 _contracts, UD60x18 strike, bool isCall) internal pure returns (UD60x18) {
        return isCall ? _contracts : _contracts * strike;
    }

    /// @notice Converts `_collateral` to the amount of contracts normalized to 28 decimals
    /// @param strike The strike price (18 decimals)
    function collateralToContracts(UD50x28 _collateral, UD60x18 strike, bool isCall) internal pure returns (UD50x28) {
        return isCall ? _collateral : _collateral / strike.intoUD50x28();
    }

    /// @notice Converts `_contracts` to the amount of collateral normalized to 28 decimals
    /// @dev WARNING: Decimals needs to be scaled before using this amount for collateral transfers
    /// @param strike The strike price (18 decimals)
    function contractsToCollateral(UD50x28 _contracts, UD60x18 strike, bool isCall) internal pure returns (UD50x28) {
        return isCall ? _contracts : _contracts * strike.intoUD50x28();
    }

    /// @notice Returns the per-tick liquidity phi (delta) for a specific position key `self`
    /// @param size The contract amount (18 decimals)
    function liquidityPerTick(KeyInternal memory self, UD60x18 size) internal pure returns (UD50x28) {
        UD60x18 amountOfTicks = Pricing.amountOfTicksBetween(self.lower, self.upper);

        return size.intoUD50x28() / amountOfTicks.intoUD50x28();
    }

    /// @notice Returns the bid collateral (18 decimals) either used to buy back options or revenue/ income generated
    ///         from underwriting / selling options.
    ///         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ///         For a <= p <= b we have:
    ///
    ///         bid(p; a, b) = [ (p - a) / (b - a) ] * [ (a + p)  / 2 ]
    ///                      = (p^2 - a^2) / [2 * (b - a)]
    ///         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// @param self The internal position key
    /// @param size The contract amount (18 decimals)
    /// @param price The current market price (28 decimals)
    function bid(KeyInternal memory self, UD60x18 size, UD50x28 price) internal pure returns (UD60x18) {
        return
            contractsToCollateral(pieceWiseQuadratic(self, price) * size.intoUD50x28(), self.strike, self.isCall)
                .intoUD60x18();
    }

    /// @notice Returns the total collateral (18 decimals) held by the position key `self`. Note that here we do not
    ///         distinguish between ask- and bid-side collateral. This increases the capital efficiency of the range order
    /// @param size The contract amount (18 decimals)
    /// @param price The current market price (28 decimals)
    function collateral(
        KeyInternal memory self,
        UD60x18 size,
        UD50x28 price
    ) internal pure returns (UD60x18 _collateral) {
        UD50x28 nu = pieceWiseLinear(self, price);

        if (self.orderType.isShort()) {
            _collateral = contractsToCollateral((UD50_ONE - nu) * size.intoUD50x28(), self.strike, self.isCall)
                .intoUD60x18();

            if (self.orderType == OrderType.CSUP) {
                _collateral = _collateral - (self.bid(size, self.upper.intoUD50x28()) - self.bid(size, price));
            } else {
                _collateral = _collateral + self.bid(size, price);
            }
        } else if (self.orderType.isLong()) {
            _collateral = self.bid(size, price);
        } else {
            revert IPosition.Position__InvalidOrderType();
        }
    }

    /// @notice Returns the total contracts (18 decimals) held by the position key `self`
    /// @param size The contract amount (18 decimals)
    /// @param price The current market price (28 decimals)
    function contracts(KeyInternal memory self, UD60x18 size, UD50x28 price) internal pure returns (UD60x18) {
        UD50x28 nu = pieceWiseLinear(self, price);

        if (self.orderType.isLong()) {
            return ((UD50_ONE - nu) * size.intoUD50x28()).intoUD60x18();
        }

        return (nu * size.intoUD50x28()).intoUD60x18();
    }

    /// @notice Returns the number of long contracts (18 decimals) held in position `self` at current price
    /// @param size The contract amount (18 decimals)
    /// @param price The current market price (28 decimals)
    function long(KeyInternal memory self, UD60x18 size, UD50x28 price) internal pure returns (UD60x18) {
        if (self.orderType.isShort()) {
            return ZERO;
        } else if (self.orderType.isLong()) {
            return self.contracts(size, price);
        } else {
            revert IPosition.Position__InvalidOrderType();
        }
    }

    /// @notice Returns the number of short contracts (18 decimals) held in position `self` at current price
    /// @param size The contract amount (18 decimals)
    /// @param price The current market price (28 decimals)
    function short(KeyInternal memory self, UD60x18 size, UD50x28 price) internal pure returns (UD60x18) {
        if (self.orderType.isShort()) {
            return self.contracts(size, price);
        } else if (self.orderType.isLong()) {
            return ZERO;
        } else {
            revert IPosition.Position__InvalidOrderType();
        }
    }

    /// @notice Calculate the update for the Position. Either increments them in case withdraw is False (i.e. in case
    ///         there is a deposit) and otherwise decreases them. Returns the change in collateral, longs, shorts. These
    ///         are transferred to (withdrawal)or transferred from (deposit) the Agent (Position.operator).
    /// @param currentBalance The current balance of tokens (18 decimals)
    /// @param amount The number of tokens deposited or withdrawn (18 decimals)
    /// @param price The current market price, used to compute the change in collateral, long and shorts due to the
    ///        change in tokens (28 decimals)
    /// @return delta Absolute change in collateral / longs / shorts due to change in tokens
    function calculatePositionUpdate(
        KeyInternal memory self,
        UD60x18 currentBalance,
        SD59x18 amount,
        UD50x28 price
    ) internal pure returns (Delta memory delta) {
        if (currentBalance.intoSD59x18() + amount < iZERO)
            revert IPosition.Position__InvalidPositionUpdate(currentBalance, amount);

        UD60x18 absChangeTokens = amount.abs().intoUD60x18();
        SD59x18 sign = amount > iZERO ? sd(1e18) : sd(-1e18);

        delta.collateral = sign * (self.collateral(absChangeTokens, price)).intoSD59x18();

        delta.longs = sign * (self.long(absChangeTokens, price)).intoSD59x18();
        delta.shorts = sign * (self.short(absChangeTokens, price)).intoSD59x18();
    }

    /// @notice Revert if `lower` is greater or equal to `upper`
    function revertIfLowerGreaterOrEqualUpper(UD60x18 lower, UD60x18 upper) internal pure {
        if (lower >= upper) revert IPosition.Position__LowerGreaterOrEqualUpper(lower, upper);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";
import {SD59x18} from "lib/prb-math/src/SD59x18.sol";

import {UD50x28, uMAX_UD50x28, ud50x28} from "./UD50x28.sol";
import {SD49x28, uMAX_SD49x28} from "./SD49x28.sol";

import {iZERO, SD49_ZERO} from "./Constants.sol";

library PRBMathExtra {
    error SD59x18_IntoSD49x28_Overflow(SD59x18 x);
    error UD60x18_IntoUD50x28_Overflow(UD60x18 x);

    function intoSD49x28(SD59x18 x) internal pure returns (SD49x28 result) {
        int256 xUint = x.unwrap() * int256(1e10); // Scaling factor = 10 ** (28 - 18)
        if (xUint > uMAX_SD49x28) revert SD59x18_IntoSD49x28_Overflow(x);
        result = SD49x28.wrap(xUint);
    }

    function intoUD50x28(UD60x18 x) internal pure returns (UD50x28 result) {
        uint256 xUint = x.unwrap() * 1e10; // Scaling factor = 10 ** (28 - 18)
        if (xUint > uMAX_UD50x28) revert UD60x18_IntoUD50x28_Overflow(x);
        result = UD50x28.wrap(xUint);
    }

    //

    /// @notice Returns the greater of two numbers `a` and `b`
    function max(UD60x18 a, UD60x18 b) internal pure returns (UD60x18) {
        return a > b ? a : b;
    }

    /// @notice Returns the lesser of two numbers `a` and `b`
    function min(UD60x18 a, UD60x18 b) internal pure returns (UD60x18) {
        return a > b ? b : a;
    }

    /// @notice Returns the greater of two numbers `a` and `b`
    function max(SD59x18 a, SD59x18 b) internal pure returns (SD59x18) {
        return a > b ? a : b;
    }

    /// @notice Returns the lesser of two numbers `a` and `b`
    function min(SD59x18 a, SD59x18 b) internal pure returns (SD59x18) {
        return a > b ? b : a;
    }

    /// @notice Returns the sum of `a` and `b`
    function add(UD60x18 a, SD59x18 b) internal pure returns (UD60x18) {
        return b < iZERO ? sub(a, -b) : a + b.intoUD60x18();
    }

    /// @notice Returns the difference of `a` and `b`
    function sub(UD60x18 a, SD59x18 b) internal pure returns (UD60x18) {
        return b < iZERO ? add(a, -b) : a - b.intoUD60x18();
    }

    ////////////////////////

    /// @notice Returns the greater of two numbers `a` and `b`
    function max(UD50x28 a, UD50x28 b) internal pure returns (UD50x28) {
        return a > b ? a : b;
    }

    /// @notice Returns the lesser of two numbers `a` and `b`
    function min(UD50x28 a, UD50x28 b) internal pure returns (UD50x28) {
        return a > b ? b : a;
    }

    /// @notice Returns the greater of two numbers `a` and `b`
    function max(SD49x28 a, SD49x28 b) internal pure returns (SD49x28) {
        return a > b ? a : b;
    }

    /// @notice Returns the lesser of two numbers `a` and `b`
    function min(SD49x28 a, SD49x28 b) internal pure returns (SD49x28) {
        return a > b ? b : a;
    }

    /// @notice Returns the sum of `a` and `b`
    function add(UD50x28 a, SD49x28 b) internal pure returns (UD50x28) {
        return b < SD49_ZERO ? sub(a, -b) : a + b.intoUD50x28();
    }

    /// @notice Returns the difference of `a` and `b`
    function sub(UD50x28 a, SD49x28 b) internal pure returns (UD50x28) {
        return b < SD49_ZERO ? add(a, -b) : a - b.intoUD50x28();
    }

    ////////////////////////

    /// @notice Rounds an `UD50x28` to the nearest `UD60x18`
    function roundToNearestUD60x18(UD50x28 value) internal pure returns (UD60x18 result) {
        // Rounded down by default
        result = value.intoUD60x18();

        // (10 ** (28 - 18)) / 2 = 5e9
        if (value - intoUD50x28(result) >= ud50x28(5e9)) {
            // Round up
            result = result + ud(1);
        }
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {DoublyLinkedListUD60x18, DoublyLinkedList} from "../libraries/DoublyLinkedListUD60x18.sol";
import {UD50x28} from "../libraries/UD50x28.sol";
import {PoolStorage} from "../pool/PoolStorage.sol";
import {PRBMathExtra} from "./PRBMathExtra.sol";

import {IPricing} from "./IPricing.sol";

import {ZERO, UD50_ONE} from "./Constants.sol";

/// @notice This library implements the functions necessary for computing price movements within a tick range.
/// @dev WARNING: This library should not be used for computations that span multiple ticks. Instead, the user should
///      use the functions of this library to simplify computations for more complex price calculations.
library Pricing {
    using DoublyLinkedListUD60x18 for DoublyLinkedList.Bytes32List;
    using PoolStorage for PoolStorage.Layout;
    using PRBMathExtra for UD60x18;
    using PRBMathExtra for UD50x28;

    struct Args {
        UD50x28 liquidityRate; // Amount of liquidity (28 decimals)
        UD50x28 marketPrice; // The current market price (28 decimals)
        UD60x18 lower; // The normalized price of the lower bound of the range (18 decimals)
        UD60x18 upper; // The normalized price of the upper bound of the range (18 decimals)
        bool isBuy; // The direction of the trade
    }

    /// @notice Returns the percentage by which the market price has passed through the lower and upper prices
    ///         from left to right. Reverts if the market price is not within the range of the lower and upper prices.
    function proportion(UD60x18 lower, UD60x18 upper, UD50x28 marketPrice) internal pure returns (UD50x28) {
        UD60x18 marketPriceUD60 = marketPrice.intoUD60x18();
        if (lower >= upper) revert IPricing.Pricing__UpperNotGreaterThanLower(lower, upper);
        if (lower > marketPriceUD60 || marketPriceUD60 > upper)
            revert IPricing.Pricing__PriceOutOfRange(lower, upper, marketPriceUD60);

        return (marketPrice - lower.intoUD50x28()) / (upper - lower).intoUD50x28();
    }

    /// @notice Returns the percentage by which the market price has passed through the lower and upper prices
    ///         from left to right. Reverts if the market price is not within the range of the lower and upper prices.
    function proportion(Args memory args) internal pure returns (UD50x28) {
        return proportion(args.lower, args.upper, args.marketPrice);
    }

    /// @notice Find the number of ticks of an active tick range. Used to compute the aggregate, bid or ask liquidity
    ///         either of the pool or the range order.
    ///         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ///         min_tick_distance = 0.01
    ///         lower = 0.01
    ///         upper = 0.03
    ///         num_ticks = 2
    ///
    ///         0.01               0.02               0.03
    ///          |xxxxxxxxxxxxxxxxxx|xxxxxxxxxxxxxxxxxx|
    ///
    ///         Then there are two active ticks, 0.01 and 0.02, within the active tick range.
    ///         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function amountOfTicksBetween(UD60x18 lower, UD60x18 upper) internal pure returns (UD60x18) {
        if (lower >= upper) revert IPricing.Pricing__UpperNotGreaterThanLower(lower, upper);

        return (upper - lower) / PoolStorage.MIN_TICK_DISTANCE;
    }

    /// @notice Returns the number of ticks between `args.lower` and `args.upper`
    function amountOfTicksBetween(Args memory args) internal pure returns (UD60x18) {
        return amountOfTicksBetween(args.lower, args.upper);
    }

    /// @notice Returns the liquidity between `args.lower` and `args.upper`
    function liquidity(Args memory args) internal pure returns (UD60x18) {
        return (args.liquidityRate * amountOfTicksBetween(args).intoUD50x28()).intoUD60x18();
    }

    /// @notice Returns the bid-side liquidity between `args.lower` and `args.upper`
    function bidLiquidity(Args memory args) internal pure returns (UD60x18) {
        return (proportion(args) * liquidity(args).intoUD50x28()).roundToNearestUD60x18();
    }

    /// @notice Returns the ask-side liquidity between `args.lower` and `args.upper`
    function askLiquidity(Args memory args) internal pure returns (UD60x18) {
        return ((UD50_ONE - proportion(args)) * liquidity(args).intoUD50x28()).roundToNearestUD60x18();
    }

    /// @notice Returns the maximum trade size (askLiquidity or bidLiquidity depending on the TradeSide).
    function maxTradeSize(Args memory args) internal pure returns (UD60x18) {
        return args.isBuy ? askLiquidity(args) : bidLiquidity(args);
    }

    /// @notice Computes price reached from the current lower/upper tick after buying/selling `trade_size` amount of
    ///         contracts
    function price(Args memory args, UD60x18 tradeSize) internal pure returns (UD50x28) {
        UD60x18 liq = liquidity(args);
        if (liq == ZERO) return (args.isBuy ? args.upper : args.lower).intoUD50x28();

        UD50x28 _proportion;
        if (tradeSize > ZERO) _proportion = tradeSize.intoUD50x28() / liq.intoUD50x28();

        if (_proportion > UD50_ONE) revert IPricing.Pricing__PriceCannotBeComputedWithinTickRange();

        return
            args.isBuy
                ? args.lower.intoUD50x28() + (args.upper - args.lower).intoUD50x28() * _proportion
                : args.upper.intoUD50x28() - (args.upper - args.lower).intoUD50x28() * _proportion;
    }

    /// @notice Gets the next market price within a tick range after buying/selling `tradeSize` amount of contracts
    function nextPrice(Args memory args, UD60x18 tradeSize) internal pure returns (UD50x28) {
        UD60x18 offset = args.isBuy ? bidLiquidity(args) : askLiquidity(args);
        return price(args, offset + tradeSize);
    }
}

// SPDX-License-Identifier: MIT
// Derived from SD59x18 from PRBMath ( https://github.com/PaulRBerg/prb-math )
pragma solidity ^0.8.19;

import {mulDiv} from "lib/prb-math/src/Common.sol";
import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {SD59x18} from "lib/prb-math/src/SD59x18.sol";

import {UD50x28} from "./UD50x28.sol";

type SD49x28 is int256;

/// @dev Max SD49x28 value
int256 constant uMAX_SD49x28 = type(int256).max;
/// @dev Min SD49x28 value
int256 constant uMIN_SD49x28 = type(int256).min;

/// @dev The unit number, which gives the decimal precision of SD49x28.
int256 constant uUNIT = 1e28;
SD49x28 constant UNIT = SD49x28.wrap(uUNIT);

// Scaling factor = 10 ** (28 - 18)
int256 constant SCALING_FACTOR = 1e10;

error SD49x28_Mul_InputTooSmall();
error SD49x28_Mul_Overflow(SD49x28 x, SD49x28 y);

error SD49x28_Div_InputTooSmall();
error SD49x28_Div_Overflow(SD49x28 x, SD49x28 y);

error SD49x28_IntoUD50x28_Underflow(SD49x28 x);

error SD49x28_Abs_MinSD49x28();

/// @notice Wraps a int256 number into the SD49x28 value type.
function wrap(int256 x) pure returns (SD49x28 result) {
    result = SD49x28.wrap(x);
}

/// @notice Unwraps a SD49x28 number into int256.
function unwrap(SD49x28 x) pure returns (int256 result) {
    result = SD49x28.unwrap(x);
}

function sd49x28(int256 x) pure returns (SD49x28 result) {
    result = SD49x28.wrap(x);
}

/// @notice Casts an SD49x28 number into UD50x28.
/// @dev Requirements:
/// - x must be positive.
function intoUD50x28(SD49x28 x) pure returns (UD50x28 result) {
    int256 xInt = SD49x28.unwrap(x);
    if (xInt < 0) {
        revert SD49x28_IntoUD50x28_Underflow(x);
    }
    result = UD50x28.wrap(uint256(xInt));
}

function intoUD60x18(SD49x28 x) pure returns (UD60x18 result) {
    return intoUD50x28(x).intoUD60x18();
}

function intoSD59x18(SD49x28 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(x.unwrap() / SCALING_FACTOR);
}

/// @notice Implements the checked addition operation (+) in the SD49x28 type.
function add(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    return wrap(x.unwrap() + y.unwrap());
}

/// @notice Implements the AND (&) bitwise operation in the SD49x28 type.
function and(SD49x28 x, int256 bits) pure returns (SD49x28 result) {
    return wrap(x.unwrap() & bits);
}

/// @notice Implements the AND (&) bitwise operation in the SD49x28 type.
function and2(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    return wrap(x.unwrap() & y.unwrap());
}

/// @notice Implements the equal (=) operation in the SD49x28 type.
function eq(SD49x28 x, SD49x28 y) pure returns (bool result) {
    result = x.unwrap() == y.unwrap();
}

/// @notice Implements the greater than operation (>) in the SD49x28 type.
function gt(SD49x28 x, SD49x28 y) pure returns (bool result) {
    result = x.unwrap() > y.unwrap();
}

/// @notice Implements the greater than or equal to operation (>=) in the SD49x28 type.
function gte(SD49x28 x, SD49x28 y) pure returns (bool result) {
    result = x.unwrap() >= y.unwrap();
}

/// @notice Implements a zero comparison check function in the SD49x28 type.
function isZero(SD49x28 x) pure returns (bool result) {
    result = x.unwrap() == 0;
}

/// @notice Implements the left shift operation (<<) in the SD49x28 type.
function lshift(SD49x28 x, uint256 bits) pure returns (SD49x28 result) {
    result = wrap(x.unwrap() << bits);
}

/// @notice Implements the lower than operation (<) in the SD49x28 type.
function lt(SD49x28 x, SD49x28 y) pure returns (bool result) {
    result = x.unwrap() < y.unwrap();
}

/// @notice Implements the lower than or equal to operation (<=) in the SD49x28 type.
function lte(SD49x28 x, SD49x28 y) pure returns (bool result) {
    result = x.unwrap() <= y.unwrap();
}

/// @notice Implements the unchecked modulo operation (%) in the SD49x28 type.
function mod(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    result = wrap(x.unwrap() % y.unwrap());
}

/// @notice Implements the not equal operation (!=) in the SD49x28 type.
function neq(SD49x28 x, SD49x28 y) pure returns (bool result) {
    result = x.unwrap() != y.unwrap();
}

/// @notice Implements the NOT (~) bitwise operation in the SD49x28 type.
function not(SD49x28 x) pure returns (SD49x28 result) {
    result = wrap(~x.unwrap());
}

/// @notice Implements the OR (|) bitwise operation in the SD49x28 type.
function or(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    result = wrap(x.unwrap() | y.unwrap());
}

/// @notice Implements the right shift operation (>>) in the SD49x28 type.
function rshift(SD49x28 x, uint256 bits) pure returns (SD49x28 result) {
    result = wrap(x.unwrap() >> bits);
}

/// @notice Implements the checked subtraction operation (-) in the SD49x28 type.
function sub(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    result = wrap(x.unwrap() - y.unwrap());
}

/// @notice Implements the checked unary minus operation (-) in the SD49x28 type.
function unary(SD49x28 x) pure returns (SD49x28 result) {
    result = wrap(-x.unwrap());
}

/// @notice Implements the unchecked addition operation (+) in the SD49x28 type.
function uncheckedAdd(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    unchecked {
        result = wrap(x.unwrap() + y.unwrap());
    }
}

/// @notice Implements the unchecked subtraction operation (-) in the SD49x28 type.
function uncheckedSub(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    unchecked {
        result = wrap(x.unwrap() - y.unwrap());
    }
}

/// @notice Implements the unchecked unary minus operation (-) in the SD49x28 type.
function uncheckedUnary(SD49x28 x) pure returns (SD49x28 result) {
    unchecked {
        result = wrap(-x.unwrap());
    }
}

/// @notice Implements the XOR (^) bitwise operation in the SD49x28 type.
function xor(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    result = wrap(x.unwrap() ^ y.unwrap());
}

/// @notice Calculates the absolute value of x.
///
/// @dev Requirements:
/// - x must be greater than `MIN_SD49x28`.
///
/// @param x The SD49x28 number for which to calculate the absolute value.
/// @param result The absolute value of x as an SD49x28 number.
/// @custom:smtchecker abstract-function-nondet
function abs(SD49x28 x) pure returns (SD49x28 result) {
    int256 xInt = x.unwrap();
    if (xInt == uMIN_SD49x28) {
        revert SD49x28_Abs_MinSD49x28();
    }
    result = xInt < 0 ? wrap(-xInt) : x;
}

/// @notice Calculates the arithmetic average of x and y.
///
/// @dev Notes:
/// - The result is rounded toward zero.
///
/// @param x The first operand as an SD49x28 number.
/// @param y The second operand as an SD49x28 number.
/// @return result The arithmetic average as an SD49x28 number.
/// @custom:smtchecker abstract-function-nondet
function avg(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();

    unchecked {
        // This operation is equivalent to `x / 2 +  y / 2`, and it can never overflow.
        int256 sum = (xInt >> 1) + (yInt >> 1);

        if (sum < 0) {
            // If at least one of x and y is odd, add 1 to the result, because shifting negative numbers to the right
            // rounds down to infinity. The right part is equivalent to `sum + (x % 2 == 1 || y % 2 == 1)`.
            assembly ("memory-safe") {
                result := add(sum, and(or(xInt, yInt), 1))
            }
        } else {
            // Add 1 if both x and y are odd to account for the double 0.5 remainder truncated after shifting.
            result = wrap(sum + (xInt & yInt & 1));
        }
    }
}

/// @notice Divides two SD49x28 numbers, returning a new SD49x28 number.
///
/// @dev This is an extension of {Common.mulDiv} for signed numbers, which works by computing the signs and the absolute
/// values separately.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
/// - The result is rounded toward zero.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
/// - None of the inputs can be `MIN_SD49x28`.
/// - The denominator must not be zero.
/// - The result must fit in SD49x28.
///
/// @param x The numerator as an SD49x28 number.
/// @param y The denominator as an SD49x28 number.
/// @param result The quotient as an SD49x28 number.
/// @custom:smtchecker abstract-function-nondet
function div(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();
    if (xInt == uMIN_SD49x28 || yInt == uMIN_SD49x28) {
        revert SD49x28_Div_InputTooSmall();
    }

    // Get hold of the absolute values of x and y.
    uint256 xAbs;
    uint256 yAbs;
    unchecked {
        xAbs = xInt < 0 ? uint256(-xInt) : uint256(xInt);
        yAbs = yInt < 0 ? uint256(-yInt) : uint256(yInt);
    }

    // Compute the absolute value (x*UNIT÷y). The resulting value must fit in SD49x28.
    uint256 resultAbs = mulDiv(xAbs, uint256(uUNIT), yAbs);
    if (resultAbs > uint256(uMAX_SD49x28)) {
        revert SD49x28_Div_Overflow(x, y);
    }

    // Check if x and y have the same sign using two's complement representation. The left-most bit represents the sign (1 for
    // negative, 0 for positive or zero).
    bool sameSign = (xInt ^ yInt) > -1;

    // If the inputs have the same sign, the result should be positive. Otherwise, it should be negative.
    unchecked {
        result = wrap(sameSign ? int256(resultAbs) : -int256(resultAbs));
    }
}

/// @notice Multiplies two SD49x28 numbers together, returning a new SD49x28 number.
///
/// @dev Notes:
/// - Refer to the notes in {Common.mulDiv18}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv18}.
/// - None of the inputs can be `MIN_SD49x28`.
/// - The result must fit in SD49x28.
///
/// @param x The multiplicand as an SD49x28 number.
/// @param y The multiplier as an SD49x28 number.
/// @return result The product as an SD49x28 number.
/// @custom:smtchecker abstract-function-nondet
function mul(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();
    if (xInt == uMIN_SD49x28 || yInt == uMIN_SD49x28) {
        revert SD49x28_Mul_InputTooSmall();
    }

    // Get hold of the absolute values of x and y.
    uint256 xAbs;
    uint256 yAbs;
    unchecked {
        xAbs = xInt < 0 ? uint256(-xInt) : uint256(xInt);
        yAbs = yInt < 0 ? uint256(-yInt) : uint256(yInt);
    }

    // Compute the absolute value (x*y÷UNIT). The resulting value must fit in SD49x28.
    uint256 resultAbs = mulDiv(xAbs, yAbs, uint256(uUNIT));
    if (resultAbs > uint256(uMAX_SD49x28)) {
        revert SD49x28_Mul_Overflow(x, y);
    }

    // Check if x and y have the same sign using two's complement representation. The left-most bit represents the sign (1 for
    // negative, 0 for positive or zero).
    bool sameSign = (xInt ^ yInt) > -1;

    // If the inputs have the same sign, the result should be positive. Otherwise, it should be negative.
    unchecked {
        result = wrap(sameSign ? int256(resultAbs) : -int256(resultAbs));
    }
}

//////////////////////////////////////////////////////////////////////////

// The global "using for" directive makes the functions in this library callable on the SD49x28 type.
using {
    unwrap,
    intoSD59x18,
    intoUD50x28,
    intoUD60x18,
    abs,
    avg,
    add,
    and,
    eq,
    gt,
    gte,
    isZero,
    lshift,
    lt,
    lte,
    mod,
    neq,
    not,
    or,
    rshift,
    sub,
    uncheckedAdd,
    uncheckedSub,
    xor
} for SD49x28 global;

// The global "using for" directive makes it possible to use these operators on the SD49x28 type.
using {
    add as +,
    and2 as &,
    div as /,
    eq as ==,
    gt as >,
    gte as >=,
    lt as <,
    lte as <=,
    or as |,
    mod as %,
    mul as *,
    neq as !=,
    not as ~,
    sub as -,
    unary as -,
    xor as ^
} for SD49x28 global;

// SPDX-License-Identifier: MIT
// Derived from UD60x18 from PRBMath ( https://github.com/PaulRBerg/prb-math )
pragma solidity ^0.8.19;

import {mulDiv} from "lib/prb-math/src/Common.sol";
import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {SD49x28, uMAX_SD49x28} from "./SD49x28.sol";

type UD50x28 is uint256;

/// @dev Max UD50x28 value
uint256 constant uMAX_UD50x28 = type(uint256).max;

/// @dev The unit number, which gives the decimal precision of UD50x28.
uint256 constant uUNIT = 1e28;
UD50x28 constant UNIT = UD50x28.wrap(uUNIT);

// Scaling factor = 10 ** (28 - 18)
uint256 constant SCALING_FACTOR = 1e10;

error UD50x28_IntoSD49x28_Overflow(UD50x28 x);

/// @notice Wraps a uint256 number into the UD50x28 value type.
function wrap(uint256 x) pure returns (UD50x28 result) {
    result = UD50x28.wrap(x);
}

/// @notice Unwraps a UD50x28 number into uint256.
function unwrap(UD50x28 x) pure returns (uint256 result) {
    result = UD50x28.unwrap(x);
}

function ud50x28(uint256 x) pure returns (UD50x28 result) {
    result = UD50x28.wrap(x);
}

/// @notice Casts a UD50x28 number into SD49x28.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_SD49x28`.
function intoSD49x28(UD50x28 x) pure returns (SD49x28 result) {
    uint256 xUint = UD50x28.unwrap(x);
    if (xUint > uint256(uMAX_SD49x28)) {
        revert UD50x28_IntoSD49x28_Overflow(x);
    }
    result = SD49x28.wrap(int256(xUint));
}

function intoUD60x18(UD50x28 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(x.unwrap() / SCALING_FACTOR);
}

/// @notice Implements the checked addition operation (+) in the UD50x28 type.
function add(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    result = wrap(x.unwrap() + y.unwrap());
}

/// @notice Implements the AND (&) bitwise operation in the UD50x28 type.
function and(UD50x28 x, uint256 bits) pure returns (UD50x28 result) {
    result = wrap(x.unwrap() & bits);
}

/// @notice Implements the AND (&) bitwise operation in the UD50x28 type.
function and2(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    result = wrap(x.unwrap() & y.unwrap());
}

/// @notice Implements the equal operation (==) in the UD50x28 type.
function eq(UD50x28 x, UD50x28 y) pure returns (bool result) {
    result = x.unwrap() == y.unwrap();
}

/// @notice Implements the greater than operation (>) in the UD50x28 type.
function gt(UD50x28 x, UD50x28 y) pure returns (bool result) {
    result = x.unwrap() > y.unwrap();
}

/// @notice Implements the greater than or equal to operation (>=) in the UD50x28 type.
function gte(UD50x28 x, UD50x28 y) pure returns (bool result) {
    result = x.unwrap() >= y.unwrap();
}

/// @notice Implements a zero comparison check function in the UD50x28 type.
function isZero(UD50x28 x) pure returns (bool result) {
    // This wouldn't work if x could be negative.
    result = x.unwrap() == 0;
}

/// @notice Implements the left shift operation (<<) in the UD50x28 type.
function lshift(UD50x28 x, uint256 bits) pure returns (UD50x28 result) {
    result = wrap(x.unwrap() << bits);
}

/// @notice Implements the lower than operation (<) in the UD50x28 type.
function lt(UD50x28 x, UD50x28 y) pure returns (bool result) {
    result = x.unwrap() < y.unwrap();
}

/// @notice Implements the lower than or equal to operation (<=) in the UD50x28 type.
function lte(UD50x28 x, UD50x28 y) pure returns (bool result) {
    result = x.unwrap() <= y.unwrap();
}

/// @notice Implements the checked modulo operation (%) in the UD50x28 type.
function mod(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    result = wrap(x.unwrap() % y.unwrap());
}

/// @notice Implements the not equal operation (!=) in the UD50x28 type.
function neq(UD50x28 x, UD50x28 y) pure returns (bool result) {
    result = x.unwrap() != y.unwrap();
}

/// @notice Implements the NOT (~) bitwise operation in the UD50x28 type.
function not(UD50x28 x) pure returns (UD50x28 result) {
    result = wrap(~x.unwrap());
}

/// @notice Implements the OR (|) bitwise operation in the UD50x28 type.
function or(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    result = wrap(x.unwrap() | y.unwrap());
}

/// @notice Implements the right shift operation (>>) in the UD50x28 type.
function rshift(UD50x28 x, uint256 bits) pure returns (UD50x28 result) {
    result = wrap(x.unwrap() >> bits);
}

/// @notice Implements the checked subtraction operation (-) in the UD50x28 type.
function sub(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    result = wrap(x.unwrap() - y.unwrap());
}

/// @notice Implements the unchecked addition operation (+) in the UD50x28 type.
function uncheckedAdd(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    unchecked {
        result = wrap(x.unwrap() + y.unwrap());
    }
}

/// @notice Implements the unchecked subtraction operation (-) in the UD50x28 type.
function uncheckedSub(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    unchecked {
        result = wrap(x.unwrap() - y.unwrap());
    }
}

/// @notice Implements the XOR (^) bitwise operation in the UD50x28 type.
function xor(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    result = wrap(x.unwrap() ^ y.unwrap());
}

/// @notice Calculates the arithmetic average of x and y using the following formula:
///
/// $$
/// avg(x, y) = (x & y) + ((xUint ^ yUint) / 2)
/// $$
//
/// In English, this is what this formula does:
///
/// 1. AND x and y.
/// 2. Calculate half of XOR x and y.
/// 3. Add the two results together.
///
/// This technique is known as SWAR, which stands for "SIMD within a register". You can read more about it here:
/// https://devblogs.microsoft.com/oldnewthing/20220207-00/?p=106223
///
/// @dev Notes:
/// - The result is rounded down.
///
/// @param x The first operand as a UD50x28 number.
/// @param y The second operand as a UD50x28 number.
/// @return result The arithmetic average as a UD50x28 number.
/// @custom:smtchecker abstract-function-nondet
function avg(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    uint256 xUint = x.unwrap();
    uint256 yUint = y.unwrap();
    unchecked {
        result = wrap((xUint & yUint) + ((xUint ^ yUint) >> 1));
    }
}

/// @notice Divides two UD50x28 numbers, returning a new UD50x28 number.
///
/// @dev Uses {Common.mulDiv} to enable overflow-safe multiplication and division.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
///
/// @param x The numerator as a UD50x28 number.
/// @param y The denominator as a UD50x28 number.
/// @param result The quotient as a UD50x28 number.
/// @custom:smtchecker abstract-function-nondet
function div(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    result = UD50x28.wrap(mulDiv(x.unwrap(), uUNIT, y.unwrap()));
}

/// @notice Multiplies two UD50x28 numbers together, returning a new UD50x28 number.
///
/// @dev Uses {Common.mulDiv} to enable overflow-safe multiplication and division.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
///
/// @dev See the documentation in {Common.mulDiv18}.
/// @param x The multiplicand as a UD50x28 number.
/// @param y The multiplier as a UD50x28 number.
/// @return result The product as a UD50x28 number.
/// @custom:smtchecker abstract-function-nondet
function mul(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    result = UD50x28.wrap(mulDiv(x.unwrap(), y.unwrap(), uUNIT));
}

//////////////////////////////////////////////////////////////////////////

// The global "using for" directive makes the functions in this library callable on the UD50x28 type.
using {
    unwrap,
    intoUD60x18,
    intoSD49x28,
    avg,
    add,
    and,
    eq,
    gt,
    gte,
    isZero,
    lshift,
    lt,
    lte,
    mod,
    neq,
    not,
    or,
    rshift,
    sub,
    uncheckedAdd,
    uncheckedSub,
    xor
} for UD50x28 global;

// The global "using for" directive makes it possible to use these operators on the UD50x28 type.
using {
    add as +,
    and2 as &,
    div as /,
    eq as ==,
    gt as >,
    gte as >=,
    lt as <,
    lte as <=,
    or as |,
    mod as %,
    mul as *,
    neq as !=,
    not as ~,
    sub as -,
    xor as ^
} for UD50x28 global;

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

interface IMiningAddRewards {
    function addRewards(uint256 amount) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

interface IPaymentSplitter {
    function pay(uint256 baseAmount, uint256 quoteAmount) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {IERC1155Base} from "@solidstate/contracts/token/ERC1155/base/IERC1155Base.sol";
import {IERC1155Enumerable} from "@solidstate/contracts/token/ERC1155/enumerable/IERC1155Enumerable.sol";

interface IOptionPS is IERC1155Base, IERC1155Enumerable {
    enum TokenType {
        Long,
        Short
    }

    error OptionPS__ExercisePeriodEnded(uint256 maturity, uint256 exercisePeriodEnd);
    error OptionPS__ExercisePeriodNotEnded(uint256 maturity, uint256 exercisePeriodEnd);
    error OptionPS__OptionMaturityNot8UTC(uint256 maturity);
    error OptionPS__OptionExpired(uint256 maturity);
    error OptionPS__OptionNotExpired(uint256 maturity);
    error OptionPS__StrikeNotMultipleOfStrikeInterval(UD60x18 strike, UD60x18 strikeInterval);

    event Exercise(
        address indexed user,
        UD60x18 strike,
        uint256 maturity,
        UD60x18 contractSize,
        UD60x18 exerciseValue,
        UD60x18 exerciseCost,
        UD60x18 exerciseFee
    );

    event Settle(
        address indexed user,
        UD60x18 contractSize,
        UD60x18 strike,
        uint256 maturity,
        UD60x18 collateralAmount,
        UD60x18 exerciseTokenAmount
    );

    event Underwrite(
        address indexed underwriter,
        address indexed longReceiver,
        UD60x18 strike,
        uint256 maturity,
        UD60x18 contractSize
    );

    event Annihilate(address indexed annihilator, UD60x18 strike, uint256 maturity, UD60x18 contractSize);

    /// @notice Returns the pair infos for this option
    function getSettings() external view returns (address base, address quote, bool isCall);

    /// @notice Returns the length of time in seconds during which long holders can exercise their options after maturity
    function getExerciseDuration() external pure returns (uint256);

    /// @notice Underwrite an option by depositing collateral
    /// @param strike the option strike price (18 decimals)
    /// @param longReceiver the address that will receive the long tokens
    /// @param maturity the option maturity timestamp
    /// @param contractSize number of long tokens to mint (18 decimals)
    function underwrite(UD60x18 strike, uint64 maturity, address longReceiver, UD60x18 contractSize) external;

    /// @notice Burn longs and shorts, to recover collateral of the option
    /// @param strike the option strike price (18 decimals)
    /// @param maturity the option maturity timestamp
    /// @param contractSize number of contracts to annihilate (18 decimals)
    function annihilate(UD60x18 strike, uint64 maturity, UD60x18 contractSize) external;

    /// @notice Exercises the long options held by the caller.
    /// @param strike the option strike price (18 decimals)
    /// @param maturity the option maturity timestamp
    /// @param contractSize number of long tokens to exercise (18 decimals)
    /// @return exerciseValue the amount of tokens transferred to the caller
    function exercise(UD60x18 strike, uint64 maturity, UD60x18 contractSize) external returns (uint256 exerciseValue);

    /// @notice Settles the short options held by the caller.
    /// @param strike the option strike price (18 decimals)
    /// @param maturity the option maturity timestamp
    /// @param contractSize number of short tokens to settle (18 decimals)
    /// @return collateralAmount the amount of collateral transferred to the caller (base for calls, quote for puts)
    /// @return exerciseTokenAmount the amount of exerciseToken transferred to the caller (quote for calls, base for puts)
    function settle(
        UD60x18 strike,
        uint64 maturity,
        UD60x18 contractSize
    ) external returns (uint256 collateralAmount, uint256 exerciseTokenAmount);

    /// @notice Returns the list of existing tokenIds with non zero balance
    /// @return tokenIds The list of existing tokenIds
    function getTokenIds() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {IProxyManager} from "../../proxy/IProxyManager.sol";

interface IOptionPSFactory is IProxyManager {
    event ProxyDeployed(address indexed base, address indexed quote, bool isCall, address proxy);

    struct OptionPSArgs {
        address base;
        address quote;
        bool isCall;
    }

    function isProxyDeployed(address proxy) external view returns (bool);

    function getProxyAddress(OptionPSArgs calldata args) external view returns (address, bool);

    function deployProxy(OptionPSArgs calldata args) external returns (address);
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {ERC165Base} from "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import {ERC1155Base} from "@solidstate/contracts/token/ERC1155/base/ERC1155Base.sol";
import {ERC1155BaseInternal} from "@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol";
import {ERC1155Enumerable} from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155Enumerable.sol";
import {ERC1155EnumerableInternal} from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155EnumerableInternal.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

import {ZERO, ONE} from "../../libraries/Constants.sol";
import {OptionMath} from "../../libraries/OptionMath.sol";

import {IOptionPS} from "./IOptionPS.sol";
import {OptionPSStorage} from "./OptionPSStorage.sol";

contract OptionPS is ERC1155Base, ERC1155Enumerable, ERC165Base, IOptionPS, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;
    using OptionPSStorage for IERC20;
    using OptionPSStorage for int128;
    using OptionPSStorage for uint256;
    using OptionPSStorage for OptionPSStorage.Layout;
    using OptionPSStorage for TokenType;
    using SafeERC20 for IERC20;

    address internal immutable FEE_RECEIVER;
    UD60x18 internal constant FEE = UD60x18.wrap(0.003e18); // 0.3%

    // @notice amount of time the exercise period lasts (in seconds)
    uint256 internal constant EXERCISE_DURATION = 7 days;

    constructor(address feeReceiver) {
        FEE_RECEIVER = feeReceiver;
    }

    function getSettings() external view returns (address base, address quote, bool isCall) {
        OptionPSStorage.Layout storage l = OptionPSStorage.layout();
        return (l.base, l.quote, l.isCall);
    }

    function getExerciseDuration() external pure returns (uint256) {
        return EXERCISE_DURATION;
    }

    /// @inheritdoc IOptionPS
    function underwrite(
        UD60x18 strike,
        uint64 maturity,
        address longReceiver,
        UD60x18 contractSize
    ) external nonReentrant {
        _revertIfOptionExpired(maturity);

        OptionPSStorage.Layout storage l = OptionPSStorage.layout();

        // Validate maturity
        if (!OptionMath.is8AMUTC(maturity)) revert OptionPS__OptionMaturityNot8UTC(maturity);

        UD60x18 strikeInterval = OptionMath.calculateStrikeInterval(strike);
        if (strike % strikeInterval != ZERO) revert OptionPS__StrikeNotMultipleOfStrikeInterval(strike, strikeInterval);

        address collateral = l.getCollateral();
        IERC20(collateral).safeTransferFrom(
            msg.sender,
            address(this),
            l.toTokenDecimals(l.isCall ? contractSize : contractSize * strike, collateral)
        );

        uint256 longTokenId = TokenType.Long.formatTokenId(maturity, strike);
        uint256 shortTokenId = TokenType.Short.formatTokenId(maturity, strike);

        _mintUD60x18(longReceiver, longTokenId, contractSize);
        _mintUD60x18(msg.sender, shortTokenId, contractSize);

        l.totalUnderwritten[strike][maturity] = l.totalUnderwritten[strike][maturity] + contractSize;

        emit Underwrite(msg.sender, longReceiver, strike, maturity, contractSize);
    }

    /// @inheritdoc IOptionPS
    function annihilate(UD60x18 strike, uint64 maturity, UD60x18 contractSize) external nonReentrant {
        _revertIfExercisePeriodEnded(maturity);

        uint256 longTokenId = TokenType.Long.formatTokenId(maturity, strike);
        uint256 shortTokenId = TokenType.Short.formatTokenId(maturity, strike);

        OptionPSStorage.Layout storage l = OptionPSStorage.layout();
        l.totalUnderwritten[strike][maturity] = l.totalUnderwritten[strike][maturity] - contractSize;

        _burnUD60x18(msg.sender, longTokenId, contractSize);
        _burnUD60x18(msg.sender, shortTokenId, contractSize);

        address collateral = l.getCollateral();
        IERC20(collateral).safeTransfer(
            msg.sender,
            l.toTokenDecimals(l.isCall ? contractSize : contractSize * strike, collateral)
        );

        emit Annihilate(msg.sender, strike, maturity, contractSize);
    }

    /// @inheritdoc IOptionPS
    function exercise(
        UD60x18 strike,
        uint64 maturity,
        UD60x18 contractSize
    ) external nonReentrant returns (uint256 exerciseValue) {
        _revertIfOptionNotExpired(maturity);
        _revertIfExercisePeriodEnded(maturity);

        OptionPSStorage.Layout storage l = OptionPSStorage.layout();
        uint256 longTokenId = TokenType.Long.formatTokenId(maturity, strike);

        UD60x18 _exerciseValue = l.isCall ? contractSize : contractSize * strike;
        UD60x18 exerciseCost = l.isCall ? contractSize * strike : contractSize;

        address collateral = l.getCollateral();
        address exerciseToken = l.getExerciseToken();

        UD60x18 fee = exerciseCost * FEE;
        IERC20(exerciseToken).safeTransferFrom(
            msg.sender,
            address(this),
            l.toTokenDecimals(exerciseCost + fee, exerciseToken)
        );
        IERC20(exerciseToken).safeTransfer(FEE_RECEIVER, l.toTokenDecimals(fee, exerciseToken));

        l.totalExercised[strike][maturity] = l.totalExercised[strike][maturity] + contractSize;

        _burnUD60x18(msg.sender, longTokenId, contractSize);
        exerciseValue = l.toTokenDecimals(_exerciseValue, collateral);
        IERC20(collateral).safeTransfer(msg.sender, exerciseValue);

        emit Exercise(msg.sender, strike, maturity, contractSize, _exerciseValue, exerciseCost, fee);
    }

    /// @inheritdoc IOptionPS
    function settle(
        UD60x18 strike,
        uint64 maturity,
        UD60x18 contractSize
    ) external nonReentrant returns (uint256 collateralAmount, uint256 exerciseTokenAmount) {
        _revertIfOptionNotExpired(maturity);
        _revertIfExercisePeriodNotEnded(maturity);

        {
            uint256 shortTokenId = TokenType.Short.formatTokenId(maturity, strike);
            _burnUD60x18(msg.sender, shortTokenId, contractSize);
        }

        OptionPSStorage.Layout storage l = OptionPSStorage.layout();

        UD60x18 _collateralAmount;
        UD60x18 _exerciseTokenAmount;

        {
            UD60x18 totalUnderwritten = l.totalUnderwritten[strike][maturity];
            UD60x18 percentageExercised = l.totalExercised[strike][maturity] / totalUnderwritten;
            _collateralAmount = (l.isCall ? contractSize : contractSize * strike) * (ONE - percentageExercised);
            _exerciseTokenAmount = (l.isCall ? contractSize * strike : contractSize) * percentageExercised;
        }

        {
            address collateral = l.getCollateral();
            address exerciseToken = l.getExerciseToken();

            collateralAmount = l.toTokenDecimals(_collateralAmount, collateral);
            exerciseTokenAmount = l.toTokenDecimals(_exerciseTokenAmount, exerciseToken);
            IERC20(collateral).safeTransfer(msg.sender, collateralAmount);
            IERC20(exerciseToken).safeTransfer(msg.sender, exerciseTokenAmount);
        }

        emit Settle(msg.sender, contractSize, strike, maturity, _collateralAmount, _exerciseTokenAmount);
    }

    /// @inheritdoc IOptionPS
    function getTokenIds() external view returns (uint256[] memory) {
        return OptionPSStorage.layout().tokenIds.toArray();
    }

    /// @notice `_mint` wrapper, converts `UD60x18` to `uint256`
    function _mintUD60x18(address account, uint256 tokenId, UD60x18 amount) internal {
        _mint(account, tokenId, amount.unwrap(), "");
    }

    /// @notice `_burn` wrapper, converts `UD60x18` to `uint256`
    function _burnUD60x18(address account, uint256 tokenId, UD60x18 amount) internal {
        _burn(account, tokenId, amount.unwrap());
    }

    /// @notice Revert if option has expired
    function _revertIfOptionExpired(uint64 maturity) internal view {
        if (block.timestamp >= maturity) revert OptionPS__OptionExpired(maturity);
    }

    /// @notice Revert if option has not expired
    function _revertIfOptionNotExpired(uint64 maturity) internal view {
        if (block.timestamp < maturity) revert OptionPS__OptionNotExpired(maturity);
    }

    /// @notice Revert if exercise period has not ended
    function _revertIfExercisePeriodNotEnded(uint64 maturity) internal view {
        uint256 target = maturity + EXERCISE_DURATION;
        if (block.timestamp < target) revert OptionPS__ExercisePeriodNotEnded(maturity, target);
    }

    /// @notice Revert if exercise period has ended
    function _revertIfExercisePeriodEnded(uint64 maturity) internal view {
        uint256 target = maturity + EXERCISE_DURATION;
        if (block.timestamp > target) revert OptionPS__ExercisePeriodEnded(maturity, target);
    }

    /// @notice `_beforeTokenTransfer` wrapper, updates `tokenIds` set
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155BaseInternal, ERC1155EnumerableInternal) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        OptionPSStorage.Layout storage l = OptionPSStorage.layout();

        for (uint256 i; i < ids.length; i++) {
            uint256 id = ids[i];

            if (amounts[i] == 0) continue;

            if (from == address(0)) {
                l.tokenIds.add(id);
            }

            if (to == address(0) && _totalSupply(id) == 0) {
                l.tokenIds.remove(id);
            }
        }
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";

import {IOptionPSFactory} from "./IOptionPSFactory.sol";
import {OptionPSProxy} from "./OptionPSProxy.sol";
import {OptionPSFactoryStorage} from "./OptionPSFactoryStorage.sol";
import {IProxyManager} from "../../proxy/IProxyManager.sol";
import {ProxyManager} from "../../proxy/ProxyManager.sol";

contract OptionPSFactory is IOptionPSFactory, ProxyManager, ReentrancyGuard {
    using OptionPSFactoryStorage for OptionPSArgs;
    using OptionPSFactoryStorage for OptionPSFactoryStorage.Layout;

    function isProxyDeployed(address proxy) external view returns (bool) {
        return OptionPSFactoryStorage.layout().isProxyDeployed[proxy];
    }

    function getProxyAddress(OptionPSArgs calldata args) external view returns (address proxy, bool) {
        OptionPSFactoryStorage.Layout storage l = OptionPSFactoryStorage.layout();
        proxy = l.proxyByKey[args.keyHash()];
        return (proxy, l.isProxyDeployed[proxy]);
    }

    function deployProxy(OptionPSArgs calldata args) external nonReentrant returns (address proxy) {
        proxy = address(new OptionPSProxy(IProxyManager(address(this)), args.base, args.quote, args.isCall));

        OptionPSFactoryStorage.Layout storage l = OptionPSFactoryStorage.layout();

        l.proxyByKey[args.keyHash()] = proxy;
        l.isProxyDeployed[proxy] = true;

        emit ProxyDeployed(args.base, args.quote, args.isCall, proxy);
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {IOptionPSFactory} from "./IOptionPSFactory.sol";

library OptionPSFactoryStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.OptionPSFactory");

    struct Layout {
        mapping(address proxy => bool) isProxyDeployed;
        mapping(bytes32 key => address proxy) proxyByKey;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice Returns the encoded option physically settled key using `args`
    function keyHash(IOptionPSFactory.OptionPSArgs memory args) internal pure returns (bytes32) {
        return keccak256(abi.encode(args.base, args.quote, args.isCall));
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {OwnableStorage} from "@solidstate/contracts/access/ownable/OwnableStorage.sol";
import {IERC1155} from "@solidstate/contracts/interfaces/IERC1155.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {ERC165BaseInternal} from "@solidstate/contracts/introspection/ERC165/base/ERC165BaseInternal.sol";
import {Proxy} from "@solidstate/contracts/proxy/Proxy.sol";
import {IERC20Metadata} from "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";

import {IProxyManager} from "../../proxy/IProxyManager.sol";
import {OptionPSStorage} from "./OptionPSStorage.sol";

contract OptionPSProxy is Proxy, ERC165BaseInternal {
    IProxyManager private immutable MANAGER;

    constructor(IProxyManager manager, address base, address quote, bool isCall) {
        MANAGER = manager;
        OwnableStorage.layout().owner = msg.sender;

        OptionPSStorage.Layout storage l = OptionPSStorage.layout();

        l.isCall = isCall;
        l.baseDecimals = IERC20Metadata(base).decimals();
        l.quoteDecimals = IERC20Metadata(quote).decimals();

        l.base = base;
        l.quote = quote;

        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IERC1155).interfaceId, true);
    }

    /// @inheritdoc Proxy
    function _getImplementation() internal view override returns (address) {
        return MANAGER.getManagedProxyImplementation();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {SafeCast} from "@solidstate/contracts/utils/SafeCast.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

import {OptionMath} from "../../libraries/OptionMath.sol";

import {IOptionPS} from "./IOptionPS.sol";

library OptionPSStorage {
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.OptionPS");

    struct Layout {
        bool isCall;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        address base;
        address quote;
        // Total options underwritten for this strike/maturity (Annihilating options decreases this total amount, but exercise does not)
        mapping(UD60x18 strike => mapping(uint64 maturity => UD60x18 amount)) totalUnderwritten;
        // Amount of contracts exercised for this strike/maturity
        mapping(UD60x18 strike => mapping(uint64 maturity => UD60x18 amount)) totalExercised;
        EnumerableSet.UintSet tokenIds;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice Calculate ERC1155 token id for given option parameters
    function formatTokenId(
        IOptionPS.TokenType tokenType,
        uint64 maturity,
        UD60x18 strike
    ) internal pure returns (uint256 tokenId) {
        tokenId =
            (uint256(tokenType) << 248) +
            (uint256(maturity) << 128) +
            uint256(int256(fromUD60x18ToInt128(strike)));
    }

    /// @notice Derive option maturity and strike price from ERC1155 token id
    function parseTokenId(
        uint256 tokenId
    ) internal pure returns (IOptionPS.TokenType tokenType, uint64 maturity, int128 strike) {
        assembly {
            tokenType := shr(248, tokenId)
            maturity := shr(128, tokenId)
            strike := tokenId
        }
    }

    function getCollateral(Layout storage l) internal view returns (address) {
        return l.isCall ? l.base : l.quote;
    }

    function getExerciseToken(Layout storage l) internal view returns (address) {
        return l.isCall ? l.quote : l.base;
    }

    /// @notice Adjust decimals of a value with 18 decimals to match the token decimals
    function toTokenDecimals(Layout storage l, UD60x18 value, address token) internal view returns (uint256) {
        uint8 decimals = token == l.base ? l.baseDecimals : l.quoteDecimals;
        return OptionMath.scaleDecimals(value.unwrap(), 18, decimals);
    }

    /// @notice Adjust decimals of a value with token decimals to 18 decimals
    function fromTokenDecimals(Layout storage l, uint256 value, address token) internal view returns (UD60x18) {
        uint8 decimals = token == l.base ? l.baseDecimals : l.quoteDecimals;
        return ud(OptionMath.scaleDecimals(value, decimals, 18));
    }

    /// @notice Converts `UD60x18` to `int128`
    function fromUD60x18ToInt128(UD60x18 u) internal pure returns (int128) {
        return u.unwrap().toInt256().toInt128();
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

interface IOptionReward {
    error OptionReward__ClaimPeriodEnded(uint256 claimEnd);
    error OptionReward__ClaimPeriodNotEnded(uint256 claimEnd);
    error OptionReward__InvalidSettlement();
    error OptionReward__LockupNotExpired(uint256 lockupEnd);
    error OptionReward__NoBaseReserved(UD60x18 strike, uint256 maturity);
    error OptionReward__NoRedeemableLongs();
    error OptionReward__NotCallOption(address option);
    error OptionReward__UnderwriterNotAuthorized(address sender);
    error OptionReward__ExercisePeriodNotEnded(uint256 maturity, uint256 exercisePeriodEnd);
    error OptionReward__OptionNotExpired(uint256 maturity);
    error OptionReward__OptionInTheMoney(UD60x18 settlementPrice, UD60x18 strike);
    error OptionReward__OptionOutTheMoney(UD60x18 settlementPrice, UD60x18 strike);
    error OptionReward__PriceIsZero();
    error OptionReward__ZeroRewardPerContract(UD60x18 strike, uint256 maturity);

    event Underwrite(address indexed longReceiver, UD60x18 strike, uint64 maturity, UD60x18 contractSize);
    event RewardsClaimed(
        address indexed user,
        UD60x18 strike,
        uint64 maturity,
        UD60x18 contractSize,
        UD60x18 baseAmount
    );
    event RewardsNotClaimedReleased(UD60x18 strike, uint64 maturity, UD60x18 baseAmount);
    event Settled(
        UD60x18 strike,
        uint64 maturity,
        UD60x18 contractSize,
        UD60x18 intrinsicValuePerContract,
        UD60x18 maxRedeemableLongs,
        UD60x18 baseAmountPaid,
        UD60x18 baseAmountFee,
        UD60x18 quoteAmountPaid,
        UD60x18 quoteAmountFee,
        UD60x18 baseAmountReserved
    );

    struct SettleVarsInternal {
        UD60x18 intrinsicValuePerContract;
        UD60x18 rewardPerContract;
        UD60x18 totalUnderwritten;
        UD60x18 maxRedeemableLongs;
        UD60x18 baseAmountReserved;
        uint256 fee;
    }

    /// @notice Underwrite an option
    /// @param longReceiver the address that will receive the long tokens
    /// @param contractSize number of long tokens to mint (18 decimals)
    function underwrite(address longReceiver, UD60x18 contractSize) external;

    /// @notice Use expired longs to claim a percentage of expired option intrinsic value as reward,
    /// after `lockupDuration` has passed
    /// @param strike the option strike price (18 decimals)
    /// @param maturity the option maturity timestamp
    /// @return baseAmount the amount of base tokens earned as reward
    function claimRewards(UD60x18 strike, uint64 maturity) external returns (uint256 baseAmount);

    /// @notice Settle options after the exercise period has ended, reserve base tokens necessary for `claimRewards`,
    /// and transfer excess base tokens + quote tokens to `paymentSplitter`
    /// @param strike the option strike price (18 decimals)
    /// @param maturity the option maturity timestamp
    function settle(UD60x18 strike, uint64 maturity) external;

    /// @notice Releases base tokens reserved for `claimRewards`,
    /// if rewards have not be claimed at `maturity + lockupDuration + claimDuration`
    /// @param strike the option strike price (18 decimals)
    /// @param maturity the option maturity timestamp
    function releaseRewardsNotClaimed(UD60x18 strike, uint64 maturity) external;

    /// @notice Returns the amount of base tokens reserved for `claimRewards`
    function getTotalBaseReserved() external view returns (uint256);

    /// @notice Returns the max amount of expired longs that a user can use to claim rewards for a given option
    function getRedeemableLongs(address user, UD60x18 strike, uint64 maturity) external view returns (UD60x18);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {IOptionPS} from "../optionPS/IOptionPS.sol";
import {IProxyManager} from "../../proxy/IProxyManager.sol";

interface IOptionRewardFactory is IProxyManager {
    event ProxyDeployed(
        IOptionPS indexed option,
        address oracleAdapter,
        address paymentSplitter,
        UD60x18 discount,
        UD60x18 penalty,
        uint256 optionDuration,
        uint256 lockupDuration,
        uint256 claimDuration,
        address proxy
    );

    struct OptionRewardArgs {
        IOptionPS option;
        address oracleAdapter;
        address paymentSplitter;
        UD60x18 discount;
        UD60x18 penalty;
        uint256 optionDuration;
        uint256 lockupDuration;
        uint256 claimDuration;
    }

    function isProxyDeployed(address proxy) external view returns (bool);

    function getProxyAddress(OptionRewardArgs calldata args) external view returns (address, bool);

    function deployProxy(OptionRewardArgs calldata args) external returns (address);
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import {SafeCast} from "@solidstate/contracts/utils/SafeCast.sol";

import {ZERO, ONE} from "../../libraries/Constants.sol";
import {OptionMath} from "../../libraries/OptionMath.sol";
import {PRBMathExtra} from "../../libraries/PRBMathExtra.sol";

import {IOracleAdapter} from "../../adapter/IOracleAdapter.sol";

import {IOptionPS} from "../optionPS/IOptionPS.sol";
import {OptionPSStorage} from "../optionPS/OptionPSStorage.sol";

import {IOptionReward} from "./IOptionReward.sol";
import {OptionRewardStorage} from "./OptionRewardStorage.sol";
import {IPaymentSplitter} from "../IPaymentSplitter.sol";

contract OptionReward is IOptionReward, ReentrancyGuard {
    using OptionRewardStorage for IERC20;
    using OptionRewardStorage for int128;
    using OptionRewardStorage for uint256;
    using OptionRewardStorage for OptionRewardStorage.Layout;
    using OptionPSStorage for IOptionPS.TokenType;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    address internal constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    address public immutable FEE_RECEIVER;
    UD60x18 public immutable FEE;

    constructor(address feeReceiver, UD60x18 fee) {
        FEE_RECEIVER = feeReceiver;
        FEE = fee;
    }

    /// @inheritdoc IOptionReward
    function underwrite(address longReceiver, UD60x18 contractSize) external nonReentrant {
        OptionRewardStorage.Layout storage l = OptionRewardStorage.layout();

        uint256 collateral = l.toTokenDecimals(contractSize, true);
        IERC20(l.base).safeTransferFrom(msg.sender, address(this), collateral);
        IERC20(l.base).approve(address(l.option), collateral);

        // Calculates the maturity starting from the 8AM UTC timestamp of the current day
        uint64 maturity = (block.timestamp - (block.timestamp % 24 hours) + 8 hours + l.optionDuration).toUint64();

        UD60x18 price = IOracleAdapter(l.oracleAdapter).getPrice(l.base, l.quote);
        _revertIfPriceIsZero(price);

        UD60x18 strike = OptionMath.roundToStrikeInterval(price * l.discount);

        l.redeemableLongs[longReceiver][strike][maturity] =
            l.redeemableLongs[longReceiver][strike][maturity] +
            contractSize;
        l.totalUnderwritten[strike][maturity] = l.totalUnderwritten[strike][maturity] + contractSize;
        l.option.underwrite(strike, maturity, longReceiver, contractSize);

        emit Underwrite(longReceiver, strike, maturity, contractSize);
    }

    /// @inheritdoc IOptionReward
    function claimRewards(UD60x18 strike, uint64 maturity) external nonReentrant returns (uint256 baseAmount) {
        _revertIfLockPeriodNotEnded(maturity);
        _revertIfClaimPeriodEnded(maturity);

        OptionRewardStorage.Layout storage l = OptionRewardStorage.layout();

        UD60x18 redeemableLongs = l.redeemableLongs[msg.sender][strike][maturity];
        if (redeemableLongs == ZERO) revert OptionReward__NoRedeemableLongs();

        UD60x18 rewardPerContract = l.rewardPerContract[strike][maturity];
        if (rewardPerContract == ZERO) revert OptionReward__ZeroRewardPerContract(strike, maturity);

        uint256 longTokenId = IOptionPS.TokenType.Long.formatTokenId(maturity, strike);
        UD60x18 contractSize = ud(l.option.balanceOf(msg.sender, longTokenId));
        if (contractSize > redeemableLongs) {
            contractSize = redeemableLongs;
        }

        // Burn the longs of the users
        l.option.safeTransferFrom(msg.sender, BURN_ADDRESS, longTokenId, contractSize.unwrap(), "");
        l.redeemableLongs[msg.sender][strike][maturity] = redeemableLongs - contractSize;

        UD60x18 _baseAmount = rewardPerContract * contractSize;
        baseAmount = l.toTokenDecimals(_baseAmount, true);
        l.totalBaseReserved -= baseAmount;
        l.baseReserved[strike][maturity] -= baseAmount;

        IERC20(l.base).safeTransfer(msg.sender, baseAmount);

        emit RewardsClaimed(msg.sender, strike, maturity, contractSize, _baseAmount);
    }

    /// @inheritdoc IOptionReward
    function releaseRewardsNotClaimed(UD60x18 strike, uint64 maturity) external nonReentrant {
        _revertIfClaimPeriodNotEnded(maturity);

        OptionRewardStorage.Layout storage l = OptionRewardStorage.layout();
        uint256 baseReserved = l.baseReserved[strike][maturity];

        if (baseReserved == 0) revert OptionReward__NoBaseReserved(strike, maturity);

        l.totalBaseReserved -= baseReserved;
        delete l.baseReserved[strike][maturity];

        IERC20(l.base).approve(l.paymentSplitter, baseReserved);
        IPaymentSplitter(l.paymentSplitter).pay(baseReserved, 0);

        emit RewardsNotClaimedReleased(strike, maturity, l.fromTokenDecimals(baseReserved, true));
    }

    /// @inheritdoc IOptionReward
    function settle(UD60x18 strike, uint64 maturity) external nonReentrant {
        OptionRewardStorage.Layout storage l = OptionRewardStorage.layout();
        _revertIfExercisePeriodNotEnded(l, maturity);

        SettleVarsInternal memory vars;

        {
            UD60x18 price = IOracleAdapter(l.oracleAdapter).getPriceAt(l.base, l.quote, maturity);
            _revertIfPriceIsZero(price);
            vars.intrinsicValuePerContract = strike > price ? ZERO : (price - strike) / price;
            vars.rewardPerContract = vars.intrinsicValuePerContract * (ONE - l.penalty);
            l.rewardPerContract[strike][maturity] = vars.rewardPerContract;
        }

        // We rely on `totalUnderwritten` rather than short balance, so that `settle` cant be call multiple times for
        // a same strike/maturity, by transferring shorts to it after a `settle` call
        vars.totalUnderwritten = l.totalUnderwritten[strike][maturity];
        if (vars.totalUnderwritten == ZERO) revert OptionReward__InvalidSettlement();
        l.totalUnderwritten[strike][maturity] = ZERO;

        {
            uint256 longTokenId = IOptionPS.TokenType.Long.formatTokenId(maturity, strike);
            UD60x18 longTotalSupply = ud(l.option.totalSupply(longTokenId));

            // Calculate the max amount of contracts for which the `claimRewards` can be called after the lockup period
            vars.maxRedeemableLongs = PRBMathExtra.min(vars.totalUnderwritten, longTotalSupply);
        }

        (, uint256 quoteAmount) = l.option.settle(strike, maturity, vars.totalUnderwritten);

        vars.fee = l.toTokenDecimals(l.fromTokenDecimals(quoteAmount, false) * FEE, false);
        IERC20(l.quote).safeTransfer(FEE_RECEIVER, vars.fee);
        IERC20(l.quote).approve(l.paymentSplitter, quoteAmount - vars.fee);

        // There is a possible scenario where, if other underwriters have underwritten the same strike/maturity,
        // directly on optionPS, and most of the long holders who purchased from other holder exercised, that settlement
        // would not return enough `base` tokens to cover the required amount that needs to be reserved,
        // and will return excess `quote` tokens instead.
        //
        // Though, this should be unlikely to happen in most case, as we are only reserving a percentage of the
        // intrinsic value of the option.
        // If this happens though, some excess `base` tokens from future settlements will be used to fill the
        // missing reserve amount.
        // As there is a lockup duration before tokens can be claimed, this should not be an issue, as there should be
        // more than enough time for any missing amount to be covered through excess `base` of future settlements.
        // Though if there was still for some reason a shortage of `base` tokens, we could transfer some `base` tokens
        // from liquidity mining fund to cover the missing amount.
        vars.baseAmountReserved = vars.maxRedeemableLongs * vars.rewardPerContract;
        l.totalBaseReserved = l.totalBaseReserved + l.toTokenDecimals(vars.baseAmountReserved, true);
        l.baseReserved[strike][maturity] = l.toTokenDecimals(vars.baseAmountReserved, true);

        uint256 baseAmountToPay;
        {
            uint256 baseBalance = IERC20(l.base).balanceOf(address(this));
            if (baseBalance > l.totalBaseReserved) {
                baseAmountToPay = baseBalance - l.totalBaseReserved;
            }
        }
        IERC20(l.base).approve(l.paymentSplitter, baseAmountToPay);

        IPaymentSplitter(l.paymentSplitter).pay(baseAmountToPay, quoteAmount - vars.fee);

        emit Settled(
            strike,
            maturity,
            vars.totalUnderwritten,
            vars.intrinsicValuePerContract,
            vars.maxRedeemableLongs,
            l.fromTokenDecimals(baseAmountToPay, true),
            ud(0),
            l.fromTokenDecimals(quoteAmount - vars.fee, false),
            l.fromTokenDecimals(vars.fee, false),
            vars.baseAmountReserved
        );
    }

    /// @inheritdoc IOptionReward
    function getTotalBaseReserved() external view returns (uint256) {
        return OptionRewardStorage.layout().totalBaseReserved;
    }

    /// @inheritdoc IOptionReward
    function getRedeemableLongs(address user, UD60x18 strike, uint64 maturity) external view returns (UD60x18) {
        return OptionRewardStorage.layout().redeemableLongs[user][strike][maturity];
    }

    /// @notice Revert if price is zero
    function _revertIfPriceIsZero(UD60x18 price) internal pure {
        if (price == ZERO) revert OptionReward__PriceIsZero();
    }

    /// @notice Revert if exercise period has not ended
    function _revertIfLockPeriodNotEnded(uint64 maturity) internal view {
        OptionRewardStorage.Layout storage l = OptionRewardStorage.layout();
        if (block.timestamp < maturity + l.lockupDuration)
            revert OptionReward__LockupNotExpired(maturity + l.lockupDuration);
    }

    /// @notice Revert if exercise period has not ended
    function _revertIfClaimPeriodEnded(uint64 maturity) internal view {
        OptionRewardStorage.Layout storage l = OptionRewardStorage.layout();
        if (block.timestamp > maturity + l.lockupDuration + l.claimDuration)
            revert OptionReward__ClaimPeriodEnded(maturity + l.lockupDuration + l.claimDuration);
    }

    /// @notice Revert if exercise period has not ended
    function _revertIfClaimPeriodNotEnded(uint64 maturity) internal view {
        OptionRewardStorage.Layout storage l = OptionRewardStorage.layout();
        if (block.timestamp < maturity + l.lockupDuration + l.claimDuration)
            revert OptionReward__ClaimPeriodNotEnded(maturity + l.lockupDuration + l.claimDuration);
    }

    /// @notice Revert if exercise period has not ended
    function _revertIfExercisePeriodNotEnded(OptionRewardStorage.Layout storage l, uint64 maturity) internal view {
        uint256 target = maturity + l.option.getExerciseDuration();
        if (block.timestamp < target) revert OptionReward__ExercisePeriodNotEnded(maturity, target);
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";

import {IOptionRewardFactory} from "./IOptionRewardFactory.sol";
import {OptionRewardProxy} from "./OptionRewardProxy.sol";
import {OptionRewardFactoryStorage} from "./OptionRewardFactoryStorage.sol";

import {IProxyManager} from "../../proxy/IProxyManager.sol";
import {ProxyManager} from "../../proxy/ProxyManager.sol";

contract OptionRewardFactory is IOptionRewardFactory, ProxyManager, ReentrancyGuard {
    using OptionRewardFactoryStorage for OptionRewardArgs;
    using OptionRewardFactoryStorage for OptionRewardFactoryStorage.Layout;

    function isProxyDeployed(address proxy) external view returns (bool) {
        return OptionRewardFactoryStorage.layout().isProxyDeployed[proxy];
    }

    function getProxyAddress(OptionRewardArgs calldata args) external view returns (address proxy, bool) {
        OptionRewardFactoryStorage.Layout storage l = OptionRewardFactoryStorage.layout();
        proxy = l.proxyByKey[args.keyHash()];
        return (proxy, l.isProxyDeployed[proxy]);
    }

    function deployProxy(OptionRewardArgs calldata args) external nonReentrant returns (address proxy) {
        proxy = address(
            new OptionRewardProxy(
                IProxyManager(address(this)),
                args.option,
                args.oracleAdapter,
                args.paymentSplitter,
                args.discount,
                args.penalty,
                args.optionDuration,
                args.lockupDuration,
                args.claimDuration
            )
        );

        OptionRewardFactoryStorage.Layout storage l = OptionRewardFactoryStorage.layout();

        l.proxyByKey[args.keyHash()] = proxy;
        l.isProxyDeployed[proxy] = true;

        emit ProxyDeployed(
            args.option,
            args.oracleAdapter,
            args.paymentSplitter,
            args.discount,
            args.penalty,
            args.optionDuration,
            args.lockupDuration,
            args.claimDuration,
            proxy
        );
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {IOptionRewardFactory} from "./IOptionRewardFactory.sol";

library OptionRewardFactoryStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.OptionRewardFactory");

    struct Layout {
        mapping(address proxy => bool) isProxyDeployed;
        mapping(bytes32 key => address proxy) proxyByKey;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice Returns the encoded option reward key using `args`
    function keyHash(IOptionRewardFactory.OptionRewardArgs memory args) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    args.option,
                    args.oracleAdapter,
                    args.paymentSplitter,
                    args.discount,
                    args.penalty,
                    args.optionDuration,
                    args.lockupDuration,
                    args.claimDuration
                )
            );
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {OwnableStorage} from "@solidstate/contracts/access/ownable/OwnableStorage.sol";
import {Proxy} from "@solidstate/contracts/proxy/Proxy.sol";
import {IERC20Metadata} from "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";

import {IProxyManager} from "../../proxy/IProxyManager.sol";
import {OptionRewardStorage} from "./OptionRewardStorage.sol";
import {IOptionReward} from "./IOptionReward.sol";
import {IOptionPS} from "../optionPS/IOptionPS.sol";

contract OptionRewardProxy is Proxy {
    IProxyManager private immutable MANAGER;

    constructor(
        IProxyManager manager,
        IOptionPS option,
        address oracleAdapter,
        address paymentSplitter,
        UD60x18 discount,
        UD60x18 penalty,
        uint256 optionDuration,
        uint256 lockupDuration,
        uint256 claimDuration
    ) {
        MANAGER = manager;
        OwnableStorage.layout().owner = msg.sender;

        OptionRewardStorage.Layout storage l = OptionRewardStorage.layout();

        l.option = option;

        (address base, address quote, bool isCall) = option.getSettings();
        if (!isCall) revert IOptionReward.OptionReward__NotCallOption(address(option));

        l.base = base;
        l.quote = quote;

        l.baseDecimals = IERC20Metadata(base).decimals();
        l.quoteDecimals = IERC20Metadata(quote).decimals();

        l.optionDuration = optionDuration;
        l.oracleAdapter = oracleAdapter;
        l.paymentSplitter = paymentSplitter;

        l.discount = discount;
        l.penalty = penalty;
        l.lockupDuration = lockupDuration;
        l.claimDuration = claimDuration;
    }

    /// @inheritdoc Proxy
    function _getImplementation() internal view override returns (address) {
        return MANAGER.getManagedProxyImplementation();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {SafeCast} from "@solidstate/contracts/utils/SafeCast.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";

import {OptionMath} from "../../libraries/OptionMath.sol";

import {IOptionPS} from "../optionPS/IOptionPS.sol";

library OptionRewardStorage {
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.OptionReward");

    struct Layout {
        IOptionPS option;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        address base;
        address quote;
        address oracleAdapter;
        address paymentSplitter;
        // percentage of the asset spot price used to set the strike price
        UD60x18 discount;
        // percentage of the intrinsic value that is reduced after lockup period (ie 80% penalty (0.80e18), means the
        // long holder receives 20% of the options intrinsic value, the remaining collateral is refunded).
        UD60x18 penalty;
        // amount of time the underwritten options should last (in seconds)
        uint256 optionDuration;
        // amount of time the lockup period lasts (in seconds)
        uint256 lockupDuration;
        // amount of time during which rewards can be claimed after the lockup period
        uint256 claimDuration;
        // Total amount of contracts for which the user can trade longs against % of intrinsic value after the lockupDuration
        mapping(address user => mapping(UD60x18 strike => mapping(uint64 maturity => UD60x18 amount))) redeemableLongs;
        // Total amount of contracts underwritten for this strike/maturity
        mapping(UD60x18 strike => mapping(uint64 maturity => UD60x18 amount)) totalUnderwritten;
        // Intrinsic value per contract claimable after lockup period
        mapping(UD60x18 strike => mapping(uint64 maturity => UD60x18 amount)) rewardPerContract;
        // Total amount of base tokens (not yet claimed) and reserved as locked rewards for users
        uint256 totalBaseReserved;
        // Amount of base tokens reserved for a strike/maturity
        mapping(UD60x18 strike => mapping(uint64 maturity => uint256 amount)) baseReserved;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice Adjust decimals of a value with 18 decimals to match the token decimals
    function toTokenDecimals(Layout storage l, UD60x18 value, bool isBase) internal view returns (uint256) {
        uint8 decimals = isBase ? l.baseDecimals : l.quoteDecimals;
        return OptionMath.scaleDecimals(value.unwrap(), 18, decimals);
    }

    /// @notice Adjust decimals of a value with token decimals to 18 decimals
    function fromTokenDecimals(Layout storage l, uint256 value, bool isBase) internal view returns (UD60x18) {
        uint8 decimals = isBase ? l.baseDecimals : l.quoteDecimals;
        return ud(OptionMath.scaleDecimals(value, decimals, 18));
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";

import {IVxPremia} from "../staking/IVxPremia.sol";

import {IPaymentSplitter} from "./IPaymentSplitter.sol";
import {IMiningAddRewards} from "./IMiningAddRewards.sol";

contract PaymentSplitter is IPaymentSplitter, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable PREMIA;
    IERC20 public immutable USDC;
    IVxPremia public immutable VX_PREMIA;
    IMiningAddRewards public immutable MINING;

    constructor(IERC20 premia, IERC20 usdc, IVxPremia vxPremia, IMiningAddRewards mining) {
        PREMIA = premia;
        USDC = usdc;
        VX_PREMIA = vxPremia;
        MINING = mining;
    }

    /// @notice Distributes rewards to vxPREMIA staking contract, and send back PREMIA leftover to mining contract
    /// @param premiaAmount Amount of PREMIA to send back to mining contract
    /// @param usdcAmount Amount of USDC to send to vxPREMIA staking contract
    function pay(uint256 premiaAmount, uint256 usdcAmount) external nonReentrant {
        if (premiaAmount > 0) {
            PREMIA.safeTransferFrom(msg.sender, address(this), premiaAmount);
            PREMIA.approve(address(MINING), premiaAmount);
            MINING.addRewards(premiaAmount);
        }

        if (usdcAmount > 0) {
            USDC.safeTransferFrom(msg.sender, address(this), usdcAmount);
            USDC.approve(address(VX_PREMIA), usdcAmount);
            VX_PREMIA.addRewards(usdcAmount);
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

interface IVaultMining {
    error VaultMining__NotVault(address caller);

    event Claim(address indexed user, address indexed vault, UD60x18 rewardAmount);

    event UpdateVaultVotes(address indexed vault, UD60x18 votes, UD60x18 vaultUtilisationRate);

    event SetRewardsPerYear(UD60x18 rewardsPerYear);

    //

    struct VaultInfo {
        // Total shares for this vault
        UD60x18 totalShares;
        // Amount of votes for this vault
        UD60x18 votes;
        // Last timestamp at which distribution occurred
        uint256 lastRewardTimestamp;
        // Accumulated rewards per share
        UD60x18 accRewardsPerShare;
    }

    struct UserInfo {
        // User shares
        UD60x18 shares;
        // Total allocated unclaimed rewards
        UD60x18 reward;
        // Reward debt. See explanation below
        UD60x18 rewardDebt;
        //   pending reward = (user.shares * vault.accPremiaPerShare) - user.rewardDebt
        //
        // Whenever a user vault shares change. Here's what happens:
        //   1. The vault's `accPremiaPerShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User allocated `reward` is updated
        //   3. User's `shares` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    struct VaultVotes {
        address vault;
        UD60x18 votes;
        UD60x18 vaultUtilisationRate;
    }

    /// @notice Add rewards to the contract
    function addRewards(UD60x18 amount) external;

    /// @notice Return amount of rewards not yet allocated
    function getRewardsAvailable() external view returns (UD60x18);

    /// @notice Return amount of pending rewards (not yet claimed) for a user, on a specific vault
    function getPendingUserRewards(address user, address vault) external view returns (UD60x18);

    /// @notice Return the total amount of votes across all vaults (Used to calculate share of rewards allocation for each vault)
    function getTotalVotes() external view returns (UD60x18);

    /// @notice Return internal variables for a vault
    function getVaultInfo(address vault) external view returns (VaultInfo memory);

    /// @notice Return internal variables for a user, on a specific vault
    function getUserInfo(address user, address vault) external view returns (UserInfo memory);

    /// @notice Get the amount of rewards emitted per year
    function getRewardsPerYear() external view returns (UD60x18);

    /// @notice Claim rewards for a list of vaults
    function claim(address[] memory vaults) external;

    /// @notice Trigger an update for a user on a specific vault
    /// This needs to be called by the vault, anytime the user's shares change
    /// Can only be called by a vault registered on the VaultRegistry
    /// @param user The user to update
    /// @param vault The vault for which to update
    /// @param newUserShares The new amount of shares for the user
    /// @param newTotalShares The new amount of total shares for the vault
    /// @param utilisationRate The new utilisation rate for the vault
    function updateUser(
        address user,
        address vault,
        UD60x18 newUserShares,
        UD60x18 newTotalShares,
        UD60x18 utilisationRate
    ) external;

    /// @notice Trigger an update for a vault
    function updateVault(address vault) external;

    /// @notice Trigger an update for all vaults
    function updateVaults() external;

    /// @notice Trigger an update for a user on a specific vault
    function updateUser(address user, address vault) external;
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";

import {WAD, ZERO} from "../../libraries/Constants.sol";

import {IOptionReward} from "../optionReward/IOptionReward.sol";

import {IVaultMining} from "./IVaultMining.sol";
import {VaultMiningStorage} from "./VaultMiningStorage.sol";
import {IVxPremia} from "../../staking/IVxPremia.sol";
import {IVault} from "../../vault/IVault.sol";
import {IVaultRegistry} from "../../vault/IVaultRegistry.sol";

contract VaultMining is IVaultMining, OwnableInternal, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using VaultMiningStorage for VaultMiningStorage.Layout;

    /// @notice Address of the vault registry
    address internal immutable VAULT_REGISTRY;
    /// @notice Address of the PREMIA token
    address internal immutable PREMIA;
    /// @notice Address of the vxPremia token
    address internal immutable VX_PREMIA;
    /// @notice Address of the PREMIA physically settled options
    address internal immutable OPTION_REWARD;

    /// @notice If utilisation rate is less than this value, we use this value instead as a multiplier on allocation points
    UD60x18 private constant MIN_POINTS_MULTIPLIER = UD60x18.wrap(0.25e18);

    constructor(address vaultRegistry, address premia, address vxPremia, address optionReward) {
        VAULT_REGISTRY = vaultRegistry;
        PREMIA = premia;
        VX_PREMIA = vxPremia;
        OPTION_REWARD = optionReward;
    }

    /// @inheritdoc IVaultMining
    function addRewards(UD60x18 amount) external nonReentrant {
        VaultMiningStorage.Layout storage l = VaultMiningStorage.layout();
        IERC20(PREMIA).safeTransferFrom(msg.sender, address(this), amount.unwrap());
        l.rewardsAvailable = l.rewardsAvailable + amount;
    }

    function getRewardsAvailable() external view returns (UD60x18) {
        return VaultMiningStorage.layout().rewardsAvailable;
    }

    /// @inheritdoc IVaultMining
    function getPendingUserRewards(address user, address vault) external view returns (UD60x18) {
        VaultMiningStorage.Layout storage l = VaultMiningStorage.layout();
        VaultInfo storage vInfo = l.vaultInfo[vault];
        UserInfo storage uInfo = l.userInfo[vault][user];

        UD60x18 accRewardsPerShare = vInfo.accRewardsPerShare;
        if (block.timestamp > vInfo.lastRewardTimestamp && vInfo.votes > ZERO && vInfo.totalShares > ZERO) {
            UD60x18 rewardsAmount = _calculateRewardsUpdate(l, vInfo.lastRewardTimestamp, vInfo.votes);
            accRewardsPerShare = accRewardsPerShare + (rewardsAmount / vInfo.totalShares);
        }

        return (uInfo.shares * accRewardsPerShare) - uInfo.rewardDebt + uInfo.reward;
    }

    function _calculateRewardsUpdate(
        VaultMiningStorage.Layout storage l,
        uint256 lastVaultRewardTimestamp,
        UD60x18 vaultVotes
    ) internal view returns (UD60x18 rewardAmount) {
        UD60x18 yearsElapsed = ud((block.timestamp - lastVaultRewardTimestamp) * WAD) / ud(365 days * WAD);
        rewardAmount = (yearsElapsed * l.rewardsPerYear * vaultVotes) / l.totalVotes;

        // If we are running out of rewards to distribute, distribute whats left
        if (rewardAmount > l.rewardsAvailable) {
            rewardAmount = l.rewardsAvailable;
        }
    }

    /// @inheritdoc IVaultMining
    function getTotalVotes() external view returns (UD60x18) {
        return VaultMiningStorage.layout().totalVotes;
    }

    /// @inheritdoc IVaultMining
    function getVaultInfo(address vault) external view returns (VaultInfo memory) {
        return VaultMiningStorage.layout().vaultInfo[vault];
    }

    /// @inheritdoc IVaultMining
    function getUserInfo(address user, address vault) external view returns (UserInfo memory) {
        return VaultMiningStorage.layout().userInfo[vault][user];
    }

    /// @inheritdoc IVaultMining
    function getRewardsPerYear() external view returns (UD60x18) {
        return VaultMiningStorage.layout().rewardsPerYear;
    }

    function setRewardsPerYear(UD60x18 rewardsPerYear) external onlyOwner {
        updateVaults();

        VaultMiningStorage.layout().rewardsPerYear = rewardsPerYear;
        emit SetRewardsPerYear(rewardsPerYear);
    }

    /// @inheritdoc IVaultMining
    function claim(address[] memory vaults) external nonReentrant {
        VaultMiningStorage.Layout storage l = VaultMiningStorage.layout();

        UD60x18 size;
        for (uint256 i = 0; i < vaults.length; i++) {
            _updateUser(msg.sender, vaults[i]);

            UD60x18 rewardAmount = l.userInfo[vaults[i]][msg.sender].reward;
            size = size + rewardAmount;
            l.userInfo[vaults[i]][msg.sender].reward = ZERO;

            emit Claim(msg.sender, vaults[i], rewardAmount);
        }

        IERC20(PREMIA).approve(OPTION_REWARD, size.unwrap());
        IOptionReward(OPTION_REWARD).underwrite(msg.sender, size);
    }

    function updateVaults() public nonReentrant {
        IVaultRegistry.Vault[] memory vaults = IVaultRegistry(VAULT_REGISTRY).getVaults();

        for (uint256 i = 0; i < vaults.length; i++) {
            IVault vault = IVault(vaults[i].vault);
            _updateVault(vaults[i].vault, ud(vault.totalSupply()), vault.getUtilisation());
        }
    }

    /// @inheritdoc IVaultMining
    function updateUser(
        address user,
        address vault,
        UD60x18 newUserShares,
        UD60x18 newTotalShares,
        UD60x18 utilisationRate
    ) external nonReentrant {
        _revertIfNotVault(msg.sender);
        _revertIfNotVault(vault);
        _updateUser(user, vault, newUserShares, newTotalShares, utilisationRate);
    }

    /// @inheritdoc IVaultMining
    function updateVault(address vault) external nonReentrant {
        _revertIfNotVault(vault);

        IVault _vault = IVault(vault);
        _updateVault(vault, ud(_vault.totalSupply()), _vault.getUtilisation());
    }

    function _updateVault(address vault, UD60x18 newTotalShares, UD60x18 utilisationRate) internal {
        VaultMiningStorage.Layout storage l = VaultMiningStorage.layout();
        VaultInfo storage vInfo = l.vaultInfo[vault];

        if (block.timestamp > vInfo.lastRewardTimestamp) {
            if (vInfo.totalShares > ZERO && vInfo.votes > ZERO) {
                UD60x18 rewardAmount = _calculateRewardsUpdate(l, vInfo.lastRewardTimestamp, vInfo.votes);
                l.rewardsAvailable = l.rewardsAvailable - rewardAmount;
                vInfo.accRewardsPerShare = vInfo.accRewardsPerShare + (rewardAmount / vInfo.totalShares);
            }

            vInfo.lastRewardTimestamp = block.timestamp;
        }

        vInfo.totalShares = newTotalShares;

        _updateVaultAllocation(l, vault, utilisationRate);
    }

    /// @inheritdoc IVaultMining
    function updateUser(address user, address vault) external nonReentrant {
        _updateUser(user, vault);
    }

    function _updateUser(address user, address vault) internal {
        _revertIfNotVault(vault);

        IVault _vault = IVault(vault);
        _updateUser(user, vault, ud(_vault.balanceOf(user)), ud(_vault.totalSupply()), _vault.getUtilisation());
    }

    function _updateUser(
        address user,
        address vault,
        UD60x18 newUserShares,
        UD60x18 newTotalShares,
        UD60x18 utilisationRate
    ) internal {
        VaultMiningStorage.Layout storage l = VaultMiningStorage.layout();
        VaultInfo storage vInfo = l.vaultInfo[vault];
        UserInfo storage uInfo = l.userInfo[vault][user];

        _updateVault(vault, newTotalShares, utilisationRate);

        uInfo.reward = uInfo.reward + (uInfo.shares * vInfo.accRewardsPerShare) - uInfo.rewardDebt;
        uInfo.rewardDebt = newUserShares * vInfo.accRewardsPerShare;

        if (uInfo.shares != newUserShares) {
            uInfo.shares = newUserShares;
        }
    }

    function _updateVaultAllocation(
        VaultMiningStorage.Layout storage l,
        address vault,
        UD60x18 utilisationRate
    ) internal virtual {
        uint256 votes = IVxPremia(VX_PREMIA).getPoolVotes(IVxPremia.VoteVersion.VaultV3, abi.encodePacked(vault));
        _setVaultVotes(l, VaultVotes({vault: vault, votes: ud(votes), vaultUtilisationRate: utilisationRate}));
    }

    function _setVaultVotes(VaultMiningStorage.Layout storage l, VaultVotes memory data) internal {
        if (data.vaultUtilisationRate < MIN_POINTS_MULTIPLIER) {
            data.vaultUtilisationRate = MIN_POINTS_MULTIPLIER;
        }

        UD60x18 adjustedVotes = data.votes * data.vaultUtilisationRate;

        l.totalVotes = l.totalVotes - l.vaultInfo[data.vault].votes + adjustedVotes;
        l.vaultInfo[data.vault].votes = adjustedVotes;

        // If alloc points set for a new vault, we initialize the last reward timestamp
        if (l.vaultInfo[data.vault].lastRewardTimestamp == 0) {
            l.vaultInfo[data.vault].lastRewardTimestamp = block.timestamp;
        }

        emit UpdateVaultVotes(data.vault, data.votes, data.vaultUtilisationRate);
    }

    function _revertIfNotVault(address caller) internal view {
        if (IVaultRegistry(VAULT_REGISTRY).isVault(caller) == false) revert VaultMining__NotVault(caller);
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {VaultMiningStorage} from "./VaultMiningStorage.sol";
import {ProxyUpgradeableOwnable} from "../../proxy/ProxyUpgradeableOwnable.sol";

contract VaultMiningProxy is ProxyUpgradeableOwnable {
    constructor(address implementation, UD60x18 rewardsPerYear) ProxyUpgradeableOwnable(implementation) {
        VaultMiningStorage.layout().rewardsPerYear = rewardsPerYear;
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {IVaultMining} from "./IVaultMining.sol";

library VaultMiningStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.VaultMining");

    struct Layout {
        // Amount of rewards distributed per year
        UD60x18 rewardsPerYear;
        // Total rewards left to distribute
        UD60x18 rewardsAvailable;
        mapping(address pool => IVaultMining.VaultInfo infos) vaultInfo;
        mapping(address pool => mapping(address user => IVaultMining.UserInfo info)) userInfo;
        // Total votes across all pools
        UD60x18 totalVotes;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {VolatilityOracleStorage} from "./VolatilityOracleStorage.sol";

interface IVolatilityOracle {
    error VolatilityOracle__ArrayLengthMismatch();
    error VolatilityOracle__OutOfBounds(int256 value);
    error VolatilityOracle__SpotIsZero();
    error VolatilityOracle__StrikeIsZero();
    error VolatilityOracle__TimeToMaturityIsZero();

    event UpdateParameters(address indexed token, bytes32 tau, bytes32 theta, bytes32 psi, bytes32 rho);

    /// @notice Pack IV model parameters into a single bytes32
    /// @dev This function is used to pack the parameters into a single variable, which is then used as input in `update`
    /// @param params Parameters of IV model to pack
    /// @return result The packed parameters of IV model
    function formatParams(int256[5] calldata params) external pure returns (bytes32 result);

    /// @notice Unpack IV model parameters from a bytes32
    /// @param input Packed IV model parameters to unpack
    /// @return params The unpacked parameters of the IV model
    function parseParams(bytes32 input) external pure returns (int256[5] memory params);

    /// @notice Update a list of Anchored eSSVI model parameters
    /// @param tokens List of the base tokens
    /// @param tau List of maturities
    /// @param theta List of ATM total implied variance curves
    /// @param psi List of ATM skew curves
    /// @param rho List of rho curves
    /// @param riskFreeRate The risk-free rate
    function updateParams(
        address[] calldata tokens,
        bytes32[] calldata tau,
        bytes32[] calldata theta,
        bytes32[] calldata psi,
        bytes32[] calldata rho,
        UD60x18 riskFreeRate
    ) external;

    /// @notice Get the IV model parameters of a token pair
    /// @param token The token address
    /// @return The IV model parameters
    function getParams(address token) external view returns (VolatilityOracleStorage.Update memory);

    /// @notice Get unpacked IV model parameters
    /// @param token The token address
    /// @return The unpacked IV model parameters
    function getParamsUnpacked(address token) external view returns (VolatilityOracleStorage.Params memory);

    /// @notice Calculate the annualized volatility for given set of parameters
    /// @param token The token address
    /// @param spot The spot price of the token
    /// @param strike The strike price of the option
    /// @param timeToMaturity The time until maturity (denominated in years)
    /// @return The annualized implied volatility, where 1 is defined as 100%
    function getVolatility(
        address token,
        UD60x18 spot,
        UD60x18 strike,
        UD60x18 timeToMaturity
    ) external view returns (UD60x18);

    /// @notice Calculate the annualized volatility for given set of parameters
    /// @param token The token address
    /// @param spot The spot price of the token
    /// @param strike The strike price of the option
    /// @param timeToMaturity The time until maturity (denominated in years)
    /// @return The annualized implied volatility, where 1 is defined as 100%
    function getVolatility(
        address token,
        UD60x18 spot,
        UD60x18[] memory strike,
        UD60x18[] memory timeToMaturity
    ) external view returns (UD60x18[] memory);

    /// @notice Returns the current risk-free rate
    /// @return The current risk-free rate
    function getRiskFreeRate() external view returns (UD60x18);
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {SD59x18, sd} from "lib/prb-math/src/SD59x18.sol";

import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import {SafeCast} from "@solidstate/contracts/utils/SafeCast.sol";

import {RelayerAccessManager} from "../relayer/RelayerAccessManager.sol";

import {IVolatilityOracle} from "./IVolatilityOracle.sol";
import {VolatilityOracleStorage} from "./VolatilityOracleStorage.sol";

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {SD59x18} from "lib/prb-math/src/SD59x18.sol";

import {ZERO, iZERO, iONE, iTWO} from "../libraries/Constants.sol";
import {PRBMathExtra} from "../libraries/PRBMathExtra.sol";

/// @title Premia volatility surface oracle contract for liquid markets.
contract VolatilityOracle is IVolatilityOracle, ReentrancyGuard, RelayerAccessManager {
    using VolatilityOracleStorage for VolatilityOracleStorage.Layout;
    using SafeCast for uint256;
    using SafeCast for int256;
    using PRBMathExtra for UD60x18;
    using PRBMathExtra for SD59x18;

    uint256 private constant DECIMALS = 12;

    struct Params {
        SD59x18[5] tau;
        SD59x18[5] theta;
        SD59x18[5] psi;
        SD59x18[5] rho;
    }

    struct SliceInfo {
        SD59x18 theta;
        SD59x18 psi;
        SD59x18 rho;
    }

    /// @inheritdoc IVolatilityOracle
    function formatParams(int256[5] calldata params) external pure returns (bytes32 result) {
        return VolatilityOracleStorage.formatParams(params);
    }

    /// @inheritdoc IVolatilityOracle
    function parseParams(bytes32 input) external pure returns (int256[5] memory params) {
        return VolatilityOracleStorage.parseParams(input);
    }

    /// @inheritdoc IVolatilityOracle
    function updateParams(
        address[] calldata tokens,
        bytes32[] calldata tau,
        bytes32[] calldata theta,
        bytes32[] calldata psi,
        bytes32[] calldata rho,
        UD60x18 riskFreeRate
    ) external nonReentrant {
        _revertIfNotWhitelistedRelayer(msg.sender);

        if (
            tokens.length != tau.length ||
            tokens.length != theta.length ||
            tokens.length != psi.length ||
            tokens.length != rho.length
        ) revert IVolatilityOracle.VolatilityOracle__ArrayLengthMismatch();

        VolatilityOracleStorage.Layout storage l = VolatilityOracleStorage.layout();

        for (uint256 i = 0; i < tokens.length; i++) {
            l.parameters[tokens[i]] = VolatilityOracleStorage.Update({
                updatedAt: block.timestamp,
                tau: tau[i],
                theta: theta[i],
                psi: psi[i],
                rho: rho[i]
            });

            emit UpdateParameters(tokens[i], tau[i], theta[i], psi[i], rho[i]);
        }

        l.riskFreeRate = riskFreeRate;
    }

    /// @inheritdoc IVolatilityOracle
    function getParams(address token) external view returns (VolatilityOracleStorage.Update memory) {
        VolatilityOracleStorage.Layout storage l = VolatilityOracleStorage.layout();
        return l.parameters[token];
    }

    /// @inheritdoc IVolatilityOracle
    function getParamsUnpacked(address token) external view returns (VolatilityOracleStorage.Params memory) {
        VolatilityOracleStorage.Layout storage l = VolatilityOracleStorage.layout();
        VolatilityOracleStorage.Update memory packed = l.getParams(token);
        VolatilityOracleStorage.Params memory params = VolatilityOracleStorage.Params({
            tau: VolatilityOracleStorage.parseParams(packed.tau),
            theta: VolatilityOracleStorage.parseParams(packed.theta),
            psi: VolatilityOracleStorage.parseParams(packed.psi),
            rho: VolatilityOracleStorage.parseParams(packed.rho)
        });
        return params;
    }

    /// @notice Finds the interval a particular value is located in.
    /// @param arr The array of cutoff points that define the intervals
    /// @param value The value to find the interval for
    /// @return The interval index that corresponds the value
    function _findInterval(SD59x18[5] memory arr, SD59x18 value) internal pure returns (uint256) {
        uint256 low = 0;
        uint256 high = arr.length;
        uint256 m;
        uint256 result;

        while ((high - low) > 1) {
            m = (uint256)((low + high) / 2);

            if (arr[m] <= value) {
                low = m;
            } else {
                high = m;
            }
        }

        if (arr[low] <= value) {
            result = low;
        }

        return result;
    }

    /// @notice Convert an int256[] array to a SD59x18[] array
    /// @param src The array to be converted
    /// @return tgt The input array converted to a SD59x18[] array
    function _toArray59x18(int256[5] memory src) internal pure returns (SD59x18[5] memory tgt) {
        for (uint256 i = 0; i < src.length; i++) {
            // Convert parameters in DECIMALS to an SD59x18
            tgt[i] = sd(src[i] * 1e6);
        }
        return tgt;
    }

    function _weightedAvg(SD59x18 lam, SD59x18 value1, SD59x18 value2) internal pure returns (SD59x18) {
        return (iONE - lam) * value1 + (lam * value2);
    }

    /// @inheritdoc IVolatilityOracle
    function getVolatility(
        address token,
        UD60x18 spot,
        UD60x18 strike,
        UD60x18 timeToMaturity
    ) public view virtual returns (UD60x18) {
        if (spot == ZERO) revert VolatilityOracle__SpotIsZero();
        if (strike == ZERO) revert VolatilityOracle__StrikeIsZero();
        if (timeToMaturity == ZERO) revert VolatilityOracle__TimeToMaturityIsZero();

        VolatilityOracleStorage.Layout storage l = VolatilityOracleStorage.layout();
        VolatilityOracleStorage.Update memory packed = l.getParams(token);

        Params memory params = Params({
            tau: _toArray59x18(VolatilityOracleStorage.parseParams(packed.tau)),
            theta: _toArray59x18(VolatilityOracleStorage.parseParams(packed.theta)),
            psi: _toArray59x18(VolatilityOracleStorage.parseParams(packed.psi)),
            rho: _toArray59x18(VolatilityOracleStorage.parseParams(packed.rho))
        });

        // Number of tau
        uint256 n = params.tau.length;

        // Log Moneyness
        SD59x18 k = (strike / spot).intoSD59x18().ln();

        // Compute total implied variance
        SliceInfo memory info;
        SD59x18 lam;

        SD59x18 _timeToMaturity = timeToMaturity.intoSD59x18();

        // Short-Term Extrapolation
        if (_timeToMaturity < params.tau[0]) {
            lam = _timeToMaturity / params.tau[0];

            info = SliceInfo({theta: lam * params.theta[0], psi: lam * params.psi[0], rho: params.rho[0]});
        }
        // Long-term extrapolation
        else if (_timeToMaturity >= params.tau[n - 1]) {
            SD59x18 u = _timeToMaturity - params.tau[n - 1];
            u = u * (params.theta[n - 1] - params.theta[n - 2]);
            u = u / (params.tau[n - 1] - params.tau[n - 2]);

            info = SliceInfo({theta: params.theta[n - 1] + u, psi: params.psi[n - 1], rho: params.rho[n - 1]});
        }
        // Interpolation between tau[0] to tau[n - 1]
        else {
            uint256 i = _findInterval(params.tau, _timeToMaturity);

            lam = _timeToMaturity - params.tau[i];
            lam = lam / (params.tau[i + 1] - params.tau[i]);

            info = SliceInfo({
                theta: _weightedAvg(lam, params.theta[i], params.theta[i + 1]),
                psi: _weightedAvg(lam, params.psi[i], params.psi[i + 1]),
                rho: iZERO
            });
            info.rho =
                _weightedAvg(lam, params.rho[i] * params.psi[i], params.rho[i + 1] * params.psi[i + 1]) /
                info.psi;
        }

        SD59x18 phi = info.psi / info.theta;

        // Use powu(2) instead of pow(TWO) here (o.w. LogInputTooSmall Error)
        SD59x18 term = (phi * k + info.rho).powu(2) + (iONE - info.rho.powu(2));

        SD59x18 w = info.theta / iTWO;
        w = w * (iONE + info.rho * phi * k + term.sqrt());

        return (w / _timeToMaturity).sqrt().intoUD60x18();
    }

    // @inheritdoc IVolatilityOracle
    function getVolatility(
        address token,
        UD60x18 spot,
        UD60x18[] memory strike,
        UD60x18[] memory timeToMaturity
    ) external view virtual returns (UD60x18[] memory) {
        if (strike.length != timeToMaturity.length) revert VolatilityOracle__ArrayLengthMismatch();

        UD60x18[] memory sigma = new UD60x18[](strike.length);

        for (uint256 i = 0; i < sigma.length; i++) {
            sigma[i] = getVolatility(token, spot, strike[i], timeToMaturity[i]);
        }

        return sigma;
    }

    // @inheritdoc IVolatilityOracle
    function getRiskFreeRate() external view virtual returns (UD60x18) {
        VolatilityOracleStorage.Layout storage l = VolatilityOracleStorage.layout();
        return l.riskFreeRate;
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {IVolatilityOracle} from "./IVolatilityOracle.sol";

library VolatilityOracleStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.VolatilityOracle");

    uint256 internal constant PARAM_BITS = 51;
    uint256 internal constant PARAM_BITS_MINUS_ONE = 50;
    uint256 internal constant PARAM_AMOUNT = 5;
    // START_BIT = PARAM_BITS * (PARAM_AMOUNT - 1)
    uint256 internal constant START_BIT = 204;

    struct Update {
        uint256 updatedAt;
        bytes32 tau;
        bytes32 theta;
        bytes32 psi;
        bytes32 rho;
    }

    struct Params {
        int256[5] tau;
        int256[5] theta;
        int256[5] psi;
        int256[5] rho;
    }

    struct Layout {
        mapping(address token => Update) parameters;
        // risk-free rate
        UD60x18 riskFreeRate;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice Returns the current parameters for `token`
    function getParams(Layout storage l, address token) internal view returns (Update memory) {
        return l.parameters[token];
    }

    /// @notice Returns the parsed parameters for the encoded `input`
    function parseParams(bytes32 input) internal pure returns (int256[5] memory params) {
        // Value to add to negative numbers to cast them to int256
        int256 toAdd = (int256(-1) >> PARAM_BITS) << PARAM_BITS;

        assembly {
            let i := 0
            // Value equal to -1

            let mid := shl(PARAM_BITS_MINUS_ONE, 1)

            for {

            } lt(i, PARAM_AMOUNT) {

            } {
                let offset := sub(START_BIT, mul(PARAM_BITS, i))
                let param := shr(offset, sub(input, shl(add(offset, PARAM_BITS), shr(add(offset, PARAM_BITS), input))))

                // Check if value is a negative number and needs casting
                if or(eq(param, mid), gt(param, mid)) {
                    param := add(param, toAdd)
                }

                // Store result in the params array
                mstore(add(params, mul(0x20, i)), param)

                i := add(i, 1)
            }
        }
    }

    /// @notice Returns the encoded parameters for `params`
    function formatParams(int256[5] memory params) internal pure returns (bytes32 result) {
        int256 max = int256(1 << PARAM_BITS_MINUS_ONE);

        unchecked {
            for (uint256 i = 0; i < PARAM_AMOUNT; i++) {
                if (params[i] >= max || params[i] <= -max)
                    revert IVolatilityOracle.VolatilityOracle__OutOfBounds(params[i]);
            }
        }

        assembly {
            let i := 0

            for {

            } lt(i, PARAM_AMOUNT) {

            } {
                let offset := sub(START_BIT, mul(PARAM_BITS, i))
                let param := mload(add(params, mul(0x20, i)))

                result := add(result, shl(offset, sub(param, shl(PARAM_BITS, shr(PARAM_BITS, param)))))

                i := add(i, 1)
            }
        }
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {IPoolFactory} from "contracts/factory/IPoolFactory.sol";

contract OrderbookStream {
    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct Quote {
        // The pool key
        IPoolFactory.PoolKey poolKey;
        // The provider of the quote
        address provider;
        // The taker of the quote (address(0) if quote should be usable by anyone)
        address taker;
        // The normalized option price
        uint256 price;
        // The max size
        uint256 size;
        // Whether provider is buying or selling
        bool isBuy;
        // Timestamp until which the quote is valid
        uint256 deadline;
        // Salt to make quote unique
        uint256 salt;
        // Signature of the quote
        Signature signature;
    }

    event PublishQuote(
        // When a struct is used as indexed param, it is stored as a Keccak-256 hash of the abi encoding of that struct
        // https://docs.soliditylang.org/en/v0.8.19/abi-spec.html#indexed-event-encoding
        IPoolFactory.PoolKey indexed poolKeyHash,
        address indexed provider,
        address taker,
        uint256 price,
        uint256 size,
        bool isBuy,
        uint256 deadline,
        uint256 salt,
        Signature signature,
        // We still emit the poolKey as non indexed param to be able to access the elements of the poolKey in the event
        // This is why the same variable is emitted twice
        IPoolFactory.PoolKey poolKey
    );

    /// @notice Emits PublishQuote event for `quote`
    function add(Quote[] calldata quote) external {
        for (uint256 i = 0; i < quote.length; i++) {
            emit PublishQuote(
                quote[i].poolKey,
                quote[i].provider,
                quote[i].taker,
                quote[i].price,
                quote[i].size,
                quote[i].isBuy,
                quote[i].deadline,
                quote[i].salt,
                quote[i].signature,
                quote[i].poolKey
            );
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {IPoolBase} from "./IPoolBase.sol";
import {IPoolCore} from "./IPoolCore.sol";
import {IPoolDepositWithdraw} from "./IPoolDepositWithdraw.sol";
import {IPoolTrade} from "./IPoolTrade.sol";
import {IPoolEvents} from "./IPoolEvents.sol";

interface IPool is IPoolBase, IPoolCore, IPoolDepositWithdraw, IPoolEvents, IPoolTrade {}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {IERC1155Base} from "@solidstate/contracts/token/ERC1155/base/IERC1155Base.sol";
import {IERC1155Enumerable} from "@solidstate/contracts/token/ERC1155/enumerable/IERC1155Enumerable.sol";
import {IMulticall} from "@solidstate/contracts/utils/IMulticall.sol";

interface IPoolBase is IERC1155Base, IERC1155Enumerable, IMulticall {
    error Pool__UseTransferPositionToTransferLPTokens();

    /// @notice get token collection name
    /// @return collection name
    function name() external view returns (string memory);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {IPoolInternal} from "./IPoolInternal.sol";

import {Position} from "../libraries/Position.sol";

interface IPoolCore is IPoolInternal {
    /// @notice Get the current market price as normalized price
    /// @return The current market price as normalized price
    function marketPrice() external view returns (UD60x18);

    /// @notice Calculates the fee for a trade based on the `size` and `premium` of the trade
    /// @param taker The taker of a trade
    /// @param size The size of a trade (number of contracts) (18 decimals)
    /// @param premium The total cost of option(s) for a purchase (poolToken decimals)
    /// @param isPremiumNormalized Whether the premium given is already normalized by strike or not (Ex: For a strike of 1500, and a premium of 750, the normalized premium would be 0.5)
    /// @param isOrderbook Whether the fee is for the `fillQuoteOB` function or not
    /// @return The taker fee for an option trade denormalized (poolToken decimals)
    function takerFee(
        address taker,
        UD60x18 size,
        uint256 premium,
        bool isPremiumNormalized,
        bool isOrderbook
    ) external view returns (uint256);

    /// @notice Calculates the fee for a trade based on the `size` and `premiumNormalized` of the trade.
    /// @dev WARNING: It is recommended to use `takerFee` instead of this function. This function is a lower level
    ///      function here to be used when a pool has not yet be deployed, by calling it from the diamond contract
    ///      directly rather than a pool proxy. If using it from the pool, you should pass the same value as the pool
    ///      for `strike` and `isCallPool` in order to get the accurate takerFee
    /// @param taker The taker of a trade
    /// @param size The size of a trade (number of contracts) (18 decimals)
    /// @param premium The total cost of option(s) for a purchase (18 decimals)
    /// @param isPremiumNormalized Whether the premium given is already normalized by strike or not (Ex: For a strike of
    ///        1500, and a premium of 750, the normalized premium would be 0.5)
    /// @param isOrderbook Whether the fee is for the `fillQuoteOB` function or not
    /// @param strike The strike of the option (18 decimals)
    /// @param isCallPool Whether the pool is a call pool or not
    /// @return The taker fee for an option trade denormalized. (18 decimals)
    function _takerFeeLowLevel(
        address taker,
        UD60x18 size,
        UD60x18 premium,
        bool isPremiumNormalized,
        bool isOrderbook,
        UD60x18 strike,
        bool isCallPool
    ) external view returns (UD60x18);

    /// @notice Returns all pool parameters used for deployment
    /// @return base Address of base token
    /// @return quote Address of quote token
    /// @return oracleAdapter Address of oracle adapter
    /// @return strike The strike of the option (18 decimals)
    /// @return maturity The maturity timestamp of the option
    /// @return isCallPool Whether the pool is for call or put options
    function getPoolSettings()
        external
        view
        returns (address base, address quote, address oracleAdapter, UD60x18 strike, uint256 maturity, bool isCallPool);

    /// @notice Returns all ticks in the pool, including net liquidity for each tick
    /// @return ticks All pool ticks with the liquidityNet (18 decimals) of each tick
    function ticks() external view returns (IPoolInternal.TickWithRates[] memory);

    /// @notice Updates the claimable fees of a position and transfers the claimed
    ///         fees to the operator of the position. Then resets the claimable fees to
    ///         zero.
    /// @param p The position key
    /// @return The amount of claimed fees (poolToken decimals)
    function claim(Position.Key calldata p) external returns (uint256);

    /// @notice Returns total claimable fees for the position
    /// @param p The position key
    /// @return The total claimable fees for the position (poolToken decimals)
    function getClaimableFees(Position.Key calldata p) external view returns (uint256);

    /// @notice Underwrite an option by depositing collateral. By default the taker fee and referral are applied to the
    ///         underwriter, if the caller is a registered vault the longReceiver is used instead.
    /// @param underwriter The underwriter of the option (Collateral will be taken from this address, and it will
    ///        receive the short token)
    /// @param longReceiver The address which will receive the long token
    /// @param size The number of contracts being underwritten (18 decimals)
    /// @param referrer The referrer of the user doing the trade
    function writeFrom(address underwriter, address longReceiver, UD60x18 size, address referrer) external;

    /// @notice Annihilate a pair of long + short option contracts to unlock the stored collateral.
    /// @dev This function can be called post or prior to expiration.
    /// @param size The size to annihilate (18 decimals)
    function annihilate(UD60x18 size) external;

    /// @notice Annihilate a pair of long + short option contracts to unlock the stored collateral on behalf of another account.
    ///         msg.sender must be approved through `UserSettings.setAuthorizedAddress` by the owner of the long/short contracts.
    /// @dev This function can be called post or prior to expiration.
    /// @param owner The owner of the shorts/longs to annihilate
    /// @param size The size to annihilate (18 decimals)
    function annihilateFor(address owner, UD60x18 size) external;

    /// @notice Exercises all long options held by caller
    /// @return exerciseValue The exercise value as amount of collateral paid out to long holder (poolToken decimals)
    /// @return exerciseFee The fee paid to protocol (poolToken decimals)
    function exercise() external returns (uint256 exerciseValue, uint256 exerciseFee);

    /// @notice Batch exercises all long options held by each `holder`, caller is reimbursed with the cost deducted from
    ///         the proceeds of the exercised options. Only authorized agents may execute this function on behalf of the
    ///         option holder.
    /// @param holders The holders of the contracts
    /// @param costPerHolder The cost charged by the authorized operator, per option holder (poolToken decimals)
    /// @return exerciseValues The exercise value as amount of collateral paid out per holder, ignoring costs applied during automatic
    ///         exercise, but excluding protocol fees from amount (poolToken decimals)
    /// @return exerciseFees The fees paid to protocol (poolToken decimals)
    function exerciseFor(
        address[] calldata holders,
        uint256 costPerHolder
    ) external returns (uint256[] memory exerciseValues, uint256[] memory exerciseFees);

    /// @notice Settles all short options held by caller
    /// @return collateral The amount of collateral left after settlement (poolToken decimals)
    function settle() external returns (uint256 collateral);

    /// @notice Batch settles all short options held by each `holder`, caller is reimbursed with the cost deducted from
    ///         the proceeds of the settled options. Only authorized operators may execute this function on behalf of the
    ///         option holder.
    /// @param holders The holders of the contracts
    /// @param costPerHolder The cost charged by the authorized operator, per option holder (poolToken decimals)
    /// @return The amount of collateral left after settlement per holder, ignoring costs applied during automatic
    ///         settlement (poolToken decimals)
    function settleFor(address[] calldata holders, uint256 costPerHolder) external returns (uint256[] memory);

    /// @notice Reconciles a user's `position` to account for settlement payouts post-expiration.
    /// @param p The position key
    /// @return collateral The amount of collateral left after settlement (poolToken decimals)
    function settlePosition(Position.Key calldata p) external returns (uint256 collateral);

    /// @notice Batch reconciles each `position` to account for settlement payouts post-expiration. Caller is reimbursed
    ///         with the cost deducted from the proceeds of the settled position. Only authorized operators may execute
    ///         this function on behalf of the option holder.
    /// @param p The position keys
    /// @param costPerHolder The cost charged by the authorized operator, per position holder (poolToken decimals)
    /// @return The amount of collateral left after settlement per holder, ignoring costs applied during automatic
    ///         settlement (poolToken decimals)
    function settlePositionFor(Position.Key[] calldata p, uint256 costPerHolder) external returns (uint256[] memory);

    /// @notice Transfer a LP position to a new owner/operator
    /// @param srcP The position key
    /// @param newOwner The new owner
    /// @param newOperator The new operator
    /// @param size The size to transfer (18 decimals)
    function transferPosition(Position.Key calldata srcP, address newOwner, address newOperator, UD60x18 size) external;

    /// @notice Attempts to cache the settlement price of the option after expiration. Reverts if a price has already been cached
    function tryCacheSettlementPrice() external;

    /// @notice Returns the settlement price of the option.
    /// @return The settlement price of the option (18 decimals). Returns 0 if option is not settled yet.
    function getSettlementPrice() external view returns (UD60x18);

    /// @notice Gets the lower and upper bound of the stranded market area when it exists. In case the stranded market
    ///         area does not exist it will return the stranded market area the maximum tick price for both the lower
    ///         and the upper, in which case the market price is not stranded given any range order info order.
    /// @return lower Lower bound of the stranded market price area (Default : 1e18) (18 decimals)
    /// @return upper Upper bound of the stranded market price area (Default : 1e18) (18 decimals)
    function getStrandedArea() external view returns (UD60x18 lower, UD60x18 upper);

    /// @notice Returns the list of existing tokenIds with non zero balance
    /// @return tokenIds The list of existing tokenIds
    function getTokenIds() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {IPoolInternal} from "./IPoolInternal.sol";

import {Position} from "../libraries/Position.sol";

interface IPoolDepositWithdraw is IPoolInternal {
    /// @notice Deposits a `position` (combination of owner/operator, price range, bid/ask collateral, and long/short
    ///         contracts) into the pool. Tx will revert if market price is not between `minMarketPrice` and
    ///         `maxMarketPrice`. If the pool uses WETH as collateral, it is possible to send ETH to this function and
    ///         it will be wrapped into WETH. Any excess ETH sent will be refunded to the `msg.sender` as WETH.
    /// @param p The position key
    /// @param belowLower The normalized price of nearest existing tick below lower. The search is done off-chain,
    ///        passed as arg and validated on-chain to save gas (18 decimals)
    /// @param belowUpper The normalized price of nearest existing tick below upper. The search is done off-chain,
    ///        passed as arg and validated on-chain to save gas (18 decimals)
    /// @param size The position size to deposit (18 decimals)
    /// @param minMarketPrice Min market price, as normalized value. (If below, tx will revert) (18 decimals)
    /// @param maxMarketPrice Max market price, as normalized value. (If above, tx will revert) (18 decimals)
    /// @return delta The amount of collateral / longs / shorts deposited
    function deposit(
        Position.Key calldata p,
        UD60x18 belowLower,
        UD60x18 belowUpper,
        UD60x18 size,
        UD60x18 minMarketPrice,
        UD60x18 maxMarketPrice
    ) external returns (Position.Delta memory delta);

    /// @notice Deposits a `position` (combination of owner/operator, price range, bid/ask collateral, and long/short
    ///         contracts) into the pool. Tx will revert if market price is not between `minMarketPrice` and
    ///         `maxMarketPrice`. If the pool uses WETH as collateral, it is possible to send ETH to this function and
    ///         it will be wrapped into WETH. Any excess ETH sent will be refunded to the `msg.sender` as WETH.
    /// @param p The position key
    /// @param belowLower The normalized price of nearest existing tick below lower. The search is done off-chain,
    ///        passed as arg and validated on-chain to save gas (18 decimals)
    /// @param belowUpper The normalized price of nearest existing tick below upper. The search is done off-chain,
    ///        passed as arg and validated on-chain to save gas (18 decimals)
    /// @param size The position size to deposit (18 decimals)
    /// @param minMarketPrice Min market price, as normalized value. (If below, tx will revert) (18 decimals)
    /// @param maxMarketPrice Max market price, as normalized value. (If above, tx will revert) (18 decimals)
    /// @param isBidIfStrandedMarketPrice Whether this is a bid or ask order when the market price is stranded (This
    ///        argument doesnt matter if market price is not stranded)
    /// @return delta The amount of collateral / longs / shorts deposited
    function deposit(
        Position.Key calldata p,
        UD60x18 belowLower,
        UD60x18 belowUpper,
        UD60x18 size,
        UD60x18 minMarketPrice,
        UD60x18 maxMarketPrice,
        bool isBidIfStrandedMarketPrice
    ) external returns (Position.Delta memory delta);

    /// @notice Withdraws a `position` (combination of owner/operator, price range, bid/ask collateral, and long/short
    ///         contracts) from the pool. Tx will revert if market price is not between `minMarketPrice` and
    ///         `maxMarketPrice`.
    /// @param p The position key
    /// @param size The position size to withdraw (18 decimals)
    /// @param minMarketPrice Min market price, as normalized value. (If below, tx will revert) (18 decimals)
    /// @param maxMarketPrice Max market price, as normalized value. (If above, tx will revert) (18 decimals)
    /// @return delta The amount of collateral / longs / shorts withdrawn
    function withdraw(
        Position.Key calldata p,
        UD60x18 size,
        UD60x18 minMarketPrice,
        UD60x18 maxMarketPrice
    ) external returns (Position.Delta memory delta);

    /// @notice Get nearest ticks below `lower` and `upper`.
    /// @dev If no tick between `lower` and `upper`, then the nearest tick below `upper`, will be `lower`
    /// @param lower The lower bound of the range (18 decimals)
    /// @param upper The upper bound of the range (18 decimals)
    /// @return nearestBelowLower The nearest tick below `lower` (18 decimals)
    /// @return nearestBelowUpper The nearest tick below `upper` (18 decimals)
    function getNearestTicksBelow(
        UD60x18 lower,
        UD60x18 upper
    ) external view returns (UD60x18 nearestBelowLower, UD60x18 nearestBelowUpper);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {SD59x18} from "lib/prb-math/src/SD59x18.sol";
import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {Position} from "../libraries/Position.sol";

interface IPoolEvents {
    event UpdateTick(
        UD60x18 indexed tick,
        UD60x18 indexed prev,
        UD60x18 indexed next,
        SD59x18 delta,
        UD60x18 externalFeeRate,
        SD59x18 longDelta,
        SD59x18 shortDelta,
        uint256 counter
    );

    event Deposit(
        address indexed owner,
        uint256 indexed tokenId,
        UD60x18 collateral,
        UD60x18 longs,
        UD60x18 shorts,
        SD59x18 lastFeeRate,
        UD60x18 claimableFees,
        UD60x18 marketPrice,
        UD60x18 liquidityRate,
        UD60x18 currentTick
    );

    event Withdrawal(
        address indexed owner,
        uint256 indexed tokenId,
        UD60x18 collateral,
        UD60x18 longs,
        UD60x18 shorts,
        SD59x18 lastFeeRate,
        UD60x18 claimableFees,
        UD60x18 marketPrice,
        UD60x18 liquidityRate,
        UD60x18 currentTick
    );

    event ClaimFees(address indexed owner, uint256 indexed tokenId, UD60x18 feesClaimed, SD59x18 lastFeeRate);

    event ClaimProtocolFees(address indexed feeReceiver, UD60x18 feesClaimed);

    event FillQuoteOB(
        bytes32 indexed quoteOBHash,
        address indexed user,
        address indexed provider,
        UD60x18 contractSize,
        Position.Delta deltaMaker,
        Position.Delta deltaTaker,
        UD60x18 premium,
        UD60x18 protocolFee,
        UD60x18 totalReferralRebate,
        bool isBuy
    );

    event WriteFrom(
        address indexed underwriter,
        address indexed longReceiver,
        address indexed taker,
        UD60x18 contractSize,
        UD60x18 collateral,
        UD60x18 protocolFee
    );

    event Trade(
        address indexed user,
        UD60x18 contractSize,
        Position.Delta delta,
        UD60x18 premium,
        UD60x18 takerFee,
        UD60x18 protocolFee,
        UD60x18 marketPrice,
        UD60x18 liquidityRate,
        UD60x18 currentTick,
        UD60x18 totalReferralRebate,
        bool isBuy
    );

    event Exercise(
        address indexed operator,
        address indexed holder,
        UD60x18 contractSize,
        UD60x18 exerciseValue,
        UD60x18 settlementPrice,
        UD60x18 fee,
        UD60x18 operatorCost
    );

    event Settle(
        address indexed operator,
        address indexed holder,
        UD60x18 contractSize,
        UD60x18 exerciseValue,
        UD60x18 settlementPrice,
        UD60x18 fee,
        UD60x18 operatorCost
    );

    event Annihilate(address indexed owner, UD60x18 contractSize, uint256 fee);

    event SettlePosition(
        address indexed operator,
        address indexed owner,
        uint256 indexed tokenId,
        UD60x18 contractSize,
        UD60x18 collateral,
        UD60x18 exerciseValue,
        UD60x18 feesClaimed,
        UD60x18 settlementPrice,
        UD60x18 fee,
        UD60x18 operatorCost
    );

    event TransferPosition(address indexed owner, address indexed receiver, uint256 srcTokenId, uint256 destTokenId);

    event CancelQuoteOB(address indexed provider, bytes32 quoteOBHash);

    event FlashLoan(address indexed initiator, address indexed receiver, UD60x18 amount, UD60x18 fee);

    event SettlementPriceCached(UD60x18 settlementPrice);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {SD59x18} from "lib/prb-math/src/SD59x18.sol";

import {IPosition} from "../libraries/IPosition.sol";
import {IPricing} from "../libraries/IPricing.sol";
import {UD50x28} from "../libraries/UD50x28.sol";
import {SD49x28} from "../libraries/SD49x28.sol";

import {IUserSettings} from "../settings/IUserSettings.sol";

interface IPoolInternal is IPosition, IPricing {
    error Pool__AboveQuoteSize(UD60x18 size, UD60x18 quoteSize);
    error Pool__AboveMaxSlippage(uint256 value, uint256 minimum, uint256 maximum);
    error Pool__ActionNotAuthorized(address user, address sender, IUserSettings.Action action);
    error Pool__AgentNotAuthorized();
    error Pool__CostExceedsPayout(UD60x18 cost, UD60x18 payout);
    error Pool__CostNotAuthorized(UD60x18 costInWrappedNative, UD60x18 authorizedCost);
    error Pool__FlashLoanCallbackFailed();
    error Pool__FlashLoanNotRepayed();
    error Pool__InsufficientAskLiquidity();
    error Pool__InsufficientBidLiquidity();
    error Pool__InsufficientFunds();
    error Pool__InsufficientLiquidity();
    error Pool__InvalidAssetUpdate(SD59x18 deltaLongs, SD59x18 deltaShorts);
    error Pool__InvalidBelowPrice(UD60x18 price, UD60x18 priceBelow);
    error Pool__InvalidMonth(uint256 month);
    error Pool__InvalidPositionState(uint256 balance, uint256 lastDeposit);
    error Pool__InvalidQuoteOBSignature();
    error Pool__InvalidQuoteOBTaker();
    error Pool__InvalidRange(UD60x18 lower, UD60x18 upper);
    error Pool__InvalidReconciliation(uint256 crossings);
    error Pool__InvalidSize(UD60x18 lower, UD60x18 upper, UD60x18 depositSize);
    error Pool__InvalidTickPrice();
    error Pool__InvalidTickUpdate();
    error Pool__InvalidTransfer();
    error Pool__NotEnoughTokens(UD60x18 balance, UD60x18 size);
    error Pool__NotPoolToken(address token);
    error Pool__NotWrappedNativeTokenPool();
    error Pool__OperatorNotAuthorized(address sender);
    error Pool__OptionExpired();
    error Pool__OptionNotExpired();
    error Pool__OutOfBoundsPrice(UD60x18 price);
    error Pool__PositionDoesNotExist(address owner, uint256 tokenId);
    error Pool__PositionCantHoldLongAndShort(UD60x18 longs, UD60x18 shorts);
    error Pool__QuoteOBCancelled();
    error Pool__QuoteOBExpired();
    error Pool__QuoteOBOverfilled(UD60x18 filledAmount, UD60x18 size, UD60x18 quoteOBSize);
    error Pool__SettlementFailed();
    error Pool__SettlementPriceAlreadyCached();
    error Pool__TickDeltaNotZero(SD59x18 tickDelta);
    error Pool__TickNotFound(UD60x18 price);
    error Pool__TickOutOfRange(UD60x18 price);
    error Pool__TickWidthInvalid(UD60x18 price);
    error Pool__WithdrawalDelayNotElapsed(uint256 unlockTime);
    error Pool__ZeroSize();

    struct Tick {
        SD49x28 delta;
        UD50x28 externalFeeRate;
        SD49x28 longDelta;
        SD49x28 shortDelta;
        uint256 counter;
    }

    struct TickWithRates {
        Tick tick;
        UD60x18 price;
        UD50x28 longRate;
        UD50x28 shortRate;
    }

    struct QuoteOB {
        // The provider of the OB quote
        address provider;
        // The taker of the OB quote (address(0) if OB quote should be usable by anyone)
        address taker;
        // The normalized option price (18 decimals)
        UD60x18 price;
        // The max size (18 decimals)
        UD60x18 size;
        // Whether provider is buying or selling
        bool isBuy;
        // Timestamp until which the OB quote is valid
        uint256 deadline;
        // Salt to make OB quote unique
        uint256 salt;
    }

    enum InvalidQuoteOBError {
        None,
        QuoteOBExpired,
        QuoteOBCancelled,
        QuoteOBOverfilled,
        OutOfBoundsPrice,
        InvalidQuoteOBTaker,
        InvalidQuoteOBSignature,
        InvalidAssetUpdate,
        InsufficientCollateralAllowance,
        InsufficientCollateralBalance,
        InsufficientLongBalance,
        InsufficientShortBalance
    }

    ////////////////////
    ////////////////////
    // The structs below are used as a way to reduce stack depth and avoid "stack too deep" errors

    struct TradeArgsInternal {
        // The account doing the trade
        address user;
        // The referrer of the user doing the trade
        address referrer;
        // The number of contracts being traded (18 decimals)
        UD60x18 size;
        // Whether the taker is buying or selling
        bool isBuy;
        // Tx will revert if total premium is above this value when buying, or below this value when selling.
        // (poolToken decimals)
        uint256 premiumLimit;
        // Whether to transfer collateral to user or not if collateral value is positive. Should be false if that
        // collateral is used for a swap
        bool transferCollateralToUser;
    }

    struct ReferralVarsInternal {
        UD60x18 totalRebate;
        UD60x18 primaryRebate;
        UD60x18 secondaryRebate;
    }

    struct TradeVarsInternal {
        UD60x18 maxSize;
        UD60x18 tradeSize;
        UD50x28 oldMarketPrice;
        UD60x18 totalPremium;
        UD60x18 totalTakerFees;
        UD60x18 totalProtocolFees;
        UD50x28 longDelta;
        UD50x28 shortDelta;
        ReferralVarsInternal referral;
    }

    struct DepositArgsInternal {
        // The normalized price of nearest existing tick below lower. The search is done off-chain, passed as arg and
        // validated on-chain to save gas (18 decimals)
        UD60x18 belowLower;
        // The normalized price of nearest existing tick below upper. The search is done off-chain, passed as arg and
        // validated on-chain to save gas (18 decimals)
        UD60x18 belowUpper;
        // The position size to deposit (18 decimals)
        UD60x18 size;
        // minMarketPrice Min market price, as normalized value. (If below, tx will revert) (18 decimals)
        UD60x18 minMarketPrice;
        // maxMarketPrice Max market price, as normalized value. (If above, tx will revert) (18 decimals)
        UD60x18 maxMarketPrice;
    }

    struct WithdrawVarsInternal {
        bytes32 pKeyHash;
        uint256 tokenId;
        UD60x18 initialSize;
        UD50x28 liquidityPerTick;
        bool isFullWithdrawal;
        SD49x28 tickDelta;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct FillQuoteOBArgsInternal {
        // The user filling the OB quote
        address user;
        // The referrer of the user filling the OB quote
        address referrer;
        // The size to fill from the OB quote (18 decimals)
        UD60x18 size;
        // secp256k1 'r', 's', and 'v' value
        Signature signature;
        // Whether to transfer collateral to user or not if collateral value is positive. Should be false if that
        // collateral is used for a swap
        bool transferCollateralToUser;
    }

    struct PremiumAndFeeInternal {
        UD60x18 totalReferralRebate;
        UD60x18 premium;
        UD60x18 protocolFee;
        UD60x18 premiumTaker;
        UD60x18 premiumMaker;
        ReferralVarsInternal referral;
    }

    struct QuoteAMMVarsInternal {
        UD60x18 liquidity;
        UD60x18 maxSize;
        UD60x18 totalPremium;
        UD60x18 totalTakerFee;
    }

    struct SettlePositionVarsInternal {
        bytes32 pKeyHash;
        uint256 tokenId;
        UD60x18 size;
        UD60x18 claimableFees;
        UD60x18 payoff;
        UD60x18 collateral;
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {IERC3156FlashLender} from "@solidstate/contracts/interfaces/IERC3156FlashLender.sol";
import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {Position} from "../libraries/Position.sol";

import {IPoolInternal} from "./IPoolInternal.sol";

interface IPoolTrade is IPoolInternal, IERC3156FlashLender {
    /// @notice Gives a quote for an AMM trade
    /// @param taker The taker of the trade
    /// @param size The number of contracts being traded (18 decimals)
    /// @param isBuy Whether the taker is buying or selling
    /// @return premiumNet The premium which has to be paid to complete the trade (Net of fees) (poolToken decimals)
    /// @return takerFee The taker fees to pay (Included in `premiumNet`) (poolToken decimals)
    function getQuoteAMM(
        address taker,
        UD60x18 size,
        bool isBuy
    ) external view returns (uint256 premiumNet, uint256 takerFee);

    /// @notice Functionality to support the OB / OTC system.
    ///         An LP can create a OB quote for which he will do an OTC trade through
    ///         the exchange. Takers can buy from / sell to the LP then partially or
    ///         fully while having the price guaranteed.
    /// @param quoteOB The OB quote given by the provider
    /// @param size The size to fill from the OB quote (18 decimals)
    /// @param signature secp256k1 'r', 's', and 'v' value
    /// @param referrer The referrer of the user filling the OB quote
    /// @return premiumTaker The premium paid or received by the taker for the trade (poolToken decimals)
    /// @return delta The net collateral / longs / shorts change for taker of the trade.
    function fillQuoteOB(
        QuoteOB calldata quoteOB,
        UD60x18 size,
        Signature calldata signature,
        address referrer
    ) external returns (uint256 premiumTaker, Position.Delta memory delta);

    /// @notice Completes a trade of `size` on `side` via the AMM using the liquidity in the Pool.
    ///         Tx will revert if total premium is above `totalPremium` when buying, or below `totalPremium` when
    ///         selling.
    /// @param size The number of contracts being traded (18 decimals)
    /// @param isBuy Whether the taker is buying or selling
    /// @param premiumLimit Tx will revert if total premium is above this value when buying, or below this value when
    ///        selling. (poolToken decimals)
    /// @param referrer The referrer of the user doing the trade
    /// @return totalPremium The premium paid or received by the taker for the trade (poolToken decimals)
    /// @return delta The net collateral / longs / shorts change for taker of the trade.
    function trade(
        UD60x18 size,
        bool isBuy,
        uint256 premiumLimit,
        address referrer
    ) external returns (uint256 totalPremium, Position.Delta memory delta);

    /// @notice Cancel given OB quotes
    /// @dev No check is done to ensure the given hash correspond to a OB quote provider by msg.sender,
    ///      but as we register the cancellation in a mapping provider -> hash, it is not possible to cancel a OB quote
    ///      created by another provider
    /// @param hashes The hashes of the OB quotes to cancel
    function cancelQuotesOB(bytes32[] calldata hashes) external;

    /// @notice Returns whether or not an OB quote is valid, given a fill size
    /// @param quoteOB The OB quote to check
    /// @param size Size to fill from the OB quote (18 decimals)
    /// @param sig secp256k1 Signature
    function isQuoteOBValid(
        QuoteOB calldata quoteOB,
        UD60x18 size,
        Signature calldata sig
    ) external view returns (bool, InvalidQuoteOBError);

    /// @notice Returns the size already filled for a given OB quote
    /// @param provider Provider of the OB quote
    /// @param quoteOBHash Hash of the OB quote
    /// @return The size already filled (18 decimals)
    function getQuoteOBFilledAmount(address provider, bytes32 quoteOBHash) external view returns (UD60x18);
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {ERC165Base} from "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import {ERC1155Base} from "@solidstate/contracts/token/ERC1155/base/ERC1155Base.sol";
import {ERC1155BaseInternal} from "@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol";
import {ERC1155Enumerable} from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155Enumerable.sol";
import {ERC1155EnumerableInternal} from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155EnumerableInternal.sol";
import {Multicall} from "@solidstate/contracts/utils/Multicall.sol";

import {PoolName} from "../libraries/PoolName.sol";

import {PoolStorage} from "./PoolStorage.sol";
import {IPoolBase} from "./IPoolBase.sol";

contract PoolBase is IPoolBase, ERC1155Base, ERC1155Enumerable, ERC165Base, Multicall {
    /// @inheritdoc IPoolBase
    function name() external view returns (string memory) {
        PoolStorage.Layout storage l = PoolStorage.layout();

        return PoolName.name(l.base, l.quote, l.maturity, l.strike.unwrap(), l.isCallPool);
    }

    /// @notice `_beforeTokenTransfer` wrapper, reverts if transferring LP tokens
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155BaseInternal, ERC1155EnumerableInternal) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // We do not need to update PoolStorage.Layout.tokenIds here as in PoolInternal._beforeTokenTransfer,
        // as no call to `_mint` or `_burn` can be made from this facet, and transfers to address(0) would revert
        for (uint256 i; i < ids.length; i++) {
            if (ids[i] > PoolStorage.LONG) revert Pool__UseTransferPositionToTransferLPTokens();
        }
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {DoublyLinkedListUD60x18, DoublyLinkedList} from "../libraries/DoublyLinkedListUD60x18.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

import {ONE, ZERO, UD50_ZERO} from "../libraries/Constants.sol";
import {Position} from "../libraries/Position.sol";
import {PRBMathExtra} from "../libraries/PRBMathExtra.sol";
import {UD50x28} from "../libraries/UD50x28.sol";

import {IUserSettings} from "../settings/IUserSettings.sol";

import {IPoolCore} from "./IPoolCore.sol";
import {IPoolInternal} from "./IPoolInternal.sol";
import {PoolStorage} from "./PoolStorage.sol";
import {PoolInternal} from "./PoolInternal.sol";

contract PoolCore is IPoolCore, PoolInternal, ReentrancyGuard {
    using DoublyLinkedListUD60x18 for DoublyLinkedList.Bytes32List;
    using EnumerableSet for EnumerableSet.UintSet;
    using PoolStorage for PoolStorage.Layout;
    using Position for Position.Key;
    using SafeERC20 for IERC20;
    using PRBMathExtra for UD60x18;
    using PRBMathExtra for UD50x28;

    constructor(
        address factory,
        address router,
        address wrappedNativeToken,
        address feeReceiver,
        address referral,
        address settings,
        address vaultRegistry,
        address vxPremia
    ) PoolInternal(factory, router, wrappedNativeToken, feeReceiver, referral, settings, vaultRegistry, vxPremia) {}

    /// @inheritdoc IPoolCore
    function marketPrice() external view returns (UD60x18) {
        return PoolStorage.layout().marketPrice.intoUD60x18();
    }

    /// @inheritdoc IPoolCore
    function takerFee(
        address taker,
        UD60x18 size,
        uint256 premium,
        bool isPremiumNormalized,
        bool isOrderbook
    ) external view returns (uint256) {
        PoolStorage.Layout storage l = PoolStorage.layout();
        return
            l.toPoolTokenDecimals(
                _takerFee(
                    taker,
                    size,
                    l.fromPoolTokenDecimals(premium),
                    isPremiumNormalized,
                    l.strike,
                    l.isCallPool,
                    isOrderbook
                )
            );
    }

    /// @inheritdoc IPoolCore
    function _takerFeeLowLevel(
        address taker,
        UD60x18 size,
        UD60x18 premium,
        bool isPremiumNormalized,
        bool isOrderbook,
        UD60x18 strike,
        bool isCallPool
    ) external view returns (UD60x18) {
        return _takerFee(taker, size, premium, isPremiumNormalized, strike, isCallPool, isOrderbook);
    }

    /// @inheritdoc IPoolCore
    function getPoolSettings()
        external
        view
        returns (address base, address quote, address oracleAdapter, UD60x18 strike, uint256 maturity, bool isCallPool)
    {
        PoolStorage.Layout storage l = PoolStorage.layout();
        return (l.base, l.quote, l.oracleAdapter, l.strike, l.maturity, l.isCallPool);
    }

    /// @inheritdoc IPoolCore
    function ticks() external view returns (IPoolInternal.TickWithRates[] memory) {
        PoolStorage.Layout storage l = PoolStorage.layout();
        UD50x28 longRate = l.longRate;
        UD50x28 shortRate = l.shortRate;
        UD60x18 prev = l.tickIndex.prev(l.currentTick);
        UD60x18 curr = l.currentTick;

        uint256 maxTicks = (ONE / PoolStorage.MIN_TICK_DISTANCE).unwrap() / 1e18;
        uint256 count;

        IPoolInternal.TickWithRates[] memory _ticks = new IPoolInternal.TickWithRates[](maxTicks);

        // compute the longRate and shortRate at MIN_TICK_PRICE
        if (l.currentTick != PoolStorage.MIN_TICK_PRICE) {
            while (true) {
                longRate = longRate.add(l.ticks[curr].longDelta);
                shortRate = shortRate.add(l.ticks[curr].shortDelta);

                if (prev == PoolStorage.MIN_TICK_PRICE) {
                    break;
                }

                curr = prev;
                prev = l.tickIndex.prev(prev);
            }
        }

        prev = PoolStorage.MIN_TICK_PRICE;
        curr = l.tickIndex.next(PoolStorage.MIN_TICK_PRICE);

        while (true) {
            _ticks[count++] = IPoolInternal.TickWithRates({
                tick: l.ticks[prev],
                price: prev,
                longRate: longRate,
                shortRate: shortRate
            });

            if (curr == PoolStorage.MAX_TICK_PRICE) {
                _ticks[count++] = IPoolInternal.TickWithRates({
                    tick: l.ticks[curr],
                    price: curr,
                    longRate: UD50_ZERO,
                    shortRate: UD50_ZERO
                });
                break;
            }

            prev = curr;

            if (curr <= l.currentTick) {
                longRate = longRate.sub(l.ticks[curr].longDelta);
                shortRate = shortRate.sub(l.ticks[curr].shortDelta);
            } else {
                longRate = longRate.add(l.ticks[curr].longDelta);
                shortRate = shortRate.add(l.ticks[curr].shortDelta);
            }
            curr = l.tickIndex.next(curr);
        }

        // Remove empty elements from array
        if (count < maxTicks) {
            assembly {
                mstore(_ticks, sub(mload(_ticks), sub(maxTicks, count)))
            }
        }

        return _ticks;
    }

    /// @inheritdoc IPoolCore
    function claim(Position.Key calldata p) external nonReentrant returns (uint256) {
        PoolStorage.Layout storage l = PoolStorage.layout();
        _revertIfOperatorNotAuthorized(p.operator);
        return _claim(p.toKeyInternal(l.strike, l.isCallPool));
    }

    /// @inheritdoc IPoolCore
    function getClaimableFees(Position.Key calldata p) external view returns (uint256) {
        PoolStorage.Layout storage l = PoolStorage.layout();
        Position.Data storage pData = l.positions[p.keyHash()];

        uint256 tokenId = PoolStorage.formatTokenId(p.operator, p.lower, p.upper, p.orderType);
        UD60x18 balance = _balanceOfUD60x18(p.owner, tokenId);

        (UD60x18 pendingClaimableFees, ) = _pendingClaimableFees(
            l,
            p.toKeyInternal(l.strike, l.isCallPool),
            pData,
            balance
        );

        return l.toPoolTokenDecimals(pData.claimableFees + pendingClaimableFees);
    }

    /// @inheritdoc IPoolCore
    function writeFrom(
        address underwriter,
        address longReceiver,
        UD60x18 size,
        address referrer
    ) external nonReentrant {
        return _writeFrom(underwriter, longReceiver, size, referrer);
    }

    /// @inheritdoc IPoolCore
    function annihilate(UD60x18 size) external nonReentrant {
        _annihilate(msg.sender, size);
    }

    /// @inheritdoc IPoolCore
    function annihilateFor(address account, UD60x18 size) external nonReentrant {
        _annihilate(account, size);
    }

    /// @inheritdoc IPoolCore
    function exercise() external nonReentrant returns (uint256 exerciseValue, uint256 exerciseFee) {
        (exerciseValue, exerciseFee, ) = _exercise(msg.sender, ZERO);
    }

    /// @inheritdoc IPoolCore
    function exerciseFor(
        address[] calldata holders,
        uint256 costPerHolder
    ) external nonReentrant returns (uint256[] memory exerciseValues, uint256[] memory exerciseFees) {
        PoolStorage.Layout storage l = PoolStorage.layout();

        UD60x18 _costPerHolder = l.fromPoolTokenDecimals(costPerHolder);
        exerciseValues = new uint256[](holders.length);
        exerciseFees = new uint256[](holders.length);

        for (uint256 i = 0; i < holders.length; i++) {
            if (holders[i] != msg.sender) {
                _revertIfActionNotAuthorized(holders[i], IUserSettings.Action.Exercise);
                _revertIfCostNotAuthorized(holders[i], _costPerHolder);
            }

            (uint256 exerciseValue, uint256 exerciseFee, bool success) = _exercise(holders[i], _costPerHolder);
            if (!success) revert Pool__SettlementFailed();
            exerciseValues[i] = exerciseValue;
            exerciseFees[i] = exerciseFee;
        }

        IERC20(l.getPoolToken()).safeTransfer(msg.sender, holders.length * costPerHolder);
    }

    /// @inheritdoc IPoolCore
    function settle() external nonReentrant returns (uint256 collateral) {
        (collateral, ) = _settle(msg.sender, ZERO);
    }

    /// @inheritdoc IPoolCore
    function settleFor(
        address[] calldata holders,
        uint256 costPerHolder
    ) external nonReentrant returns (uint256[] memory collateral) {
        PoolStorage.Layout storage l = PoolStorage.layout();

        UD60x18 _costPerHolder = l.fromPoolTokenDecimals(costPerHolder);
        collateral = new uint256[](holders.length);

        for (uint256 i = 0; i < holders.length; i++) {
            if (holders[i] != msg.sender) {
                _revertIfActionNotAuthorized(holders[i], IUserSettings.Action.Settle);
                _revertIfCostNotAuthorized(holders[i], _costPerHolder);
            }

            (uint256 _collateral, bool success) = _settle(holders[i], _costPerHolder);
            if (!success) revert Pool__SettlementFailed();
            collateral[i] = _collateral;
        }

        IERC20(l.getPoolToken()).safeTransfer(msg.sender, holders.length * costPerHolder);
    }

    /// @inheritdoc IPoolCore
    function settlePosition(Position.Key calldata p) external nonReentrant returns (uint256 collateral) {
        PoolStorage.Layout storage l = PoolStorage.layout();
        _revertIfOperatorNotAuthorized(p.operator);
        (collateral, ) = _settlePosition(p.toKeyInternal(l.strike, l.isCallPool), ZERO);
    }

    /// @inheritdoc IPoolCore
    function settlePositionFor(
        Position.Key[] calldata p,
        uint256 costPerHolder
    ) external nonReentrant returns (uint256[] memory collateral) {
        PoolStorage.Layout storage l = PoolStorage.layout();

        UD60x18 _costPerHolder = l.fromPoolTokenDecimals(costPerHolder);
        collateral = new uint256[](p.length);

        for (uint256 i = 0; i < p.length; i++) {
            if (p[i].operator != msg.sender) {
                _revertIfActionNotAuthorized(p[i].operator, IUserSettings.Action.SettlePosition);
                _revertIfCostNotAuthorized(p[i].operator, _costPerHolder);
            }

            (uint256 _collateral, bool success) = _settlePosition(
                p[i].toKeyInternal(l.strike, l.isCallPool),
                _costPerHolder
            );

            if (!success) revert Pool__SettlementFailed();
            collateral[i] = _collateral;
        }

        IERC20(l.getPoolToken()).safeTransfer(msg.sender, p.length * costPerHolder);
    }

    /// @inheritdoc IPoolCore
    function transferPosition(
        Position.Key calldata srcP,
        address newOwner,
        address newOperator,
        UD60x18 size
    ) external nonReentrant {
        PoolStorage.Layout storage l = PoolStorage.layout();
        _revertIfOperatorNotAuthorized(srcP.operator);
        _transferPosition(srcP.toKeyInternal(l.strike, l.isCallPool), newOwner, newOperator, size);
    }

    /// @inheritdoc IPoolCore
    function tryCacheSettlementPrice() external {
        PoolStorage.Layout storage l = PoolStorage.layout();
        _revertIfOptionNotExpired(l);

        if (l.settlementPrice == ZERO) _tryCacheSettlementPrice(l);
        else revert Pool__SettlementPriceAlreadyCached();
    }

    /// @inheritdoc IPoolCore
    function getSettlementPrice() external view returns (UD60x18) {
        return PoolStorage.layout().settlementPrice;
    }

    /// @inheritdoc IPoolCore
    function getStrandedArea() external view returns (UD60x18 lower, UD60x18 upper) {
        return _getStrandedArea(PoolStorage.layout());
    }

    /// @inheritdoc IPoolCore
    function getTokenIds() external view returns (uint256[] memory) {
        return PoolStorage.layout().tokenIds.toArray();
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";

import {PoolStorage} from "./PoolStorage.sol";
import {PoolInternal} from "./PoolInternal.sol";

import {Position} from "../libraries/Position.sol";

import {IPoolDepositWithdraw} from "./IPoolDepositWithdraw.sol";

contract PoolDepositWithdraw is IPoolDepositWithdraw, PoolInternal, ReentrancyGuard {
    using PoolStorage for PoolStorage.Layout;
    using Position for Position.Key;
    using SafeERC20 for IERC20;

    constructor(
        address factory,
        address router,
        address wrappedNativeToken,
        address feeReceiver,
        address referral,
        address settings,
        address vaultRegistry,
        address vxPremia
    ) PoolInternal(factory, router, wrappedNativeToken, feeReceiver, referral, settings, vaultRegistry, vxPremia) {}

    /// @inheritdoc IPoolDepositWithdraw
    function deposit(
        Position.Key calldata p,
        UD60x18 belowLower,
        UD60x18 belowUpper,
        UD60x18 size,
        UD60x18 minMarketPrice,
        UD60x18 maxMarketPrice
    ) external nonReentrant returns (Position.Delta memory delta) {
        PoolStorage.Layout storage l = PoolStorage.layout();

        _revertIfOperatorNotAuthorized(p.operator);

        return
            _deposit(
                p.toKeyInternal(l.strike, l.isCallPool),
                DepositArgsInternal(belowLower, belowUpper, size, minMarketPrice, maxMarketPrice)
            );
    }

    /// @inheritdoc IPoolDepositWithdraw
    function deposit(
        Position.Key calldata p,
        UD60x18 belowLower,
        UD60x18 belowUpper,
        UD60x18 size,
        UD60x18 minMarketPrice,
        UD60x18 maxMarketPrice,
        bool isBidIfStrandedMarketPrice
    ) external nonReentrant returns (Position.Delta memory delta) {
        PoolStorage.Layout storage l = PoolStorage.layout();

        _revertIfOperatorNotAuthorized(p.operator);

        return
            _deposit(
                p.toKeyInternal(l.strike, l.isCallPool),
                DepositArgsInternal(belowLower, belowUpper, size, minMarketPrice, maxMarketPrice),
                isBidIfStrandedMarketPrice
            );
    }

    /// @inheritdoc IPoolDepositWithdraw
    function withdraw(
        Position.Key calldata p,
        UD60x18 size,
        UD60x18 minMarketPrice,
        UD60x18 maxMarketPrice
    ) external nonReentrant returns (Position.Delta memory delta) {
        PoolStorage.Layout storage l = PoolStorage.layout();

        _revertIfOperatorNotAuthorized(p.operator);

        return _withdraw(p.toKeyInternal(l.strike, l.isCallPool), size, minMarketPrice, maxMarketPrice, true);
    }

    /// @inheritdoc IPoolDepositWithdraw
    function getNearestTicksBelow(
        UD60x18 lower,
        UD60x18 upper
    ) external view returns (UD60x18 nearestBelowLower, UD60x18 nearestBelowUpper) {
        return _getNearestTicksBelow(lower, upper);
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {Math} from "@solidstate/contracts/utils/Math.sol";
import {EIP712} from "@solidstate/contracts/cryptography/EIP712.sol";
import {ERC1155EnumerableInternal} from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155Enumerable.sol";
import {SafeCast} from "@solidstate/contracts/utils/SafeCast.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {ECDSA} from "@solidstate/contracts/cryptography/ECDSA.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";
import {SD59x18} from "lib/prb-math/src/SD59x18.sol";

import {IOracleAdapter} from "../adapter/IOracleAdapter.sol";
import {IERC20Router} from "../router/IERC20Router.sol";
import {IPoolFactory} from "../factory/IPoolFactory.sol";
import {IUserSettings} from "../settings/IUserSettings.sol";
import {IVxPremia} from "../staking/IVxPremia.sol";
import {IVaultRegistry} from "../vault/IVaultRegistry.sol";

import {DoublyLinkedListUD60x18, DoublyLinkedList} from "../libraries/DoublyLinkedListUD60x18.sol";
import {Position} from "../libraries/Position.sol";
import {Pricing} from "../libraries/Pricing.sol";
import {PRBMathExtra} from "../libraries/PRBMathExtra.sol";
import {iZERO, ZERO, ONE, TWO, FIVE, UD50_ZERO, SD49_ZERO} from "../libraries/Constants.sol";
import {UD50x28} from "../libraries/UD50x28.sol";
import {SD49x28} from "../libraries/SD49x28.sol";

import {IReferral} from "../referral/IReferral.sol";

import {IPoolInternal} from "./IPoolInternal.sol";
import {IPoolEvents} from "./IPoolEvents.sol";
import {PoolStorage} from "./PoolStorage.sol";

contract PoolInternal is IPoolInternal, IPoolEvents, ERC1155EnumerableInternal {
    using SafeERC20 for IERC20;
    using DoublyLinkedListUD60x18 for DoublyLinkedList.Bytes32List;
    using EnumerableSet for EnumerableSet.UintSet;
    using PoolStorage for IERC20;
    using PoolStorage for IERC20Router;
    using PoolStorage for PoolStorage.Layout;
    using PoolStorage for QuoteOB;
    using Position for Position.KeyInternal;
    using Position for Position.OrderType;
    using Pricing for Pricing.Args;
    using SafeCast for uint256;
    using Math for int256;
    using ECDSA for bytes32;
    using PRBMathExtra for UD60x18;
    using PRBMathExtra for SD59x18;
    using PRBMathExtra for UD50x28;
    using PRBMathExtra for SD49x28;

    address internal immutable FACTORY;
    address internal immutable ROUTER;
    address internal immutable WRAPPED_NATIVE_TOKEN;
    address internal immutable FEE_RECEIVER;
    address internal immutable REFERRAL;
    address internal immutable SETTINGS;
    address internal immutable VAULT_REGISTRY;
    address internal immutable VXPREMIA;

    UD60x18 internal constant PROTOCOL_FEE_PERCENTAGE = UD60x18.wrap(0.5e18); // 50%

    UD60x18 internal constant AMM_PREMIUM_FEE_PERCENTAGE = UD60x18.wrap(0.03e18); // 3% of premium
    UD60x18 internal constant AMM_NOTIONAL_FEE_PERCENTAGE = UD60x18.wrap(0.003e18); // 0.3% of notional
    UD60x18 internal constant ORDERBOOK_NOTIONAL_FEE_PERCENTAGE = UD60x18.wrap(0.0008e18); // 0.08% of notional
    UD60x18 internal constant MAX_PREMIUM_FEE_PERCENTAGE = UD60x18.wrap(0.125e18); // 12.5% of premium

    UD60x18 internal constant EXERCISE_FEE_PERCENTAGE = UD60x18.wrap(0.003e18); // 0.3% of notional
    UD60x18 internal constant MAX_EXERCISE_FEE_PERCENTAGE = UD60x18.wrap(0.125e18); // 12.5% of intrinsic value

    // Number of seconds required to pass before a deposit can be withdrawn (To prevent flash loans and JIT)
    uint256 internal constant WITHDRAWAL_DELAY = 60;

    bytes32 internal constant FILL_QUOTE_OB_TYPE_HASH =
        keccak256(
            "FillQuoteOB(address provider,address taker,uint256 price,uint256 size,bool isBuy,uint256 deadline,uint256 salt)"
        );

    constructor(
        address factory,
        address router,
        address wrappedNativeToken,
        address feeReceiver,
        address referral,
        address settings,
        address vaultRegistry,
        address vxPremia
    ) {
        FACTORY = factory;
        ROUTER = router;
        WRAPPED_NATIVE_TOKEN = wrappedNativeToken;
        FEE_RECEIVER = feeReceiver;
        REFERRAL = referral;
        SETTINGS = settings;
        VAULT_REGISTRY = vaultRegistry;
        VXPREMIA = vxPremia;
    }

    /// @notice Calculates the fee for a trade based on the `size` and `premium` of the trade.
    /// @param taker The taker of a trade
    /// @param size The size of a trade (number of contracts) (18 decimals)
    /// @param premium The total cost of option(s) for a purchase (18 decimals)
    /// @param isPremiumNormalized Whether the premium given is already normalized by strike or not (Ex: For a strike of
    ///        1500, and a premium of 750, the normalized premium would be 0.5)
    /// @param strike The strike of the option (18 decimals)
    /// @param isCallPool Whether the pool is a call pool or not
    /// @param isOrderbook Whether the fee is for the `fillQuoteOB` function or not
    /// @return The taker fee for an option trade denormalized. (18 decimals)
    function _takerFee(
        address taker,
        UD60x18 size,
        UD60x18 premium,
        bool isPremiumNormalized,
        UD60x18 strike,
        bool isCallPool,
        bool isOrderbook
    ) internal view returns (UD60x18) {
        if (!isPremiumNormalized) {
            // Normalize premium
            premium = Position.collateralToContracts(premium, strike, isCallPool);
        }

        UD60x18 fee;
        if (isOrderbook) {
            fee = PRBMathExtra.min(premium * MAX_PREMIUM_FEE_PERCENTAGE, size * ORDERBOOK_NOTIONAL_FEE_PERCENTAGE);
        } else {
            UD60x18 notionalFee = size * AMM_NOTIONAL_FEE_PERCENTAGE;
            UD60x18 premiumFee = (premium == ZERO) ? notionalFee : premium * AMM_PREMIUM_FEE_PERCENTAGE;
            UD60x18 maxFee = (premium == ZERO) ? notionalFee : premium * MAX_PREMIUM_FEE_PERCENTAGE;

            fee = PRBMathExtra.min(maxFee, PRBMathExtra.max(premiumFee, notionalFee));
        }

        UD60x18 discount;
        if (taker != address(0)) discount = ud(IVxPremia(VXPREMIA).getDiscount(taker));
        if (discount > ZERO) fee = (ONE - discount) * fee;

        return Position.contractsToCollateral(fee, strike, isCallPool);
    }

    /// @notice Calculates the fee for an exercise. It is the minimum between a percentage of the intrinsic
    /// value of options exercised, or a percentage of the notional value.
    /// @param taker The taker of a trade
    /// @param size The size of a trade (number of contracts) (18 decimals)
    /// @param intrinsicValue Total intrinsic value of all the contracts exercised, denormalized (18 decimals)
    /// @param strike The strike of the option (18 decimals)
    /// @param isCallPool Whether the pool is a call pool or not
    /// @return The fee to exercise an option, denormalized (18 decimals)
    function _exerciseFee(
        address taker,
        UD60x18 size,
        UD60x18 intrinsicValue,
        UD60x18 strike,
        bool isCallPool
    ) internal view returns (UD60x18) {
        UD60x18 notionalFee = Position.contractsToCollateral(size, strike, isCallPool) * EXERCISE_FEE_PERCENTAGE;
        UD60x18 intrinsicValueFee = intrinsicValue * MAX_EXERCISE_FEE_PERCENTAGE;

        UD60x18 fee = PRBMathExtra.min(notionalFee, intrinsicValueFee);

        UD60x18 discount;
        if (taker != address(0)) discount = ud(IVxPremia(VXPREMIA).getDiscount(taker));
        if (discount > ZERO) fee = (ONE - discount) * fee;
        return fee;
    }

    /// @notice Gives a quote for a trade
    /// @param taker The taker of the trade
    /// @param size The number of contracts being traded (18 decimals)
    /// @param isBuy Whether the taker is buying or selling
    /// @return totalNetPremium The premium which has to be paid to complete the trade (Net of fees) (poolToken decimals)
    /// @return totalTakerFee The taker fees to pay (Included in `premiumNet`) (poolToken decimals)
    function _getQuoteAMM(
        address taker,
        UD60x18 size,
        bool isBuy
    ) internal view returns (uint256 totalNetPremium, uint256 totalTakerFee) {
        PoolStorage.Layout storage l = PoolStorage.layout();

        _revertIfZeroSize(size);
        _revertIfOptionExpired(l);

        Pricing.Args memory pricing = Pricing.Args(
            l.liquidityRate,
            l.marketPrice,
            l.currentTick,
            l.tickIndex.next(l.currentTick),
            isBuy
        );

        QuoteAMMVarsInternal memory vars;
        vars.liquidity = pricing.liquidity();
        vars.maxSize = pricing.maxTradeSize();

        while (size > ZERO) {
            UD60x18 tradeSize = PRBMathExtra.min(size, vars.maxSize);

            UD50x28 nextPrice;
            // Compute next price
            if (vars.liquidity == ZERO || tradeSize == vars.maxSize) {
                nextPrice = (isBuy ? pricing.upper : pricing.lower).intoUD50x28();
            } else {
                UD50x28 priceDelta = ((pricing.upper - pricing.lower).intoUD50x28() * tradeSize.intoUD50x28()) /
                    vars.liquidity.intoUD50x28();
                nextPrice = isBuy ? pricing.marketPrice + priceDelta : pricing.marketPrice - priceDelta;
            }

            if (tradeSize > ZERO) {
                UD60x18 premium = (pricing.marketPrice.avg(nextPrice) * tradeSize.intoUD50x28()).intoUD60x18();

                UD60x18 takerFee = _takerFee(taker, tradeSize, premium, true, l.strike, l.isCallPool, false);

                // Denormalize premium
                premium = Position.contractsToCollateral(premium, l.strike, l.isCallPool);

                vars.totalTakerFee = vars.totalTakerFee + takerFee;
                vars.totalPremium = vars.totalPremium + premium;
            }

            pricing.marketPrice = nextPrice;

            if (vars.maxSize >= size) {
                size = ZERO;
            } else {
                // Cross tick
                size = size - vars.maxSize;

                // Adjust liquidity rate
                pricing.liquidityRate = pricing.liquidityRate.add(l.ticks[isBuy ? pricing.upper : pricing.lower].delta);

                // Set new lower and upper bounds
                pricing.lower = isBuy ? pricing.upper : l.tickIndex.prev(pricing.lower);
                pricing.upper = l.tickIndex.next(pricing.lower);

                if (pricing.upper == ZERO) revert Pool__InsufficientLiquidity();

                // Compute new liquidity
                vars.liquidity = pricing.liquidity();
                vars.maxSize = pricing.maxTradeSize();
            }
        }

        return (
            l.toPoolTokenDecimals(
                isBuy ? vars.totalPremium + vars.totalTakerFee : vars.totalPremium - vars.totalTakerFee
            ),
            l.toPoolTokenDecimals(vars.totalTakerFee)
        );
    }

    /// @notice Returns amount of claimable fees from pending update of claimable fees for the position. This does not
    ///         include pData.claimableFees
    function _pendingClaimableFees(
        PoolStorage.Layout storage l,
        Position.KeyInternal memory p,
        Position.Data storage pData,
        UD60x18 balance
    ) internal view returns (UD60x18 claimableFees, SD49x28 feeRate) {
        Tick memory lowerTick = _getTick(p.lower);
        Tick memory upperTick = _getTick(p.upper);

        feeRate = _rangeFeeRate(l, p.lower, p.upper, lowerTick.externalFeeRate, upperTick.externalFeeRate);
        claimableFees = _calculateClaimableFees(feeRate, pData.lastFeeRate, p.liquidityPerTick(balance));
    }

    /// @notice Returns the amount of fees an LP can claim for a position (without claiming)
    function _calculateClaimableFees(
        SD49x28 feeRate,
        SD49x28 lastFeeRate,
        UD50x28 liquidityPerTick
    ) internal pure returns (UD60x18) {
        return ((feeRate - lastFeeRate).intoUD50x28() * liquidityPerTick).intoUD60x18();
    }

    /// @notice Updates the amount of fees an LP can claim for a position (without claiming)
    function _updateClaimableFees(Position.Data storage pData, SD49x28 feeRate, UD50x28 liquidityPerTick) internal {
        pData.claimableFees =
            pData.claimableFees +
            _calculateClaimableFees(feeRate, pData.lastFeeRate, liquidityPerTick);

        // Reset the initial range rate of the position
        pData.lastFeeRate = feeRate;
    }

    /// @notice Updates the amount of fees an LP can claim for a position
    function _updateClaimableFees(
        PoolStorage.Layout storage l,
        Position.KeyInternal memory p,
        Position.Data storage pData,
        UD60x18 balance
    ) internal {
        (UD60x18 claimableFees, SD49x28 feeRate) = _pendingClaimableFees(l, p, pData, balance);
        pData.claimableFees = pData.claimableFees + claimableFees;
        pData.lastFeeRate = feeRate;
    }

    /// @notice Updates the claimable fees of a position and transfers the claimed fees to the operator of the position.
    ///         Then resets the claimable fees to zero.
    /// @param p The position to claim fees for
    /// @return The amount of fees claimed (poolToken decimals)
    function _claim(Position.KeyInternal memory p) internal returns (uint256) {
        PoolStorage.Layout storage l = PoolStorage.layout();

        if (l.protocolFees > ZERO) _claimProtocolFees();

        uint256 tokenId = PoolStorage.formatTokenId(p.operator, p.lower, p.upper, p.orderType);
        UD60x18 balance = _balanceOfUD60x18(p.owner, tokenId);
        _revertIfPositionDoesNotExist(p.owner, tokenId, balance);

        Position.Data storage pData = l.positions[p.keyHash()];
        _updateClaimableFees(l, p, pData, balance);

        UD60x18 _claimedFees = pData.claimableFees;
        if (_claimedFees == ZERO) return 0;

        pData.claimableFees = ZERO;
        IERC20(l.getPoolToken()).safeTransferIgnoreDust(p.operator, _claimedFees);

        emit ClaimFees(
            p.owner,
            PoolStorage.formatTokenId(p.operator, p.lower, p.upper, p.orderType),
            _claimedFees,
            pData.lastFeeRate.intoSD59x18()
        );

        return l.toPoolTokenDecimals(_claimedFees);
    }

    /// @notice Claims the protocol fees and transfers them to the fee receiver
    function _claimProtocolFees() internal {
        PoolStorage.Layout storage l = PoolStorage.layout();
        UD60x18 claimedFees = l.protocolFees;

        if (claimedFees == ZERO) return;

        l.protocolFees = ZERO;
        IERC20(l.getPoolToken()).safeTransferIgnoreDust(FEE_RECEIVER, claimedFees);
        emit ClaimProtocolFees(FEE_RECEIVER, claimedFees);
    }

    /// @notice Deposits a `position` (combination of owner/operator, price range, bid/ask collateral, and long/short
    ///         contracts) into the pool.
    /// @param p The position key
    /// @param args The deposit parameters
    /// @return delta The amount of collateral / longs / shorts deposited
    function _deposit(
        Position.KeyInternal memory p,
        DepositArgsInternal memory args
    ) internal returns (Position.Delta memory delta) {
        return
            _deposit(
                p,
                args,
                // We default to isBid = true if orderType is long and isBid = false if orderType is short, so that
                // default behavior in case of stranded market price is to deposit collateral
                p.orderType.isLong()
            );
    }

    /// @notice Deposits a `position` (combination of owner/operator, price range, bid/ask collateral, and long/short
    ///         contracts) into the pool.
    /// @param p The position key
    /// @param args The deposit parameters
    /// @param isBidIfStrandedMarketPrice Whether this is a bid or ask order when the market price is stranded (This
    ///        argument doesnt matter if market price is not stranded)
    /// @return delta The amount of collateral / longs / shorts deposited
    function _deposit(
        Position.KeyInternal memory p,
        DepositArgsInternal memory args,
        bool isBidIfStrandedMarketPrice
    ) internal returns (Position.Delta memory delta) {
        PoolStorage.Layout storage l = PoolStorage.layout();

        uint256 tokenId = PoolStorage.formatTokenId(p.operator, p.lower, p.upper, p.orderType);
        uint256 balance = _balanceOf(p.owner, tokenId);

        Position.Data storage pData = l.positions[p.keyHash()];

        _revertIfInvalidPositionState(balance, pData.lastDeposit);
        pData.lastDeposit = block.timestamp;

        // Set the market price correctly in case it's stranded
        if (_isMarketPriceStranded(l, p, isBidIfStrandedMarketPrice)) {
            l.marketPrice = _getStrandedMarketPriceUpdate(p, isBidIfStrandedMarketPrice);
        }

        _revertIfDepositWithdrawalAboveMaxSlippage(
            l.marketPrice.intoUD60x18(),
            args.minMarketPrice,
            args.maxMarketPrice
        );
        _revertIfZeroSize(args.size);
        _revertIfOptionExpired(l);

        _revertIfRangeInvalid(p.lower, p.upper);
        _revertIfTickWidthInvalid(p.lower);
        _revertIfTickWidthInvalid(p.upper);
        _revertIfInvalidSize(p.lower, p.upper, args.size);

        delta = p.calculatePositionUpdate(ud(balance), args.size.intoSD59x18(), l.marketPrice);

        _transferTokens(
            l,
            p.operator,
            address(this),
            l.toPoolTokenDecimals(delta.collateral.intoUD60x18()),
            delta.longs.intoUD60x18(),
            delta.shorts.intoUD60x18()
        );

        _depositFeeAndTicksUpdate(l, pData, p, args.belowLower, args.belowUpper, args.size, tokenId);

        emit Deposit(
            p.owner,
            tokenId,
            delta.collateral.intoUD60x18(),
            delta.longs.intoUD60x18(),
            delta.shorts.intoUD60x18(),
            pData.lastFeeRate.intoSD59x18(),
            pData.claimableFees,
            l.marketPrice.intoUD60x18(),
            l.liquidityRate.intoUD60x18(),
            l.currentTick
        );
    }

    /// @notice Handles fee/tick updates and mints LP token on deposit
    function _depositFeeAndTicksUpdate(
        PoolStorage.Layout storage l,
        Position.Data storage pData,
        Position.KeyInternal memory p,
        UD60x18 belowLower,
        UD60x18 belowUpper,
        UD60x18 size,
        uint256 tokenId
    ) internal {
        SD49x28 feeRate;
        {
            // If ticks dont exist they are created and inserted into the linked list
            Tick memory lowerTick = _getOrCreateTick(p.lower, belowLower);
            Tick memory upperTick = _getOrCreateTick(p.upper, belowUpper);

            feeRate = _rangeFeeRate(l, p.lower, p.upper, lowerTick.externalFeeRate, upperTick.externalFeeRate);
        }

        {
            UD60x18 initialSize = _balanceOfUD60x18(p.owner, tokenId);
            UD50x28 liquidityPerTick;

            if (initialSize > ZERO) {
                liquidityPerTick = p.liquidityPerTick(initialSize);

                _updateClaimableFees(pData, feeRate, liquidityPerTick);
            } else {
                pData.lastFeeRate = feeRate;
            }

            _mint(p.owner, tokenId, size);

            SD49x28 tickDelta = p.liquidityPerTick(_balanceOfUD60x18(p.owner, tokenId)).intoSD49x28() -
                liquidityPerTick.intoSD49x28();

            // Adjust tick deltas
            _updateTicks(p.lower, p.upper, l.marketPrice, tickDelta, initialSize == ZERO, false, p.orderType);
        }

        // Safeguard, should never happen
        if (
            feeRate !=
            _rangeFeeRate(l, p.lower, p.upper, l.ticks[p.lower].externalFeeRate, l.ticks[p.upper].externalFeeRate)
        ) revert Pool__InvalidTickUpdate();
    }

    /// @notice Withdraws a `position` (combination of owner/operator, price range, bid/ask collateral, and long/short
    ///         contracts) from the pool
    ///         Tx will revert if market price is not between `minMarketPrice` and `maxMarketPrice`.
    /// @param p The position key
    /// @param size The position size to withdraw (18 decimals)
    /// @param minMarketPrice Min market price, as normalized value. (If below, tx will revert) (18 decimals)
    /// @param maxMarketPrice Max market price, as normalized value. (If above, tx will revert) (18 decimals)
    /// @param transferCollateralToUser Whether to transfer collateral to user or not if collateral value is positive.
    ///        Should be false if that collateral is used for a swap
    /// @return delta The amount of collateral / longs / shorts withdrawn
    function _withdraw(
        Position.KeyInternal memory p,
        UD60x18 size,
        UD60x18 minMarketPrice,
        UD60x18 maxMarketPrice,
        bool transferCollateralToUser
    ) internal returns (Position.Delta memory delta) {
        PoolStorage.Layout storage l = PoolStorage.layout();
        _revertIfOptionExpired(l);

        _revertIfDepositWithdrawalAboveMaxSlippage(l.marketPrice.intoUD60x18(), minMarketPrice, maxMarketPrice);
        _revertIfZeroSize(size);
        _revertIfRangeInvalid(p.lower, p.upper);
        _revertIfTickWidthInvalid(p.lower);
        _revertIfTickWidthInvalid(p.upper);
        _revertIfInvalidSize(p.lower, p.upper, size);

        WithdrawVarsInternal memory vars;

        vars.pKeyHash = p.keyHash();
        Position.Data storage pData = l.positions[vars.pKeyHash];

        _revertIfWithdrawalDelayNotElapsed(pData);

        vars.tokenId = PoolStorage.formatTokenId(p.operator, p.lower, p.upper, p.orderType);
        vars.initialSize = _balanceOfUD60x18(p.owner, vars.tokenId);
        _revertIfPositionDoesNotExist(p.owner, vars.tokenId, vars.initialSize);

        vars.isFullWithdrawal = vars.initialSize == size;

        {
            Tick memory lowerTick = _getTick(p.lower);
            Tick memory upperTick = _getTick(p.upper);

            // Initialize variables before position update
            vars.liquidityPerTick = p.liquidityPerTick(vars.initialSize);
            SD49x28 feeRate = _rangeFeeRate(l, p.lower, p.upper, lowerTick.externalFeeRate, upperTick.externalFeeRate);

            // Update claimable fees
            _updateClaimableFees(pData, feeRate, vars.liquidityPerTick);
        }

        // Check whether it's a full withdrawal before updating the position

        {
            UD60x18 collateralToTransfer;
            if (vars.isFullWithdrawal) {
                UD60x18 feesClaimed = pData.claimableFees;
                // Claim all fees and remove the position completely
                collateralToTransfer = collateralToTransfer + feesClaimed;
                _deletePosition(l, vars.pKeyHash);
                emit ClaimFees(p.owner, vars.tokenId, feesClaimed, iZERO);
            }

            delta = p.calculatePositionUpdate(vars.initialSize, -size.intoSD59x18(), l.marketPrice);

            delta.collateral = delta.collateral.abs();
            delta.longs = delta.longs.abs();
            delta.shorts = delta.shorts.abs();

            collateralToTransfer = collateralToTransfer + delta.collateral.intoUD60x18();

            _burn(p.owner, vars.tokenId, size);

            _transferTokens(
                l,
                address(this),
                p.operator,
                transferCollateralToUser ? l.toPoolTokenDecimals(collateralToTransfer) : 0,
                delta.longs.intoUD60x18(),
                delta.shorts.intoUD60x18()
            );
        }

        vars.tickDelta =
            p.liquidityPerTick(_balanceOfUD60x18(p.owner, vars.tokenId)).intoSD49x28() -
            vars.liquidityPerTick.intoSD49x28();

        _updateTicks(
            p.lower,
            p.upper,
            l.marketPrice,
            vars.tickDelta, // Adjust tick deltas (reverse of deposit)
            false,
            vars.isFullWithdrawal,
            p.orderType
        );

        emit Withdrawal(
            p.owner,
            vars.tokenId,
            delta.collateral.intoUD60x18(),
            delta.longs.intoUD60x18(),
            delta.shorts.intoUD60x18(),
            pData.lastFeeRate.intoSD59x18(),
            pData.claimableFees,
            l.marketPrice.intoUD60x18(),
            l.liquidityRate.intoUD60x18(),
            l.currentTick
        );
    }

    /// @notice Handle transfer of collateral / longs / shorts on deposit or withdrawal
    /// @dev WARNING: `collateral` must be scaled to the collateral token decimals
    function _transferTokens(
        PoolStorage.Layout storage l,
        address from,
        address to,
        uint256 collateral,
        UD60x18 longs,
        UD60x18 shorts
    ) internal {
        // Safeguard, should never happen
        if (longs > ZERO && shorts > ZERO) revert Pool__PositionCantHoldLongAndShort(longs, shorts);

        address poolToken = l.getPoolToken();

        if (from == address(this)) {
            IERC20(poolToken).safeTransferIgnoreDust(to, collateral);
        } else {
            IERC20Router(ROUTER).safeTransferFrom(poolToken, from, to, collateral);
        }

        if (longs + shorts > ZERO) {
            uint256 id = longs > ZERO ? PoolStorage.LONG : PoolStorage.SHORT;
            uint256 amount = longs > ZERO ? longs.unwrap() : shorts.unwrap();

            if (to == address(this)) {
                // We bypass the acceptance check by using `_transfer` instead of `_safeTransfer if transferring to the pool,
                // so that we do not have to blindly accept any transfer
                _transfer(address(this), from, to, id, amount, "");
            } else {
                _safeTransfer(address(this), from, to, id, amount, "");
            }
        }
    }

    /// @notice Transfers collateral + fees from `underwriter` and sends long/short tokens to both parties
    function _writeFrom(address underwriter, address longReceiver, UD60x18 size, address referrer) internal {
        if (
            msg.sender != underwriter &&
            !IUserSettings(SETTINGS).isActionAuthorized(underwriter, msg.sender, IUserSettings.Action.WriteFrom)
        ) revert Pool__ActionNotAuthorized(underwriter, msg.sender, IUserSettings.Action.WriteFrom);

        PoolStorage.Layout storage l = PoolStorage.layout();

        _revertIfZeroSize(size);
        _revertIfOptionExpired(l);

        UD60x18 collateral = Position.contractsToCollateral(size, l.strike, l.isCallPool);

        address taker = underwriter;
        if (IVaultRegistry(VAULT_REGISTRY).isVault(msg.sender)) {
            taker = longReceiver;
        }

        UD60x18 protocolFee = _takerFee(taker, size, ZERO, true, l.strike, l.isCallPool, false);
        IERC20Router(ROUTER).safeTransferFrom(l.getPoolToken(), underwriter, address(this), collateral + protocolFee);

        (UD60x18 primaryReferralRebate, UD60x18 secondaryReferralRebate) = IReferral(REFERRAL).getRebateAmounts(
            taker,
            referrer,
            protocolFee
        );

        _useReferral(l, taker, referrer, primaryReferralRebate, secondaryReferralRebate);
        l.protocolFees = l.protocolFees + protocolFee - (primaryReferralRebate + secondaryReferralRebate);

        _mint(underwriter, PoolStorage.SHORT, size);
        _mint(longReceiver, PoolStorage.LONG, size);

        emit WriteFrom(underwriter, longReceiver, taker, size, collateral, protocolFee);
    }

    /// @notice Completes a trade of `size` on `side` via the AMM using the liquidity in the Pool.
    /// @param args Trade parameters
    /// @return totalPremium The premium paid or received by the taker for the trade (poolToken decimals)
    /// @return delta The net collateral / longs / shorts change for taker of the trade.
    function _trade(
        TradeArgsInternal memory args
    ) internal returns (uint256 totalPremium, Position.Delta memory delta) {
        PoolStorage.Layout storage l = PoolStorage.layout();

        _revertIfZeroSize(args.size);
        _revertIfOptionExpired(l);

        TradeVarsInternal memory vars;

        {
            UD60x18 remaining = args.size;

            while (remaining > ZERO) {
                Pricing.Args memory pricing = _getPricing(l, args.isBuy);
                vars.maxSize = pricing.maxTradeSize();
                vars.tradeSize = PRBMathExtra.min(remaining, vars.maxSize);
                vars.oldMarketPrice = l.marketPrice;

                {
                    UD50x28 nextMarketPrice;
                    if (vars.tradeSize != vars.maxSize) {
                        nextMarketPrice = pricing.nextPrice(vars.tradeSize);
                    } else {
                        nextMarketPrice = (args.isBuy ? pricing.upper : pricing.lower).intoUD50x28();
                    }

                    UD60x18 premium;

                    {
                        UD50x28 quoteAMMPrice = l.marketPrice.avg(nextMarketPrice);
                        premium = (quoteAMMPrice * vars.tradeSize.intoUD50x28()).intoUD60x18();
                    }

                    UD60x18 takerFee = _takerFee(
                        args.user,
                        vars.tradeSize,
                        premium,
                        true,
                        l.strike,
                        l.isCallPool,
                        false
                    );

                    // Denormalize premium
                    premium = Position.contractsToCollateral(premium, l.strike, l.isCallPool);

                    // Update price and liquidity variables
                    {
                        (UD60x18 primaryReferralRebate, UD60x18 secondaryReferralRebate) = IReferral(REFERRAL)
                            .getRebateAmounts(args.user, args.referrer, takerFee);

                        UD60x18 totalReferralRebate = primaryReferralRebate + secondaryReferralRebate;
                        vars.referral.totalRebate = vars.referral.totalRebate + totalReferralRebate;
                        vars.referral.primaryRebate = vars.referral.primaryRebate + primaryReferralRebate;
                        vars.referral.secondaryRebate = vars.referral.secondaryRebate + secondaryReferralRebate;

                        UD60x18 takerFeeSansRebate = takerFee - totalReferralRebate;
                        UD60x18 protocolFee = takerFeeSansRebate * PROTOCOL_FEE_PERCENTAGE;
                        UD60x18 makerRebate = takerFeeSansRebate - protocolFee;

                        _updateGlobalFeeRate(l, makerRebate);

                        vars.totalProtocolFees = vars.totalProtocolFees + protocolFee;
                        l.protocolFees = l.protocolFees + protocolFee;
                    }

                    // is_buy: taker has to pay premium + fees
                    // ~is_buy: taker receives premium - fees
                    vars.totalPremium = vars.totalPremium + (args.isBuy ? premium + takerFee : premium - takerFee);
                    vars.totalTakerFees = vars.totalTakerFees + takerFee;
                    l.marketPrice = nextMarketPrice;
                }

                UD50x28 dist = (l.marketPrice.intoSD49x28() - vars.oldMarketPrice.intoSD49x28()).abs().intoUD50x28();

                vars.shortDelta =
                    vars.shortDelta +
                    (l.shortRate * (dist / PoolStorage.MIN_TICK_DISTANCE.intoUD50x28()));
                vars.longDelta = vars.longDelta + (l.longRate * (dist / PoolStorage.MIN_TICK_DISTANCE.intoUD50x28()));

                if (vars.maxSize >= remaining) {
                    remaining = ZERO;
                } else {
                    // The trade will require crossing into the next tick range
                    if (args.isBuy && l.tickIndex.next(l.currentTick) >= PoolStorage.MAX_TICK_PRICE)
                        revert Pool__InsufficientAskLiquidity();

                    if (!args.isBuy && l.currentTick <= PoolStorage.MIN_TICK_PRICE)
                        revert Pool__InsufficientBidLiquidity();

                    remaining = remaining - vars.tradeSize;
                    _cross(args.isBuy);
                }
            }
        }

        totalPremium = l.toPoolTokenDecimals(vars.totalPremium);

        _revertIfTradeAboveMaxSlippage(totalPremium, args.premiumLimit, args.isBuy);

        delta = _calculateAndUpdateUserAssets(
            l,
            args.user,
            vars.totalPremium,
            args.size,
            args.isBuy,
            args.transferCollateralToUser
        );

        _useReferral(l, args.user, args.referrer, vars.referral.primaryRebate, vars.referral.secondaryRebate);

        if (args.isBuy) {
            if (vars.shortDelta > UD50_ZERO) _mint(address(this), PoolStorage.SHORT, vars.shortDelta.intoUD60x18());
            if (vars.longDelta > UD50_ZERO) _burn(address(this), PoolStorage.LONG, vars.longDelta.intoUD60x18());
        } else {
            if (vars.longDelta > UD50_ZERO) _mint(address(this), PoolStorage.LONG, vars.longDelta.intoUD60x18());
            if (vars.shortDelta > UD50_ZERO) _burn(address(this), PoolStorage.SHORT, vars.shortDelta.intoUD60x18());
        }

        emit Trade(
            args.user,
            args.size,
            delta,
            args.isBuy ? vars.totalPremium - vars.totalTakerFees : vars.totalPremium,
            vars.totalTakerFees,
            vars.totalProtocolFees,
            l.marketPrice.intoUD60x18(),
            l.liquidityRate.intoUD60x18(),
            l.currentTick,
            vars.referral.totalRebate,
            args.isBuy
        );
    }

    /// @notice Returns the pricing arguments at the current tick
    function _getPricing(PoolStorage.Layout storage l, bool isBuy) internal view returns (Pricing.Args memory) {
        UD60x18 currentTick = l.currentTick;

        return Pricing.Args(l.liquidityRate, l.marketPrice, currentTick, l.tickIndex.next(currentTick), isBuy);
    }

    /// @notice Compute the change in short / long option contracts of an agent in order to transfer the contracts and
    ///         execute a trade
    function _getTradeDelta(
        address user,
        UD60x18 size,
        bool isBuy
    ) internal view returns (Position.Delta memory delta) {
        UD60x18 longs = _balanceOfUD60x18(user, PoolStorage.LONG);
        UD60x18 shorts = _balanceOfUD60x18(user, PoolStorage.SHORT);

        if (isBuy) {
            delta.shorts = -PRBMathExtra.min(shorts, size).intoSD59x18();
            delta.longs = size.intoSD59x18() + delta.shorts;
        } else {
            delta.longs = -PRBMathExtra.min(longs, size).intoSD59x18();
            delta.shorts = size.intoSD59x18() + delta.longs;
        }
    }

    // @notice Calculate the asset update for `user` and update the user's assets
    function _calculateAndUpdateUserAssets(
        PoolStorage.Layout storage l,
        address user,
        UD60x18 totalPremium,
        UD60x18 size,
        bool isBuy,
        bool transferCollateralToUser
    ) internal returns (Position.Delta memory delta) {
        delta = _calculateAssetsUpdate(l, user, totalPremium, size, isBuy);
        _updateUserAssets(l, user, delta, transferCollateralToUser);
    }

    /// @notice Calculate the asset update for `user`
    function _calculateAssetsUpdate(
        PoolStorage.Layout storage l,
        address user,
        UD60x18 totalPremium,
        UD60x18 size,
        bool isBuy
    ) internal view returns (Position.Delta memory delta) {
        delta = _getTradeDelta(user, size, isBuy);

        bool _isBuy = delta.longs > iZERO || delta.shorts < iZERO;

        UD60x18 shortCollateral = Position.contractsToCollateral(
            delta.shorts.abs().intoUD60x18(),
            l.strike,
            l.isCallPool
        );

        SD59x18 iShortCollateral = shortCollateral.intoSD59x18();
        if (delta.shorts < iZERO) {
            iShortCollateral = -iShortCollateral;
        }

        if (_isBuy) {
            delta.collateral = -PRBMathExtra.min(iShortCollateral, iZERO) - totalPremium.intoSD59x18();
        } else {
            delta.collateral = totalPremium.intoSD59x18() - PRBMathExtra.max(iShortCollateral, iZERO);
        }

        return delta;
    }

    /// @notice Execute a trade by transferring the net change in short and long option contracts and collateral to /
    ///         from an agent.
    function _updateUserAssets(
        PoolStorage.Layout storage l,
        address user,
        Position.Delta memory delta,
        bool transferCollateralToUser
    ) internal {
        if (
            (delta.longs == iZERO && delta.shorts == iZERO) ||
            (delta.longs > iZERO && delta.shorts > iZERO) ||
            (delta.longs < iZERO && delta.shorts < iZERO)
        ) revert Pool__InvalidAssetUpdate(delta.longs, delta.shorts);

        int256 deltaCollateral = l.toPoolTokenDecimals(delta.collateral);

        // Transfer collateral
        if (deltaCollateral < 0) {
            IERC20Router(ROUTER).safeTransferFrom(l.getPoolToken(), user, address(this), uint256(-deltaCollateral));
        } else if (deltaCollateral > 0 && transferCollateralToUser) {
            IERC20(l.getPoolToken()).safeTransferIgnoreDust(user, uint256(deltaCollateral));
        }

        // Transfer long
        if (delta.longs < iZERO) {
            _burn(user, PoolStorage.LONG, (-delta.longs).intoUD60x18());
        } else if (delta.longs > iZERO) {
            _mint(user, PoolStorage.LONG, delta.longs.intoUD60x18());
        }

        // Transfer short
        if (delta.shorts < iZERO) {
            _burn(user, PoolStorage.SHORT, (-delta.shorts).intoUD60x18());
        } else if (delta.shorts > iZERO) {
            _mint(user, PoolStorage.SHORT, delta.shorts.intoUD60x18());
        }
    }

    /// @notice Calculates the OB quote premium and fee
    function _calculateQuoteOBPremiumAndFee(
        PoolStorage.Layout storage l,
        address taker,
        address referrer,
        UD60x18 size,
        UD60x18 price,
        bool isBuy
    ) internal view returns (PremiumAndFeeInternal memory r) {
        r.premium = price * size;
        r.protocolFee = _takerFee(taker, size, r.premium, true, l.strike, l.isCallPool, true);

        (UD60x18 primaryReferralRebate, UD60x18 secondaryReferralRebate) = IReferral(REFERRAL).getRebateAmounts(
            taker,
            referrer,
            r.protocolFee
        );

        r.referral.totalRebate = primaryReferralRebate + secondaryReferralRebate;
        r.referral.primaryRebate = primaryReferralRebate;
        r.referral.secondaryRebate = secondaryReferralRebate;

        r.protocolFee = r.protocolFee - r.referral.totalRebate;

        // Denormalize premium
        r.premium = Position.contractsToCollateral(r.premium, l.strike, l.isCallPool);

        r.premiumMaker = isBuy
            ? r.premium // Maker buying
            : r.premium - r.protocolFee; // Maker selling

        r.premiumTaker = !isBuy
            ? r.premium // Taker buying
            : r.premium - r.protocolFee; // Taker selling

        return r;
    }

    /// @notice Functionality to support the OB / OTC system. An LP can create a OB quote for which he will do an OTC
    ///         trade through the exchange. Takers can buy from / sell to the LP then partially or fully while having
    ///         the price guaranteed.
    /// @param args The fillQuoteOB parameters
    /// @param quoteOB The OB quote given by the provider
    /// @return premiumTaker The premium paid by the taker (poolToken decimals)
    /// @return deltaTaker The net collateral / longs / shorts change for taker of the trade.
    function _fillQuoteOB(
        FillQuoteOBArgsInternal memory args,
        QuoteOB memory quoteOB
    ) internal returns (uint256 premiumTaker, Position.Delta memory deltaTaker) {
        if (args.size > quoteOB.size) revert Pool__AboveQuoteSize(args.size, quoteOB.size);

        bytes32 quoteOBHash;
        PremiumAndFeeInternal memory premiumAndFee;
        Position.Delta memory deltaMaker;

        {
            PoolStorage.Layout storage l = PoolStorage.layout();
            quoteOBHash = _quoteOBHash(quoteOB);
            _revertIfQuoteOBInvalid(l, args, quoteOB, quoteOBHash);

            premiumAndFee = _calculateQuoteOBPremiumAndFee(
                l,
                args.user,
                args.referrer,
                args.size,
                quoteOB.price,
                quoteOB.isBuy
            );

            // Update amount filled for this quote
            l.quoteOBAmountFilled[quoteOB.provider][quoteOBHash] =
                l.quoteOBAmountFilled[quoteOB.provider][quoteOBHash] +
                args.size;

            // Update protocol fees
            l.protocolFees = l.protocolFees + premiumAndFee.protocolFee;

            // Process trade taker
            deltaTaker = _calculateAndUpdateUserAssets(
                l,
                args.user,
                premiumAndFee.premiumTaker,
                args.size,
                !quoteOB.isBuy,
                args.transferCollateralToUser
            );

            _useReferral(
                l,
                args.user,
                args.referrer,
                premiumAndFee.referral.primaryRebate,
                premiumAndFee.referral.secondaryRebate
            );

            // Process trade maker
            deltaMaker = _calculateAndUpdateUserAssets(
                l,
                quoteOB.provider,
                premiumAndFee.premiumMaker,
                args.size,
                quoteOB.isBuy,
                true
            );
        }

        emit FillQuoteOB(
            quoteOBHash,
            args.user,
            quoteOB.provider,
            args.size,
            deltaMaker,
            deltaTaker,
            premiumAndFee.premium,
            premiumAndFee.protocolFee,
            premiumAndFee.referral.totalRebate,
            !quoteOB.isBuy
        );

        return (PoolStorage.layout().toPoolTokenDecimals(premiumAndFee.premiumTaker), deltaTaker);
    }

    /// @notice Annihilate a pair of long + short option contracts to unlock the stored collateral.
    /// @dev This function can be called post or prior to expiration.
    function _annihilate(address owner, UD60x18 size) internal {
        if (
            msg.sender != owner &&
            !IUserSettings(SETTINGS).isActionAuthorized(owner, msg.sender, IUserSettings.Action.Annihilate)
        ) revert Pool__ActionNotAuthorized(owner, msg.sender, IUserSettings.Action.Annihilate);

        _revertIfZeroSize(size);

        PoolStorage.Layout storage l = PoolStorage.layout();

        _burn(owner, PoolStorage.SHORT, size);
        _burn(owner, PoolStorage.LONG, size);
        IERC20(l.getPoolToken()).safeTransferIgnoreDust(
            owner,
            Position.contractsToCollateral(size, l.strike, l.isCallPool)
        );

        emit Annihilate(owner, size, 0);
    }

    /// @notice Transfer an LP position to another owner.
    /// @dev This function can be called post or prior to expiration.
    /// @param srcP The position key
    /// @param newOwner The new owner of the transferred liquidity
    /// @param newOperator The new operator of the transferred liquidity
    function _transferPosition(
        Position.KeyInternal memory srcP,
        address newOwner,
        address newOperator,
        UD60x18 size
    ) internal {
        if (srcP.owner == newOwner && srcP.operator == newOperator) revert Pool__InvalidTransfer();

        _revertIfZeroSize(size);
        _revertIfInvalidSize(srcP.lower, srcP.upper, size);

        PoolStorage.Layout storage l = PoolStorage.layout();

        Position.KeyInternal memory dstP = Position.KeyInternal({
            owner: newOwner,
            operator: newOperator,
            lower: srcP.lower,
            upper: srcP.upper,
            orderType: srcP.orderType,
            strike: srcP.strike,
            isCall: srcP.isCall
        });

        bytes32 srcKeyHash = srcP.keyHash();

        uint256 srcTokenId = PoolStorage.formatTokenId(srcP.operator, srcP.lower, srcP.upper, srcP.orderType);
        UD60x18 srcPOwnerBalance = _balanceOfUD60x18(srcP.owner, srcTokenId);

        _revertIfPositionDoesNotExist(srcP.owner, srcTokenId, srcPOwnerBalance);
        if (size > srcPOwnerBalance) revert Pool__NotEnoughTokens(srcPOwnerBalance, size);

        uint256 dstTokenId = srcP.operator == newOperator
            ? srcTokenId
            : PoolStorage.formatTokenId(newOperator, srcP.lower, srcP.upper, srcP.orderType);

        Position.Data storage dstData = l.positions[dstP.keyHash()];
        Position.Data storage srcData = l.positions[srcKeyHash];

        // Call function to update claimable fees, but do not claim them
        _updateClaimableFees(l, srcP, srcData, srcPOwnerBalance);

        {
            UD60x18 newOwnerBalance = _balanceOfUD60x18(newOwner, dstTokenId);
            if (newOwnerBalance > ZERO) {
                // Update claimable fees to reset the fee range rate
                _updateClaimableFees(l, dstP, dstData, newOwnerBalance);
            } else {
                dstData.lastFeeRate = srcData.lastFeeRate;
            }
        }

        {
            UD60x18 proportionTransferred = size.div(srcPOwnerBalance);
            UD60x18 feesTransferred = proportionTransferred * srcData.claimableFees;
            dstData.claimableFees = dstData.claimableFees + feesTransferred;
            srcData.claimableFees = srcData.claimableFees - feesTransferred;
        }

        if (srcData.lastDeposit > dstData.lastDeposit) {
            dstData.lastDeposit = srcData.lastDeposit;
        }

        if (srcTokenId == dstTokenId) {
            _safeTransfer(address(this), srcP.owner, newOwner, srcTokenId, size.unwrap(), "");
        } else {
            _burn(srcP.owner, srcTokenId, size);
            _mint(newOwner, dstTokenId, size);
        }

        if (size == srcPOwnerBalance) _deletePosition(l, srcKeyHash);

        emit TransferPosition(srcP.owner, newOwner, srcTokenId, dstTokenId);
    }

    /// @notice Calculates the exercise value of a position
    function _calculateExerciseValue(PoolStorage.Layout storage l, UD60x18 size) internal returns (UD60x18) {
        if (size == ZERO) return ZERO;

        UD60x18 settlementPrice = _tryCacheSettlementPrice(l);
        UD60x18 strike = l.strike;
        bool isCall = l.isCallPool;

        UD60x18 intrinsicValue;
        if (isCall && settlementPrice > strike) {
            intrinsicValue = settlementPrice - strike;
        } else if (!isCall && settlementPrice < strike) {
            intrinsicValue = strike - settlementPrice;
        } else {
            return ZERO;
        }

        UD60x18 exerciseValue = size * intrinsicValue;

        if (isCall) {
            exerciseValue = exerciseValue / settlementPrice;
        }

        return exerciseValue;
    }

    /// @notice Calculates the collateral value of a position
    function _calculateCollateralValue(
        PoolStorage.Layout storage l,
        UD60x18 size,
        UD60x18 exerciseValue
    ) internal view returns (UD60x18) {
        return l.isCallPool ? size - exerciseValue : size * l.strike - exerciseValue;
    }

    /// @notice Handle operations that need to be done before exercising or settling
    function _beforeExerciseOrSettle(
        PoolStorage.Layout storage l,
        bool isLong,
        address holder
    ) internal returns (UD60x18 size, UD60x18 exerciseValue, UD60x18 collateral) {
        _revertIfOptionNotExpired(l);
        _removeInitFeeDiscount(l);

        uint256 tokenId = isLong ? PoolStorage.LONG : PoolStorage.SHORT;
        size = _balanceOfUD60x18(holder, tokenId);
        exerciseValue = _calculateExerciseValue(l, size);

        if (size > ZERO) {
            collateral = _calculateCollateralValue(l, size, exerciseValue);
            _burn(holder, tokenId, size);
        }
    }

    /// @notice Exercises all long options held by an `owner`
    /// @param holder The holder of the contracts
    /// @param costPerHolder The cost charged by the authorized operator, per option holder (18 decimals)
    /// @return exerciseValue The amount of collateral resulting from the exercise, ignoring costs applied during
    ///         automatic exercise (poolToken decimals)
    /// @return exerciseFee The amount of fees paid to the protocol during exercise (18 decimals)
    /// @return success Whether the exercise was successful or not. This will be false if size to exercise size was zero
    function _exercise(
        address holder,
        UD60x18 costPerHolder
    ) internal returns (uint256 exerciseValue, uint256 exerciseFee, bool success) {
        PoolStorage.Layout storage l = PoolStorage.layout();

        (UD60x18 size, UD60x18 _exerciseValue, ) = _beforeExerciseOrSettle(l, true, holder);
        UD60x18 fee = _exerciseFee(holder, size, _exerciseValue, l.strike, l.isCallPool);

        l.protocolFees = l.protocolFees + fee;
        _exerciseValue = _exerciseValue - fee;

        if (size == ZERO) return (0, 0, false);
        _revertIfCostExceedsPayout(costPerHolder, _exerciseValue);

        if (l.protocolFees > ZERO) _claimProtocolFees();
        exerciseFee = l.toPoolTokenDecimals(fee);
        exerciseValue = l.toPoolTokenDecimals(_exerciseValue);

        emit Exercise(msg.sender, holder, size, _exerciseValue, l.settlementPrice, fee, costPerHolder);

        if (costPerHolder > ZERO) _exerciseValue = _exerciseValue - costPerHolder;
        if (_exerciseValue > ZERO) IERC20(l.getPoolToken()).safeTransferIgnoreDust(holder, _exerciseValue);

        success = true;
    }

    /// @notice Settles all short options held by an `owner`
    /// @param holder The holder of the contracts
    /// @param costPerHolder The cost charged by the authorized operator, per option holder (18 decimals)
    /// @return collateral The amount of collateral resulting from the settlement, ignoring costs applied during
    ///         automatic settlement (poolToken decimals)
    /// @return success Whether the settlement was successful or not. This will be false if size to settle was zero
    function _settle(address holder, UD60x18 costPerHolder) internal returns (uint256 collateral, bool success) {
        PoolStorage.Layout storage l = PoolStorage.layout();

        (UD60x18 size, UD60x18 exerciseValue, UD60x18 _collateral) = _beforeExerciseOrSettle(l, false, holder);

        if (size == ZERO) return (0, false);
        _revertIfCostExceedsPayout(costPerHolder, _collateral);

        if (l.protocolFees > ZERO) _claimProtocolFees();
        collateral = l.toPoolTokenDecimals(_collateral);

        emit Settle(msg.sender, holder, size, exerciseValue, l.settlementPrice, ZERO, costPerHolder);

        if (costPerHolder > ZERO) _collateral = _collateral - costPerHolder;
        if (_collateral > ZERO) IERC20(l.getPoolToken()).safeTransferIgnoreDust(holder, _collateral);

        success = true;
    }

    /// @notice Reconciles a user's `position` to account for settlement payouts post-expiration.
    /// @param p The position key
    /// @param costPerHolder The cost charged by the authorized operator, per position holder (18 decimals)
    /// @return collateral The amount of collateral resulting from the settlement, ignoring costs applied during
    ///         automatic settlement (poolToken decimals)
    /// @return success Whether the settlement was successful or not. This will be false if size to settle was zero
    function _settlePosition(
        Position.KeyInternal memory p,
        UD60x18 costPerHolder
    ) internal returns (uint256 collateral, bool success) {
        PoolStorage.Layout storage l = PoolStorage.layout();
        _revertIfOptionNotExpired(l);
        _removeInitFeeDiscount(l);

        if (l.protocolFees > ZERO) _claimProtocolFees();

        SettlePositionVarsInternal memory vars;

        vars.pKeyHash = p.keyHash();
        Position.Data storage pData = l.positions[vars.pKeyHash];

        vars.tokenId = PoolStorage.formatTokenId(p.operator, p.lower, p.upper, p.orderType);
        vars.size = _balanceOfUD60x18(p.owner, vars.tokenId);

        _revertIfInvalidPositionState(vars.size.unwrap(), pData.lastDeposit);

        if (vars.size == ZERO) {
            // Revert if costPerHolder > 0
            _revertIfCostExceedsPayout(costPerHolder, ZERO);
            return (0, false);
        }

        {
            // Update claimable fees
            SD49x28 feeRate = _rangeFeeRate(
                l,
                p.lower,
                p.upper,
                _getTick(p.lower).externalFeeRate,
                _getTick(p.upper).externalFeeRate
            );

            _updateClaimableFees(pData, feeRate, p.liquidityPerTick(vars.size));
        }

        // using the market price here is okay as the market price cannot be
        // changed through trades / deposits / withdrawals post-maturity.
        // changes to the market price are halted. thus, the market price
        // determines the amount of ask.
        // obviously, if the market was still liquid, the market price at
        // maturity should be close to the intrinsic value.

        {
            UD60x18 longs = p.long(vars.size, l.marketPrice);
            UD60x18 shorts = p.short(vars.size, l.marketPrice);

            vars.claimableFees = pData.claimableFees;
            vars.payoff = _calculateExerciseValue(l, ONE);

            vars.collateral = p.collateral(vars.size, l.marketPrice);
            vars.collateral = vars.collateral + longs * vars.payoff;

            vars.collateral = vars.collateral + shorts * ((l.isCallPool ? ONE : l.strike) - vars.payoff);
            vars.collateral = vars.collateral + vars.claimableFees;

            _burn(p.owner, vars.tokenId, vars.size);

            if (longs > ZERO) _burn(address(this), PoolStorage.LONG, longs);
            if (shorts > ZERO) _burn(address(this), PoolStorage.SHORT, shorts);
        }

        _deletePosition(l, vars.pKeyHash);
        _revertIfCostExceedsPayout(costPerHolder, vars.collateral);
        collateral = l.toPoolTokenDecimals(vars.collateral);

        emit SettlePosition(
            msg.sender,
            p.owner,
            vars.tokenId,
            vars.size,
            vars.collateral - vars.claimableFees,
            vars.payoff,
            vars.claimableFees,
            l.settlementPrice,
            ZERO,
            costPerHolder
        );

        if (costPerHolder > ZERO) vars.collateral = vars.collateral - costPerHolder;
        if (vars.collateral > ZERO) IERC20(l.getPoolToken()).safeTransferIgnoreDust(p.operator, vars.collateral);

        success = true;
    }

    /// @notice Fetch and cache the settlement price, if it has not been cached yet. Returns the cached price
    function _tryCacheSettlementPrice(PoolStorage.Layout storage l) internal returns (UD60x18) {
        UD60x18 settlementPrice = l.settlementPrice;
        if (settlementPrice == ZERO) {
            settlementPrice = IOracleAdapter(l.oracleAdapter).getPriceAt(l.base, l.quote, l.maturity);
            l.settlementPrice = settlementPrice;
            emit SettlementPriceCached(settlementPrice);
        }

        return settlementPrice;
    }

    /// @notice Deletes the `pKeyHash` from positions mapping
    function _deletePosition(PoolStorage.Layout storage l, bytes32 pKeyHash) internal {
        delete l.positions[pKeyHash];
    }

    ////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////

    ////////////////
    // TickSystem //
    ////////////////
    /// @notice Returns the nearest tick below `lower` and the nearest tick below `upper`
    function _getNearestTicksBelow(
        UD60x18 lower,
        UD60x18 upper
    ) internal view returns (UD60x18 nearestBelowLower, UD60x18 nearestBelowUpper) {
        _revertIfRangeInvalid(lower, upper);
        Position.revertIfLowerGreaterOrEqualUpper(lower, upper);

        nearestBelowLower = _getNearestTickBelow(lower);
        nearestBelowUpper = _getNearestTickBelow(upper);

        // If no tick between `lower` and `upper`, then the nearest tick below `upper`, will be `lower`
        if (nearestBelowUpper == nearestBelowLower) {
            nearestBelowUpper = lower;
        }
    }

    /// @notice Gets the nearest tick that is less than or equal to `price`
    function _getNearestTickBelow(UD60x18 price) internal view returns (UD60x18) {
        PoolStorage.Layout storage l = PoolStorage.layout();

        UD60x18 left = l.currentTick;

        while (left != ZERO && left > price) {
            left = l.tickIndex.prev(left);
        }

        UD60x18 next = l.tickIndex.next(left);
        while (left != ZERO && next <= price && left != PoolStorage.MAX_TICK_PRICE) {
            left = next;
            next = l.tickIndex.next(left);
        }

        if (left == ZERO) revert Pool__TickNotFound(price);

        return left;
    }

    /// @notice Get a tick, reverts if tick is not found
    function _getTick(UD60x18 price) internal view returns (Tick memory) {
        (Tick memory tick, bool tickFound) = _tryGetTick(price);
        if (!tickFound) revert Pool__TickNotFound(price);

        return tick;
    }

    /// @notice Try to get tick, does not revert if tick is not found
    function _tryGetTick(UD60x18 price) internal view returns (Tick memory tick, bool tickFound) {
        _revertIfTickWidthInvalid(price);

        if (price < PoolStorage.MIN_TICK_PRICE || price > PoolStorage.MAX_TICK_PRICE)
            revert Pool__TickOutOfRange(price);

        PoolStorage.Layout storage l = PoolStorage.layout();

        if (l.tickIndex.contains(price)) return (l.ticks[price], true);

        return (
            Tick({
                delta: SD49_ZERO,
                externalFeeRate: UD50_ZERO,
                longDelta: SD49_ZERO,
                shortDelta: SD49_ZERO,
                counter: 0
            }),
            false
        );
    }

    /// @notice Creates a Tick for a given price, or returns the existing tick.
    /// @param price The price of the Tick (18 decimals)
    /// @param priceBelow The price of the nearest Tick below (18 decimals)
    /// @return tick The Tick for a given price
    function _getOrCreateTick(UD60x18 price, UD60x18 priceBelow) internal returns (Tick memory) {
        PoolStorage.Layout storage l = PoolStorage.layout();

        (Tick memory tick, bool tickFound) = _tryGetTick(price);

        if (tickFound) return tick;

        if (!l.tickIndex.contains(priceBelow) || l.tickIndex.next(priceBelow) <= price)
            revert Pool__InvalidBelowPrice(price, priceBelow);

        tick = Tick({
            delta: SD49_ZERO,
            externalFeeRate: price <= l.currentTick ? l.globalFeeRate : UD50_ZERO,
            longDelta: SD49_ZERO,
            shortDelta: SD49_ZERO,
            counter: 0
        });

        l.tickIndex.insertAfter(priceBelow, price);
        l.ticks[price] = tick;

        return tick;
    }

    /// @notice Removes a tick if it does not mark the beginning or the end of a range order.
    function _removeTickIfNotActive(UD60x18 price) internal {
        PoolStorage.Layout storage l = PoolStorage.layout();

        if (!l.tickIndex.contains(price)) return;

        Tick storage tick = l.ticks[price];

        if (
            price > PoolStorage.MIN_TICK_PRICE &&
            price < PoolStorage.MAX_TICK_PRICE &&
            // Can only remove an active tick if no active range order marks a starting / ending tick on this tick.
            tick.counter == 0
        ) {
            if (tick.delta != SD49_ZERO) revert Pool__TickDeltaNotZero(tick.delta.intoSD59x18());

            if (price == l.currentTick) {
                UD60x18 newCurrentTick = l.tickIndex.prev(price);

                if (newCurrentTick < PoolStorage.MIN_TICK_PRICE) revert Pool__TickOutOfRange(newCurrentTick);

                l.currentTick = newCurrentTick;
            }

            l.tickIndex.remove(price);
            delete l.ticks[price];
        }
    }

    /// @notice Updates the tick deltas following a deposit or withdrawal
    function _updateTicks(
        UD60x18 lower,
        UD60x18 upper,
        UD50x28 marketPrice,
        SD49x28 delta,
        bool isNewDeposit,
        bool isFullWithdrawal,
        Position.OrderType orderType
    ) internal {
        PoolStorage.Layout storage l = PoolStorage.layout();

        Tick storage lowerTick = l.ticks[lower];
        Tick storage upperTick = l.ticks[upper];

        if (isNewDeposit) {
            lowerTick.counter += 1;
            upperTick.counter += 1;
        }

        if (isFullWithdrawal) {
            lowerTick.counter -= 1;
            upperTick.counter -= 1;
        }

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Update the deltas, i.e. the net change in per tick liquidity, of the
        // referenced lower and upper tick, dependent on the current tick.
        //
        // Three cases need to be covered.
        //
        // Case 1: current tick is above the upper tick. Upper has not been
        // crossed, thus, upon a crossing, liquidity has to be injected at the
        // upper tick and withdrawn at the lower. The bar below the range shows the
        // possible current ticks that cover case 1.
        //
        //     0   lower                upper       1
        //     |    [---------------------]         |
        //                                [---------]
        //                                  current
        //
        // Case 2: current tick is below is lower. Lower has not benn crossed yet,
        // thus, upon a crossing, liquidity has to be injected at the lower tick
        // and withdrawn at the upper.
        //
        //     0        lower                 upper 1
        //     |          [---------------------]   |
        //     [---------)
        //           current
        //
        // Case 3: current tick is greater or equal to lower and below upper. Thus,
        // liquidity has already entered. Therefore, if the price crosses the
        // lower, it needs to be withdrawn. Furthermore, if it crosses the above
        // tick it also needs to be withdrawn. Note that since the current tick lies
        // within the lower and upper range the liquidity has to be adjusted by the
        // delta.
        //
        //     0        lower                 upper 1
        //     |          [---------------------]   |
        //                [---------------------)
        //                         current
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        if (upper <= l.currentTick) {
            lowerTick.delta = lowerTick.delta - delta;
            upperTick.delta = upperTick.delta + delta;

            if (orderType.isLong()) {
                lowerTick.longDelta = lowerTick.longDelta - delta;
                upperTick.longDelta = upperTick.longDelta + delta;
            } else {
                lowerTick.shortDelta = lowerTick.shortDelta - delta;
                upperTick.shortDelta = upperTick.shortDelta + delta;
            }
        } else if (lower > l.currentTick) {
            lowerTick.delta = lowerTick.delta + delta;
            upperTick.delta = upperTick.delta - delta;

            if (orderType.isLong()) {
                lowerTick.longDelta = lowerTick.longDelta + delta;
                upperTick.longDelta = upperTick.longDelta - delta;
            } else {
                lowerTick.shortDelta = lowerTick.shortDelta + delta;
                upperTick.shortDelta = upperTick.shortDelta - delta;
            }
        } else {
            lowerTick.delta = lowerTick.delta - delta;
            upperTick.delta = upperTick.delta - delta;
            l.liquidityRate = l.liquidityRate.add(delta);

            if (orderType.isLong()) {
                lowerTick.longDelta = lowerTick.longDelta - delta;
                upperTick.longDelta = upperTick.longDelta - delta;
                l.longRate = l.longRate.add(delta);
            } else {
                lowerTick.shortDelta = lowerTick.shortDelta - delta;
                upperTick.shortDelta = upperTick.shortDelta - delta;
                l.shortRate = l.shortRate.add(delta);
            }
        }

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // After deposit / full withdrawal the current tick needs be reconciled. We
        // need cover two cases.
        //
        // Case 1. Deposit. Depositing liquidity in case the market price is
        // stranded shifts the market price to the upper tick in case of a bid-side
        // order or to the lower tick in case of an ask-side order.
        //
        // Ask-side order:
        //      current
        //     0   v                               1
        //     |   [-bid-]               [-ask-]   |
        //               ^
        //           market price
        //                 new current
        //                    v
        //                    [-new-ask-]
        //                    ^
        //             new market price
        //
        // Bid-side order:
        //      current
        //     0   v                               1
        //     |   [-bid-]               [-ask-]   |
        //               ^
        //           market price
        //                 new current
        //                    v
        //                    [new-bid]
        //                            ^
        //                     new market price
        //
        // Case 2. Full withdrawal of [R2] where the lower tick of [R2] is the
        // current tick causes the lower and upper tick of [R2] to be removed and
        // thus shifts the current tick to the lower of [R1]. Note that the market
        // price does not change. However, around the market price zero liquidity
        // is provided. Therefore, a buy / sell trade will result in the market
        // price snapping to the upper tick of [R1] or the lower tick of [R3] and a
        // crossing of the relevant tick.
        //
        //               current
        //     0            v                      1
        //     |   [R1]     [R2]    [R3]           |
        //                   ^
        //              market price
        //     new current
        //         v
        //     |   [R1]             [R3]           |
        //                   ^
        //              market price
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        if (delta > SD49_ZERO) {
            uint256 crossings;

            while (l.tickIndex.next(l.currentTick).intoUD50x28() < marketPrice) {
                _cross(true);
                crossings++;
            }

            while (l.currentTick.intoUD50x28() > marketPrice) {
                _cross(false);
                crossings++;
            }

            if (crossings > 2) revert Pool__InvalidReconciliation(crossings);
        }

        emit UpdateTick(
            lower,
            l.tickIndex.prev(lower),
            l.tickIndex.next(lower),
            lowerTick.delta.intoSD59x18(),
            lowerTick.externalFeeRate.intoUD60x18(),
            lowerTick.longDelta.intoSD59x18(),
            lowerTick.shortDelta.intoSD59x18(),
            lowerTick.counter
        );

        emit UpdateTick(
            upper,
            l.tickIndex.prev(upper),
            l.tickIndex.next(upper),
            upperTick.delta.intoSD59x18(),
            upperTick.externalFeeRate.intoUD60x18(),
            upperTick.longDelta.intoSD59x18(),
            upperTick.shortDelta.intoSD59x18(),
            upperTick.counter
        );

        if (delta <= SD49_ZERO) {
            _removeTickIfNotActive(lower);
            _removeTickIfNotActive(upper);
        }
    }

    /// @notice Updates the global fee rate
    function _updateGlobalFeeRate(PoolStorage.Layout storage l, UD60x18 makerRebate) internal {
        if (l.liquidityRate == UD50_ZERO) return;
        l.globalFeeRate = l.globalFeeRate + (makerRebate.intoUD50x28() / l.liquidityRate);
    }

    /// @notice Crosses the active tick either to the left if the LT is selling
    ///         to the pool. A cross is only executed if no bid or ask liquidity is
    ///         remaining within the active tick range.
    /// @param isBuy Whether the trade is a buy or a sell.
    function _cross(bool isBuy) internal {
        PoolStorage.Layout storage l = PoolStorage.layout();

        if (isBuy) {
            UD60x18 right = l.tickIndex.next(l.currentTick);
            if (right >= PoolStorage.MAX_TICK_PRICE) revert Pool__TickOutOfRange(right);
            l.currentTick = right;
        }

        Tick storage currentTick = l.ticks[l.currentTick];

        l.liquidityRate = l.liquidityRate.add(currentTick.delta);
        l.longRate = l.longRate.add(currentTick.longDelta);
        l.shortRate = l.shortRate.add(currentTick.shortDelta);

        // Flip the tick
        currentTick.delta = -currentTick.delta;
        currentTick.longDelta = -currentTick.longDelta;
        currentTick.shortDelta = -currentTick.shortDelta;

        currentTick.externalFeeRate = l.globalFeeRate - currentTick.externalFeeRate;

        emit UpdateTick(
            l.currentTick,
            l.tickIndex.prev(l.currentTick),
            l.tickIndex.next(l.currentTick),
            currentTick.delta.intoSD59x18(),
            currentTick.externalFeeRate.intoUD60x18(),
            currentTick.longDelta.intoSD59x18(),
            currentTick.shortDelta.intoSD59x18(),
            currentTick.counter
        );

        if (!isBuy) {
            if (l.currentTick <= PoolStorage.MIN_TICK_PRICE) revert Pool__TickOutOfRange(l.currentTick);
            l.currentTick = l.tickIndex.prev(l.currentTick);
        }
    }

    /// @notice Removes the initialization fee discount for the pool
    function _removeInitFeeDiscount(PoolStorage.Layout storage l) internal {
        if (l.initFeeDiscountRemoved) return;

        l.initFeeDiscountRemoved = true;

        IPoolFactory(FACTORY).removeDiscount(
            IPoolFactory.PoolKey(l.base, l.quote, l.oracleAdapter, l.strike, l.maturity, l.isCallPool)
        );
    }

    /// @notice Calculates the growth and exposure change between the lower and upper Ticks of a Position.
    /// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ///                     l         ▼         u
    ///    ----|----|-------|xxxxxxxxxxxxxxxxxxx|--------|---------
    ///    => (global - external(l) - external(u))
    ///
    ///                ▼    l                   u
    ///    ----|----|-------|xxxxxxxxxxxxxxxxxxx|--------|---------
    ///    => (global - (global - external(l)) - external(u))
    ///
    ///                     l                   u    ▼
    ///    ----|----|-------|xxxxxxxxxxxxxxxxxxx|--------|---------
    ///    => (global - external(l) - (global - external(u)))
    /// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function _rangeFeeRate(
        PoolStorage.Layout storage l,
        UD60x18 lower,
        UD60x18 upper,
        UD50x28 lowerTickExternalFeeRate,
        UD50x28 upperTickExternalFeeRate
    ) internal view returns (SD49x28) {
        UD50x28 aboveFeeRate = l.currentTick >= upper
            ? l.globalFeeRate - upperTickExternalFeeRate
            : upperTickExternalFeeRate;

        UD50x28 belowFeeRate = l.currentTick >= lower
            ? lowerTickExternalFeeRate
            : l.globalFeeRate - lowerTickExternalFeeRate;

        return l.globalFeeRate.intoSD49x28() - aboveFeeRate.intoSD49x28() - belowFeeRate.intoSD49x28();
    }

    /// @notice Gets the lower and upper bound of the stranded market area when it exists. In case the stranded market
    ///         area does not exist it will return the stranded market area the maximum tick price for both the lower
    ///         and the upper, in which case the market price is not stranded given any range order info order.
    /// @return lower Lower bound of the stranded market price area (Default : PoolStorage.MAX_TICK_PRICE + ONE = 2e18) (18 decimals)
    /// @return upper Upper bound of the stranded market price area (Default : PoolStorage.MAX_TICK_PRICE + ONE = 2e18) (18 decimals)
    function _getStrandedArea(PoolStorage.Layout storage l) internal view returns (UD60x18 lower, UD60x18 upper) {
        lower = PoolStorage.MAX_TICK_PRICE + ONE;
        upper = PoolStorage.MAX_TICK_PRICE + ONE;

        UD60x18 current = l.currentTick;
        UD60x18 right = l.tickIndex.next(current);

        if (l.liquidityRate == UD50_ZERO) {
            // applies whenever the pool is empty or the last active order that
            // was traversed by the price was withdrawn
            // the check is independent of the current market price
            lower = current;
            upper = right;
        } else if (
            -l.ticks[right].delta > SD49_ZERO &&
            l.liquidityRate == (-l.ticks[right].delta).intoUD50x28() &&
            right == l.marketPrice.intoUD60x18() &&
            l.tickIndex.next(right) != ZERO
        ) {
            // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            // bid-bound market price check
            // liquidity_rate > 0
            //        market price
            //             v
            // |------[----]------|
            //        ^
            //     current
            // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

            lower = right;
            upper = l.tickIndex.next(right);
        } else if (
            -l.ticks[current].delta > SD49_ZERO &&
            l.liquidityRate == (-l.ticks[current].delta).intoUD50x28() &&
            current == l.marketPrice.intoUD60x18() &&
            l.tickIndex.prev(current) != ZERO
        ) {
            // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            //  ask-bound market price check
            //  liquidity_rate > 0
            //  market price
            //        v
            // |------[----]------|
            //        ^
            //     current
            // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

            lower = l.tickIndex.prev(current);
            upper = current;
        }
    }

    /// @notice Returns true if the market price is stranded
    function _isMarketPriceStranded(
        PoolStorage.Layout storage l,
        Position.KeyInternal memory p,
        bool isBid
    ) internal view returns (bool) {
        (UD60x18 lower, UD60x18 upper) = _getStrandedArea(l);
        UD60x18 tick = isBid ? p.upper : p.lower;
        return lower <= tick && tick <= upper;
    }

    /// @notice In case the market price is stranded the market price needs to be set to the upper (lower) tick of the
    ///         bid (ask) order.
    function _getStrandedMarketPriceUpdate(Position.KeyInternal memory p, bool isBid) internal pure returns (UD50x28) {
        return (isBid ? p.upper : p.lower).intoUD50x28();
    }

    /// @notice Revert if the tick width is invalid
    function _revertIfTickWidthInvalid(UD60x18 price) internal pure {
        if (price % PoolStorage.MIN_TICK_DISTANCE != ZERO) revert Pool__TickWidthInvalid(price);
    }

    /// @notice Returns the encoded OB quote hash
    function _quoteOBHash(IPoolInternal.QuoteOB memory quoteOB) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                FILL_QUOTE_OB_TYPE_HASH,
                quoteOB.provider,
                quoteOB.taker,
                quoteOB.price,
                quoteOB.size,
                quoteOB.isBuy,
                quoteOB.deadline,
                quoteOB.salt
            )
        );

        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    EIP712.calculateDomainSeparator(keccak256("Premia"), keccak256("1")),
                    structHash
                )
            );
    }

    /// @notice Returns the balance of `user` for `tokenId` as UD60x18
    function _balanceOfUD60x18(address user, uint256 tokenId) internal view returns (UD60x18) {
        return ud(_balanceOf(user, tokenId));
    }

    /// @notice Mints `amount` of `id` and assigns it to `account`
    function _mint(address account, uint256 id, UD60x18 amount) internal {
        _mint(account, id, amount.unwrap(), "");
    }

    /// @notice Burns `amount` of `id` assigned to `account`
    function _burn(address account, uint256 id, UD60x18 amount) internal {
        _burn(account, id, amount.unwrap());
    }

    /// @notice Applies the primary and secondary referral rebates, if total rebates are greater than zero
    function _useReferral(
        PoolStorage.Layout storage l,
        address user,
        address referrer,
        UD60x18 primaryReferralRebate,
        UD60x18 secondaryReferralRebate
    ) internal {
        UD60x18 totalReferralRebate = primaryReferralRebate + secondaryReferralRebate;
        if (totalReferralRebate == ZERO) return;

        address token = l.getPoolToken();
        IERC20(token).approve(REFERRAL, totalReferralRebate);
        IReferral(REFERRAL).useReferral(user, referrer, token, primaryReferralRebate, secondaryReferralRebate);
        IERC20(token).approve(REFERRAL, 0);
    }

    /// @notice Checks if the liquidity rate of the range results in a non-terminating decimal.
    /// @dev lower should NOT be equal to upper, to avoid running into an infinite loop
    function _isRateNonTerminating(UD60x18 lower, UD60x18 upper) internal pure returns (bool) {
        UD60x18 den = (upper - lower) / PoolStorage.MIN_TICK_DISTANCE;

        while (den % TWO == ZERO) {
            den = den / TWO;
        }

        while (den % FIVE == ZERO) {
            den = den / FIVE;
        }

        return den != ONE;
    }

    /// @notice Revert if the `lower` and `upper` tick range is invalid
    function _revertIfRangeInvalid(UD60x18 lower, UD60x18 upper) internal pure {
        if (
            lower == ZERO ||
            upper == ZERO ||
            lower >= upper ||
            lower < PoolStorage.MIN_TICK_PRICE ||
            upper > PoolStorage.MAX_TICK_PRICE ||
            _isRateNonTerminating(lower, upper)
        ) revert Pool__InvalidRange(lower, upper);
    }

    /// @notice Revert if `size` is zero
    function _revertIfZeroSize(UD60x18 size) internal pure {
        if (size == ZERO) revert Pool__ZeroSize();
    }

    /// @notice Revert if option is not expired
    function _revertIfOptionNotExpired(PoolStorage.Layout storage l) internal view {
        if (block.timestamp < l.maturity) revert Pool__OptionNotExpired();
    }

    /// @notice Revert if option is expired
    function _revertIfOptionExpired(PoolStorage.Layout storage l) internal view {
        if (block.timestamp >= l.maturity) revert Pool__OptionExpired();
    }

    /// @notice Revert if withdrawal delay has not elapsed
    function _revertIfWithdrawalDelayNotElapsed(Position.Data storage position) internal view {
        uint256 unlockTime = position.lastDeposit + WITHDRAWAL_DELAY;
        if (block.timestamp < unlockTime) revert Pool__WithdrawalDelayNotElapsed(unlockTime);
    }

    /// @notice Revert if `totalPremium` is exceeds max slippage
    function _revertIfTradeAboveMaxSlippage(uint256 totalPremium, uint256 premiumLimit, bool isBuy) internal pure {
        if (isBuy && totalPremium > premiumLimit) revert Pool__AboveMaxSlippage(totalPremium, 0, premiumLimit);
        if (!isBuy && totalPremium < premiumLimit)
            revert Pool__AboveMaxSlippage(totalPremium, premiumLimit, type(uint256).max);
    }

    function _revertIfInvalidSize(UD60x18 lower, UD60x18 upper, UD60x18 size) internal pure {
        UD60x18 numTicks = (upper - lower) / PoolStorage.MIN_TICK_PRICE;
        if ((size / numTicks) * numTicks != size) revert Pool__InvalidSize(lower, upper, size);
    }

    /// @notice Revert if `marketPrice` is below `minMarketPrice` or above `maxMarketPrice`
    function _revertIfDepositWithdrawalAboveMaxSlippage(
        UD60x18 marketPrice,
        UD60x18 minMarketPrice,
        UD60x18 maxMarketPrice
    ) internal pure {
        if (marketPrice > maxMarketPrice || marketPrice < minMarketPrice)
            revert Pool__AboveMaxSlippage(marketPrice.unwrap(), minMarketPrice.unwrap(), maxMarketPrice.unwrap());
    }

    /// @notice Returns true if OB quote and OB quote balance are valid
    function _areQuoteOBAndBalanceValid(
        PoolStorage.Layout storage l,
        FillQuoteOBArgsInternal memory args,
        QuoteOB memory quoteOB,
        bytes32 quoteOBHash
    ) internal view returns (bool isValid, InvalidQuoteOBError error) {
        (isValid, error) = _isQuoteOBValid(l, args, quoteOB, quoteOBHash, false);
        if (!isValid) {
            return (isValid, error);
        }
        return _isQuoteOBBalanceValid(l, args, quoteOB);
    }

    /// @notice Revert if OB quote is invalid
    function _revertIfQuoteOBInvalid(
        PoolStorage.Layout storage l,
        FillQuoteOBArgsInternal memory args,
        QuoteOB memory quoteOB,
        bytes32 quoteOBHash
    ) internal view {
        _isQuoteOBValid(l, args, quoteOB, quoteOBHash, true);
    }

    /// @notice Revert if the position does not exist
    function _revertIfPositionDoesNotExist(address owner, uint256 tokenId, UD60x18 balance) internal pure {
        if (balance == ZERO) revert Pool__PositionDoesNotExist(owner, tokenId);
    }

    /// @notice Revert if the position is in an invalid state
    function _revertIfInvalidPositionState(uint256 balance, uint256 lastDeposit) internal pure {
        if ((balance > 0 || lastDeposit > 0) && (balance == 0 || lastDeposit == 0))
            revert Pool__InvalidPositionState(balance, lastDeposit);
    }

    /// @notice Returns true if OB quote is valid
    function _isQuoteOBValid(
        PoolStorage.Layout storage l,
        FillQuoteOBArgsInternal memory args,
        QuoteOB memory quoteOB,
        bytes32 quoteOBHash,
        bool revertIfInvalid
    ) internal view returns (bool, InvalidQuoteOBError) {
        if (block.timestamp > quoteOB.deadline) {
            if (revertIfInvalid) revert Pool__QuoteOBExpired();
            return (false, InvalidQuoteOBError.QuoteOBExpired);
        }

        UD60x18 filledAmount = l.quoteOBAmountFilled[quoteOB.provider][quoteOBHash];

        if (filledAmount.unwrap() == type(uint256).max) {
            if (revertIfInvalid) revert Pool__QuoteOBCancelled();
            return (false, InvalidQuoteOBError.QuoteOBCancelled);
        }

        if (filledAmount + args.size > quoteOB.size) {
            if (revertIfInvalid) revert Pool__QuoteOBOverfilled(filledAmount, args.size, quoteOB.size);
            return (false, InvalidQuoteOBError.QuoteOBOverfilled);
        }

        if (PoolStorage.MIN_TICK_PRICE > quoteOB.price || quoteOB.price > PoolStorage.MAX_TICK_PRICE) {
            if (revertIfInvalid) revert Pool__OutOfBoundsPrice(quoteOB.price);
            return (false, InvalidQuoteOBError.OutOfBoundsPrice);
        }

        if (quoteOB.taker != address(0) && args.user != quoteOB.taker) {
            if (revertIfInvalid) revert Pool__InvalidQuoteOBTaker();
            return (false, InvalidQuoteOBError.InvalidQuoteOBTaker);
        }

        address signer = ECDSA.recover(quoteOBHash, args.signature.v, args.signature.r, args.signature.s);
        if (signer != quoteOB.provider) {
            if (revertIfInvalid) revert Pool__InvalidQuoteOBSignature();
            return (false, InvalidQuoteOBError.InvalidQuoteOBSignature);
        }

        return (true, InvalidQuoteOBError.None);
    }

    /// @notice Returns true if OB quote balance is valid
    function _isQuoteOBBalanceValid(
        PoolStorage.Layout storage l,
        FillQuoteOBArgsInternal memory args,
        QuoteOB memory quoteOB
    ) internal view returns (bool, InvalidQuoteOBError) {
        PremiumAndFeeInternal memory premiumAndFee = _calculateQuoteOBPremiumAndFee(
            l,
            args.user,
            address(0),
            args.size,
            quoteOB.price,
            quoteOB.isBuy
        );

        Position.Delta memory delta = _calculateAssetsUpdate(
            l,
            args.user,
            premiumAndFee.premium,
            args.size,
            quoteOB.isBuy
        );

        if (
            (delta.longs == iZERO && delta.shorts == iZERO) ||
            (delta.longs > iZERO && delta.shorts > iZERO) ||
            (delta.longs < iZERO && delta.shorts < iZERO)
        ) return (false, InvalidQuoteOBError.InvalidAssetUpdate);

        if (delta.collateral < iZERO) {
            IERC20 token = IERC20(l.getPoolToken());
            if (token.allowance(args.user, ROUTER) < l.toPoolTokenDecimals((-delta.collateral).intoUD60x18())) {
                return (false, InvalidQuoteOBError.InsufficientCollateralAllowance);
            }

            if (token.balanceOf(args.user) < l.toPoolTokenDecimals((-delta.collateral).intoUD60x18())) {
                return (false, InvalidQuoteOBError.InsufficientCollateralBalance);
            }
        }

        if (delta.longs < iZERO && _balanceOf(args.user, PoolStorage.LONG) < (-delta.longs).intoUD60x18().unwrap()) {
            return (false, InvalidQuoteOBError.InsufficientLongBalance);
        }

        if (delta.shorts < iZERO && _balanceOf(args.user, PoolStorage.SHORT) < (-delta.shorts).intoUD60x18().unwrap()) {
            return (false, InvalidQuoteOBError.InsufficientShortBalance);
        }

        return (true, InvalidQuoteOBError.None);
    }

    /// @notice Revert if `operator` is not msg.sender
    function _revertIfOperatorNotAuthorized(address operator) internal view {
        if (operator != msg.sender) revert Pool__OperatorNotAuthorized(msg.sender);
    }

    /// @notice Revert if `operator` is not authorized by `holder` to call `action`
    function _revertIfActionNotAuthorized(address holder, IUserSettings.Action action) internal view {
        if (!IUserSettings(SETTINGS).isActionAuthorized(holder, msg.sender, action))
            revert Pool__ActionNotAuthorized(holder, msg.sender, action);
    }

    /// @notice Revert if `cost` is not authorized by `holder`
    function _revertIfCostNotAuthorized(address holder, UD60x18 costPerHolder) internal view {
        PoolStorage.Layout storage l = PoolStorage.layout();
        address poolToken = l.getPoolToken();

        UD60x18 wrappedNativePoolTokenSpotPrice = poolToken == WRAPPED_NATIVE_TOKEN
            ? ONE
            : IOracleAdapter(l.oracleAdapter).getPrice(WRAPPED_NATIVE_TOKEN, poolToken);

        UD60x18 costInWrappedNative = costPerHolder * wrappedNativePoolTokenSpotPrice;
        UD60x18 authorizedCost = IUserSettings(SETTINGS).getAuthorizedCost(holder);

        if (costInWrappedNative > authorizedCost) revert Pool__CostNotAuthorized(costInWrappedNative, authorizedCost);
    }

    /// @notice Revert if `cost` exceeds `payout`
    function _revertIfCostExceedsPayout(UD60x18 cost, UD60x18 payout) internal pure {
        if (cost > payout) revert Pool__CostExceedsPayout(cost, payout);
    }

    /// @notice `_beforeTokenTransfer` wrapper, updates `tokenIds` set
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        PoolStorage.Layout storage l = PoolStorage.layout();

        // We do not need to revert here if positions are transferred like in PoolBase, as ERC1155 transfers functions
        // are not external in this diamond facet
        for (uint256 i; i < ids.length; i++) {
            uint256 id = ids[i];

            if (amounts[i] == 0) continue;

            if (from == address(0)) {
                l.tokenIds.add(id);
            }

            if (to == address(0) && _totalSupply(id) == 0) {
                l.tokenIds.remove(id);
            }
        }
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {OwnableStorage} from "@solidstate/contracts/access/ownable/OwnableStorage.sol";
import {IERC1155} from "@solidstate/contracts/interfaces/IERC1155.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {ERC165BaseInternal} from "@solidstate/contracts/introspection/ERC165/base/ERC165BaseInternal.sol";
import {Proxy} from "@solidstate/contracts/proxy/Proxy.sol";
import {IDiamondReadable} from "@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol";
import {IERC20Metadata} from "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";

import {DoublyLinkedListUD60x18, DoublyLinkedList} from "../libraries/DoublyLinkedListUD60x18.sol";
import {PRBMathExtra} from "../libraries/PRBMathExtra.sol";

import {PoolStorage} from "./PoolStorage.sol";

/// @title Upgradeable proxy with centrally controlled Pool implementation
contract PoolProxy is Proxy, ERC165BaseInternal {
    using DoublyLinkedListUD60x18 for DoublyLinkedList.Bytes32List;
    using PoolStorage for PoolStorage.Layout;
    using PRBMathExtra for UD60x18;

    address private immutable DIAMOND;

    constructor(
        address diamond,
        address base,
        address quote,
        address oracleAdapter,
        UD60x18 strike,
        uint256 maturity,
        bool isCallPool
    ) {
        DIAMOND = diamond;
        OwnableStorage.layout().owner = msg.sender;

        {
            PoolStorage.Layout storage l = PoolStorage.layout();

            l.base = base;
            l.quote = quote;

            l.oracleAdapter = oracleAdapter;

            l.strike = strike;
            l.maturity = maturity;

            uint8 baseDecimals = IERC20Metadata(base).decimals();
            uint8 quoteDecimals = IERC20Metadata(quote).decimals();

            l.baseDecimals = baseDecimals;
            l.quoteDecimals = quoteDecimals;

            l.isCallPool = isCallPool;

            l.tickIndex.push(PoolStorage.MIN_TICK_PRICE);
            l.tickIndex.push(PoolStorage.MAX_TICK_PRICE);

            l.currentTick = PoolStorage.MIN_TICK_PRICE;
            l.marketPrice = PoolStorage.MIN_TICK_PRICE.intoUD50x28();
        }

        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IERC1155).interfaceId, true);
    }

    /// @inheritdoc Proxy
    function _getImplementation() internal view override returns (address) {
        return IDiamondReadable(DIAMOND).facetAddress(msg.sig);
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";
import {SD59x18, sd} from "lib/prb-math/src/SD59x18.sol";

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {DoublyLinkedList} from "@solidstate/contracts/data/DoublyLinkedList.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

import {Position} from "../libraries/Position.sol";
import {OptionMath} from "../libraries/OptionMath.sol";
import {ZERO} from "../libraries/Constants.sol";
import {UD50x28} from "../libraries/UD50x28.sol";

import {IOracleAdapter} from "../adapter/IOracleAdapter.sol";

import {IERC20Router} from "../router/IERC20Router.sol";

import {IPoolInternal} from "./IPoolInternal.sol";

library PoolStorage {
    using SafeERC20 for IERC20;
    using PoolStorage for PoolStorage.Layout;

    // Token id for SHORT
    uint256 internal constant SHORT = 0;
    // Token id for LONG
    uint256 internal constant LONG = 1;

    // The version of LP token, used to know how to decode it, if upgrades are made
    uint8 internal constant TOKEN_VERSION = 1;

    UD60x18 internal constant MIN_TICK_DISTANCE = UD60x18.wrap(0.001e18); // 0.001
    UD60x18 internal constant MIN_TICK_PRICE = UD60x18.wrap(0.001e18); // 0.001
    UD60x18 internal constant MAX_TICK_PRICE = UD60x18.wrap(1e18); // 1

    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.Pool");

    struct Layout {
        // ERC20 token addresses
        address base;
        address quote;
        address oracleAdapter;
        // token metadata
        uint8 baseDecimals;
        uint8 quoteDecimals;
        uint256 maturity;
        // Whether its a call or put pool
        bool isCallPool;
        // Index of all existing ticks sorted
        DoublyLinkedList.Bytes32List tickIndex;
        mapping(UD60x18 normalizedPrice => IPoolInternal.Tick) ticks;
        UD50x28 marketPrice;
        UD50x28 globalFeeRate;
        UD60x18 protocolFees;
        UD60x18 strike;
        UD50x28 liquidityRate;
        UD50x28 longRate;
        UD50x28 shortRate;
        // Current tick normalized price
        UD60x18 currentTick;
        // Settlement price of option
        UD60x18 settlementPrice;
        mapping(bytes32 key => Position.Data) positions;
        // Size of OB quotes already filled
        mapping(address provider => mapping(bytes32 hash => UD60x18 amountFilled)) quoteOBAmountFilled;
        // Set to true after maturity, to remove factory initialization discount
        bool initFeeDiscountRemoved;
        EnumerableSet.UintSet tokenIds;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice Returns the token decimals for the pool token
    function getPoolTokenDecimals(Layout storage l) internal view returns (uint8) {
        return l.isCallPool ? l.baseDecimals : l.quoteDecimals;
    }

    /// @notice Adjust decimals of a value with 18 decimals to match the pool token decimals
    function toPoolTokenDecimals(Layout storage l, uint256 value) internal view returns (uint256) {
        uint8 decimals = l.getPoolTokenDecimals();
        return OptionMath.scaleDecimals(value, 18, decimals);
    }

    /// @notice Adjust decimals of a value with 18 decimals to match the pool token decimals
    function toPoolTokenDecimals(Layout storage l, int256 value) internal view returns (int256) {
        uint8 decimals = l.getPoolTokenDecimals();
        return OptionMath.scaleDecimals(value, 18, decimals);
    }

    /// @notice Adjust decimals of a value with 18 decimals to match the pool token decimals
    function toPoolTokenDecimals(Layout storage l, UD60x18 value) internal view returns (uint256) {
        return l.toPoolTokenDecimals(value.unwrap());
    }

    /// @notice Adjust decimals of a value with 18 decimals to match the pool token decimals
    function toPoolTokenDecimals(Layout storage l, SD59x18 value) internal view returns (int256) {
        return l.toPoolTokenDecimals(value.unwrap());
    }

    /// @notice Adjust decimals of a value with pool token decimals to 18 decimals
    function fromPoolTokenDecimals(Layout storage l, uint256 value) internal view returns (UD60x18) {
        uint8 decimals = l.getPoolTokenDecimals();
        return ud(OptionMath.scaleDecimals(value, decimals, 18));
    }

    /// @notice Adjust decimals of a value with pool token decimals to 18 decimals
    function fromPoolTokenDecimals(Layout storage l, int256 value) internal view returns (SD59x18) {
        uint8 decimals = l.getPoolTokenDecimals();
        return sd(OptionMath.scaleDecimals(value, decimals, 18));
    }

    /// @notice Get the token used as options collateral and for payment of premium. (quote for PUT pools, base for CALL
    ///         pools)
    function getPoolToken(Layout storage l) internal view returns (address) {
        return l.isCallPool ? l.base : l.quote;
    }

    /// @notice calculate ERC1155 token id for given option parameters
    /// @param operator The current operator of the position
    /// @param lower The lower bound normalized option price (18 decimals)
    /// @param upper The upper bound normalized option price (18 decimals)
    /// @return tokenId token id
    function formatTokenId(
        address operator,
        UD60x18 lower,
        UD60x18 upper,
        Position.OrderType orderType
    ) internal pure returns (uint256 tokenId) {
        if (lower >= upper || lower < MIN_TICK_PRICE || upper > MAX_TICK_PRICE)
            revert IPoolInternal.Pool__InvalidRange(lower, upper);

        tokenId =
            (uint256(TOKEN_VERSION) << 252) +
            (uint256(orderType) << 180) +
            (uint256(uint160(operator)) << 20) +
            ((upper.unwrap() / MIN_TICK_DISTANCE.unwrap()) << 10) +
            (lower.unwrap() / MIN_TICK_DISTANCE.unwrap());
    }

    /// @notice derive option maturity and strike price from ERC1155 token id
    /// @param tokenId token id
    /// @return version The version of LP token, used to know how to decode it, if upgrades are made
    /// @return operator The current operator of the position
    /// @return lower The lower bound normalized option price (18 decimals)
    /// @return upper The upper bound normalized option price (18 decimals)
    function parseTokenId(
        uint256 tokenId
    )
        internal
        pure
        returns (uint8 version, address operator, UD60x18 lower, UD60x18 upper, Position.OrderType orderType)
    {
        uint256 minTickDistance = MIN_TICK_DISTANCE.unwrap();

        assembly {
            version := shr(252, tokenId)
            orderType := and(shr(180, tokenId), 0xF) // 4 bits mask
            operator := shr(20, tokenId)
            upper := mul(
                and(shr(10, tokenId), 0x3FF), // 10 bits mask
                minTickDistance
            )
            lower := mul(
                and(tokenId, 0x3FF), // 10 bits mask
                minTickDistance
            )
        }
    }

    /// @notice Converts `value` to pool token decimals and approves `spender`
    function approve(IERC20 token, address spender, UD60x18 value) internal {
        token.approve(spender, PoolStorage.layout().toPoolTokenDecimals(value));
    }

    /// @notice Converts `value` to pool token decimals and transfers `token`
    function safeTransferFrom(IERC20Router router, address token, address from, address to, UD60x18 value) internal {
        router.safeTransferFrom(token, from, to, PoolStorage.layout().toPoolTokenDecimals(value));
    }

    /// @notice Transfers token amount to recipient. Ignores if dust is missing on the exchange level,
    ///         i.e. if the pool balance is 0.01% less than the amount that should be sent, then the pool balance is
    ///         transferred instead of the amount. If the relative difference is larger than 0.01% then the transaction
    ///         will revert.
    /// @param token IERC20 token that is intended to be sent.
    /// @param to Recipient address of the tokens.
    /// @param value The amount of tokens that are intended to be sent (poolToken decimals).
    function safeTransferIgnoreDust(IERC20 token, address to, uint256 value) internal {
        PoolStorage.Layout storage l = PoolStorage.layout();
        uint256 balance = IERC20(l.getPoolToken()).balanceOf(address(this));

        if (value == 0) return;

        if (balance < value) {
            UD60x18 _balance = l.fromPoolTokenDecimals(balance);
            UD60x18 _value = l.fromPoolTokenDecimals(value);
            UD60x18 relativeDiff = (_value - _balance) / _value;

            // If relativeDiff is larger than the 0.01% tolerance, then revert
            if (relativeDiff > ud(0.0001 ether)) revert IPoolInternal.Pool__InsufficientFunds();

            value = balance;
        }

        token.safeTransfer(to, value);
    }

    /// @notice Transfers token amount to recipient. Ignores if dust is missing on the exchange level,
    ///         i.e. if the pool balance is 0.01% less than the amount that should be sent, then the pool balance is
    ///         transferred instead of the amount. If the relative difference is larger than 0.01% then the transaction
    ///         will revert.
    /// @param token IERC20 token that is intended to be sent.
    /// @param to Recipient address of the tokens.
    /// @param value The amount of tokens that are intended to be sent. (18 decimals)
    function safeTransferIgnoreDust(IERC20 token, address to, UD60x18 value) internal {
        PoolStorage.Layout storage l = PoolStorage.layout();
        safeTransferIgnoreDust(token, to, toPoolTokenDecimals(l, value));
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC3156FlashBorrower} from "@solidstate/contracts/interfaces/IERC3156FlashBorrower.sol";
import {IERC3156FlashLender} from "@solidstate/contracts/interfaces/IERC3156FlashLender.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";

import {Position} from "../libraries/Position.sol";

import {PoolStorage} from "./PoolStorage.sol";
import {PoolInternal} from "./PoolInternal.sol";
import {IPoolTrade} from "./IPoolTrade.sol";

contract PoolTrade is IPoolTrade, PoolInternal, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using PoolStorage for PoolStorage.Layout;

    UD60x18 internal constant FLASH_LOAN_FEE = UD60x18.wrap(0.0009e18); // 0.09%

    bytes32 internal constant FLASH_LOAN_CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    constructor(
        address factory,
        address router,
        address wrappedNativeToken,
        address feeReceiver,
        address referral,
        address settings,
        address vaultRegistry,
        address vxPremia
    ) PoolInternal(factory, router, wrappedNativeToken, feeReceiver, referral, settings, vaultRegistry, vxPremia) {}

    /// @inheritdoc IPoolTrade
    function getQuoteAMM(
        address taker,
        UD60x18 size,
        bool isBuy
    ) external view returns (uint256 premiumNet, uint256 takerFee) {
        return _getQuoteAMM(taker, size, isBuy);
    }

    /// @inheritdoc IPoolTrade
    function fillQuoteOB(
        QuoteOB calldata quoteOB,
        UD60x18 size,
        Signature calldata signature,
        address referrer
    ) external nonReentrant returns (uint256 premiumTaker, Position.Delta memory delta) {
        return _fillQuoteOB(FillQuoteOBArgsInternal(msg.sender, referrer, size, signature, true), quoteOB);
    }

    /// @inheritdoc IPoolTrade
    function trade(
        UD60x18 size,
        bool isBuy,
        uint256 premiumLimit,
        address referrer
    ) external nonReentrant returns (uint256 totalPremium, Position.Delta memory delta) {
        return _trade(TradeArgsInternal(msg.sender, referrer, size, isBuy, premiumLimit, true));
    }

    /// @inheritdoc IPoolTrade
    function cancelQuotesOB(bytes32[] calldata hashes) external nonReentrant {
        PoolStorage.Layout storage l = PoolStorage.layout();
        for (uint256 i = 0; i < hashes.length; i++) {
            l.quoteOBAmountFilled[msg.sender][hashes[i]] = ud(type(uint256).max);
            emit CancelQuoteOB(msg.sender, hashes[i]);
        }
    }

    /// @inheritdoc IPoolTrade
    function isQuoteOBValid(
        QuoteOB calldata quoteOB,
        UD60x18 size,
        Signature calldata sig
    ) external view returns (bool, InvalidQuoteOBError) {
        PoolStorage.Layout storage l = PoolStorage.layout();
        bytes32 quoteOBHash = _quoteOBHash(quoteOB);
        return
            _areQuoteOBAndBalanceValid(
                l,
                FillQuoteOBArgsInternal(msg.sender, address(0), size, sig, true),
                quoteOB,
                quoteOBHash
            );
    }

    /// @inheritdoc IPoolTrade
    function getQuoteOBFilledAmount(address provider, bytes32 quoteOBHash) external view returns (UD60x18) {
        return PoolStorage.layout().quoteOBAmountFilled[provider][quoteOBHash];
    }

    /// @inheritdoc IERC3156FlashLender
    function maxFlashLoan(address token) external view returns (uint256) {
        _revertIfNotPoolToken(token);
        return IERC20(token).balanceOf(address(this));
    }

    /// @inheritdoc IERC3156FlashLender
    function flashFee(address token, uint256 amount) external view returns (uint256) {
        _revertIfNotPoolToken(token);
        return PoolStorage.layout().toPoolTokenDecimals(_flashFee(amount));
    }

    /// @notice Returns the fee required for a flash loan of `amount`
    function _flashFee(uint256 amount) internal view returns (UD60x18) {
        return PoolStorage.layout().fromPoolTokenDecimals(amount) * FLASH_LOAN_FEE;
    }

    /// @inheritdoc IERC3156FlashLender
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external nonReentrant returns (bool) {
        _revertIfNotPoolToken(token);
        PoolStorage.Layout storage l = PoolStorage.layout();

        uint256 startBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(address(receiver), amount);

        UD60x18 fee = _flashFee(amount);
        uint256 _fee = l.toPoolTokenDecimals(fee);

        if (
            IERC3156FlashBorrower(receiver).onFlashLoan(msg.sender, token, amount, _fee, data) !=
            FLASH_LOAN_CALLBACK_SUCCESS
        ) revert Pool__FlashLoanCallbackFailed();

        uint256 endBalance = IERC20(token).balanceOf(address(this));
        uint256 endBalanceRequired = startBalance + _fee;

        if (endBalance < endBalanceRequired) revert Pool__FlashLoanNotRepayed();

        emit FlashLoan(msg.sender, address(receiver), l.fromPoolTokenDecimals(amount), fee);

        return true;
    }

    /// @notice Revert if `token` is not the pool token
    function _revertIfNotPoolToken(address token) internal view {
        if (token != PoolStorage.layout().getPoolToken()) revert Pool__NotPoolToken(token);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

interface IProxyManager {
    function getManagedProxyImplementation() external view returns (address);

    function setManagedProxyImplementation(address implementation) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

interface IProxyUpgradeableOwnable {
    function getImplementation() external view returns (address);
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {SolidStateDiamond} from "@solidstate/contracts/proxy/diamond/SolidStateDiamond.sol";

/// @title Premia core contract
/// @dev based on the EIP2535 Diamond standard
contract Premia is SolidStateDiamond {

}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";

import {ProxyManagerStorage} from "./ProxyManagerStorage.sol";
import {IProxyManager} from "./IProxyManager.sol";

contract ProxyManager is IProxyManager, OwnableInternal {
    function getManagedProxyImplementation() external view returns (address) {
        return ProxyManagerStorage.layout().managedProxyImplementation;
    }

    function setManagedProxyImplementation(address implementation) external onlyOwner {
        ProxyManagerStorage.layout().managedProxyImplementation = implementation;
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

library ProxyManagerStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.ProxyManager");

    struct Layout {
        address managedProxyImplementation;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {AddressUtils} from "@solidstate/contracts/utils/AddressUtils.sol";
import {Proxy} from "@solidstate/contracts/proxy/Proxy.sol";
import {SafeOwnable} from "@solidstate/contracts/access/ownable/SafeOwnable.sol";

import {ProxyUpgradeableOwnableStorage} from "./ProxyUpgradeableOwnableStorage.sol";

contract ProxyUpgradeableOwnable is Proxy, SafeOwnable {
    using AddressUtils for address;

    event ImplementationSet(address implementation);

    error ProxyUpgradeableOwnable__InvalidImplementation(address implementation);

    constructor(address implementation) {
        _setOwner(msg.sender);
        _setImplementation(implementation);
    }

    receive() external payable {}

    /// @inheritdoc Proxy
    function _getImplementation() internal view override returns (address) {
        return ProxyUpgradeableOwnableStorage.layout().implementation;
    }

    /// @notice get address of implementation contract
    /// @return implementation address
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    /// @notice set address of implementation contract
    /// @param implementation address of the new implementation
    function setImplementation(address implementation) external onlyOwner {
        _setImplementation(implementation);
    }

    /// @notice set address of implementation contract
    function _setImplementation(address implementation) internal {
        if (!implementation.isContract()) revert ProxyUpgradeableOwnable__InvalidImplementation(implementation);

        ProxyUpgradeableOwnableStorage.layout().implementation = implementation;
        emit ImplementationSet(implementation);
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

library ProxyUpgradeableOwnableStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.ProxyUpgradeableOwnable");

    struct Layout {
        address implementation;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

interface IReferral {
    enum RebateTier {
        PrimaryRebate1,
        PrimaryRebate2,
        PrimaryRebate3
    }

    error Referral__PoolNotAuthorized();

    event ClaimRebate(address indexed referrer, address indexed token, uint256 amount);
    event SetPrimaryRebatePercent(RebateTier tier, UD60x18 oldPercent, UD60x18 newPercent);
    event SetRebateTier(address indexed referrer, RebateTier oldTier, RebateTier newTier);
    event SetSecondaryRebatePercent(UD60x18 oldPercent, UD60x18 newPercent);

    event Refer(
        address indexed user,
        address indexed primaryReferrer,
        address indexed secondaryReferrer,
        address token,
        UD60x18 tier,
        UD60x18 primaryRebate,
        UD60x18 secondaryRebate
    );

    /// @notice Returns the address of the referrer for a given user
    /// @param user The address of the user
    /// @return referrer The address of the referrer
    function getReferrer(address user) external view returns (address referrer);

    /// @notice Returns the rebate tier for a given referrer
    /// @param referrer The address of the referrer
    /// @return tier The rebate tier
    function getRebateTier(address referrer) external view returns (RebateTier tier);

    /// @notice Returns the primary and secondary rebate percents
    /// @return primaryRebatePercents The primary rebate percents (18 decimals)
    /// @return secondaryRebatePercent The secondary rebate percent (18 decimals)
    function getRebatePercents()
        external
        view
        returns (UD60x18[] memory primaryRebatePercents, UD60x18 secondaryRebatePercent);

    /// @notice Returns the primary and secondary rebate percents for a given referrer
    /// @param referrer The address of the referrer
    /// @return primaryRebatePercent The primary rebate percent (18 decimals)
    /// @return secondaryRebatePercent The secondary rebate percent (18 decimals)
    function getRebatePercents(
        address referrer
    ) external view returns (UD60x18 primaryRebatePercent, UD60x18 secondaryRebatePercent);

    /// @notice Returns the rebates for a given referrer
    /// @param referrer The address of the referrer
    /// @return tokens The tokens for which the referrer has rebates
    /// @return rebates The rebates for each token (token decimals)
    function getRebates(address referrer) external view returns (address[] memory tokens, uint256[] memory rebates);

    /// @notice Returns the primary and secondary rebate amounts for a given `user` and `referrer`
    /// @param user The address of the user
    /// @param referrer The address of the referrer
    /// @param tradingFee The trading fee (18 decimals)
    /// @return primaryRebate The primary rebate amount (18 decimals)
    /// @return secondaryRebate The secondary rebate amount (18 decimals)
    function getRebateAmounts(
        address user,
        address referrer,
        UD60x18 tradingFee
    ) external view returns (UD60x18 primaryRebate, UD60x18 secondaryRebate);

    /// @notice Sets the rebate tier for a given referrer - caller must be owner
    /// @param referrer The address of the referrer
    /// @param tier The rebate tier
    function setRebateTier(address referrer, RebateTier tier) external;

    /// @notice Sets the primary rebate percents - caller must be owner
    /// @param percent The primary rebate percent (18 decimals)
    /// @param tier The rebate tier
    function setPrimaryRebatePercent(UD60x18 percent, RebateTier tier) external;

    /// @notice Sets the secondary rebate percent - caller must be owner
    /// @param percent The secondary rebate percent (18 decimals)
    function setSecondaryRebatePercent(UD60x18 percent) external;

    /// @notice Pulls the total rebate amount from msg.sender - caller must be an authorized pool
    /// @dev The tokens must be approved for transfer
    /// @param user The address of the user
    /// @param referrer The address of the primary referrer
    /// @param token The address of the token
    /// @param primaryRebate The primary rebate amount (18 decimals)
    /// @param secondaryRebate The secondary rebate amount (18 decimals)
    function useReferral(
        address user,
        address referrer,
        address token,
        UD60x18 primaryRebate,
        UD60x18 secondaryRebate
    ) external;

    /// @notice Claims the rebates for the msg.sender
    /// @param tokens The tokens to claim
    function claimRebate(address[] memory tokens) external;
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {ZERO} from "../libraries/OptionMath.sol";

import {IPoolFactory} from "../factory/PoolFactory.sol";

import {IReferral} from "./IReferral.sol";
import {ReferralStorage} from "./ReferralStorage.sol";

contract Referral is IReferral, OwnableInternal, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    using ReferralStorage for address;

    address internal immutable FACTORY;

    constructor(address factory) {
        FACTORY = factory;
    }

    /// @inheritdoc IReferral
    function getReferrer(address user) public view returns (address) {
        return ReferralStorage.layout().referrals[user];
    }

    /// @inheritdoc IReferral
    function getRebateTier(address referrer) public view returns (RebateTier) {
        return ReferralStorage.layout().rebateTiers[referrer];
    }

    /// @inheritdoc IReferral
    function getRebatePercents()
        external
        view
        returns (UD60x18[] memory primaryRebatePercents, UD60x18 secondaryRebatePercent)
    {
        ReferralStorage.Layout storage l = ReferralStorage.layout();
        primaryRebatePercents = l.primaryRebatePercents;
        secondaryRebatePercent = l.secondaryRebatePercent;
    }

    /// @inheritdoc IReferral
    function getRebatePercents(
        address referrer
    ) public view returns (UD60x18 primaryRebatePercents, UD60x18 secondaryRebatePercent) {
        ReferralStorage.Layout storage l = ReferralStorage.layout();

        return (
            l.primaryRebatePercents[uint8(getRebateTier(referrer))],
            l.referrals[referrer] != address(0) ? l.secondaryRebatePercent : ZERO
        );
    }

    /// @inheritdoc IReferral
    function getRebates(address referrer) public view returns (address[] memory, uint256[] memory) {
        ReferralStorage.Layout storage l = ReferralStorage.layout();

        address[] memory tokens = l.rebateTokens[referrer].toArray();
        uint256[] memory rebates = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            rebates[i] = l.rebates[referrer][tokens[i]];
        }

        return (tokens, rebates);
    }

    /// @inheritdoc IReferral
    function getRebateAmounts(
        address user,
        address referrer,
        UD60x18 tradingFee
    ) external view returns (UD60x18 primaryRebate, UD60x18 secondaryRebate) {
        if (referrer == address(0)) referrer = getReferrer(user);
        if (referrer == address(0)) return (ZERO, ZERO);

        (UD60x18 primaryRebatePercent, UD60x18 secondaryRebatePercent) = getRebatePercents(referrer);
        primaryRebate = tradingFee * primaryRebatePercent;
        secondaryRebate = primaryRebate * secondaryRebatePercent;
    }

    /// @inheritdoc IReferral
    function setRebateTier(address referrer, RebateTier tier) external onlyOwner {
        ReferralStorage.Layout storage l = ReferralStorage.layout();
        emit SetRebateTier(referrer, l.rebateTiers[referrer], tier);
        l.rebateTiers[referrer] = tier;
    }

    /// @inheritdoc IReferral
    function setPrimaryRebatePercent(UD60x18 percent, RebateTier tier) external onlyOwner {
        ReferralStorage.Layout storage l = ReferralStorage.layout();
        emit SetPrimaryRebatePercent(tier, l.primaryRebatePercents[uint8(tier)], percent);
        l.primaryRebatePercents[uint8(tier)] = percent;
    }

    /// @inheritdoc IReferral
    function setSecondaryRebatePercent(UD60x18 percent) external onlyOwner {
        ReferralStorage.Layout storage l = ReferralStorage.layout();
        emit SetSecondaryRebatePercent(l.secondaryRebatePercent, percent);
        l.secondaryRebatePercent = percent;
    }

    /// @inheritdoc IReferral
    function useReferral(
        address user,
        address referrer,
        address token,
        UD60x18 primaryRebate,
        UD60x18 secondaryRebate
    ) external nonReentrant {
        _revertIfPoolNotAuthorized();

        referrer = _trySetReferrer(user, referrer);
        if (referrer == address(0)) return;

        UD60x18 totalRebate = primaryRebate + secondaryRebate;
        if (totalRebate == ZERO) return;

        IERC20(token).safeTransferFrom(msg.sender, address(this), token.toTokenDecimals(totalRebate));

        ReferralStorage.Layout storage l = ReferralStorage.layout();
        address secondaryReferrer = l.referrals[referrer];
        _tryUpdateRebate(l, secondaryReferrer, token, secondaryRebate);
        _tryUpdateRebate(l, referrer, token, primaryRebate);

        (UD60x18 primaryRebatePercent, ) = getRebatePercents(referrer);
        emit Refer(user, referrer, secondaryReferrer, token, primaryRebatePercent, primaryRebate, secondaryRebate);
    }

    /// @inheritdoc IReferral
    function claimRebate(address[] memory tokens) external nonReentrant {
        ReferralStorage.Layout storage l = ReferralStorage.layout();

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 rebate = l.rebates[msg.sender][tokens[i]];
            if (rebate == 0) continue;

            l.rebates[msg.sender][tokens[i]] = 0;
            l.rebateTokens[msg.sender].remove(tokens[i]);

            IERC20(tokens[i]).safeTransfer(msg.sender, rebate);
            emit ClaimRebate(msg.sender, tokens[i], rebate);
        }
    }

    /// @notice Updates the `referrer` rebate balance and rebate tokens, if `amount` is greater than zero
    function _tryUpdateRebate(
        ReferralStorage.Layout storage l,
        address referrer,
        address token,
        UD60x18 amount
    ) internal {
        if (amount > ZERO) {
            l.rebates[referrer][token] += token.toTokenDecimals(amount);
            if (!l.rebateTokens[referrer].contains(token)) l.rebateTokens[referrer].add(token);
        }
    }

    /// @notice Sets the `referrer` for a `user` if they don't already have one. If a referrer has already been set,
    ///         return the existing referrer.
    function _trySetReferrer(address user, address referrer) internal returns (address) {
        ReferralStorage.Layout storage l = ReferralStorage.layout();

        if (l.referrals[user] == address(0)) {
            if (referrer == address(0)) return address(0);
            l.referrals[user] = referrer;
        } else {
            referrer = l.referrals[user];
        }

        return referrer;
    }

    /// @notice Reverts if the caller is not an authorized pool
    function _revertIfPoolNotAuthorized() internal view {
        if (!IPoolFactory(FACTORY).isPool(msg.sender)) revert Referral__PoolNotAuthorized();
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {ProxyUpgradeableOwnable} from "../proxy/ProxyUpgradeableOwnable.sol";

import {ReferralStorage} from "./ReferralStorage.sol";

contract ReferralProxy is ProxyUpgradeableOwnable {
    constructor(address implementation) ProxyUpgradeableOwnable(implementation) {
        ReferralStorage.Layout storage l = ReferralStorage.layout();

        l.primaryRebatePercents.push(UD60x18.wrap(0.05e18)); // 5%
        l.primaryRebatePercents.push(UD60x18.wrap(0.1e18)); // 10%
        l.primaryRebatePercents.push(UD60x18.wrap(0.2e18)); // 20%

        l.secondaryRebatePercent = UD60x18.wrap(0.1e18); // 10%
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";
import {IERC20Metadata} from "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";
import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {OptionMath} from "../libraries/OptionMath.sol";

import {IReferral} from "./IReferral.sol";

library ReferralStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.Referral");

    struct Layout {
        UD60x18[] primaryRebatePercents;
        UD60x18 secondaryRebatePercent;
        mapping(address user => IReferral.RebateTier tier) rebateTiers;
        mapping(address user => address referrer) referrals;
        mapping(address user => mapping(address token => uint256 amount)) rebates;
        mapping(address user => EnumerableSet.AddressSet tokens) rebateTokens;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice Adjust decimals of `value` with 18 decimals to match the `token` decimals
    function toTokenDecimals(address token, UD60x18 value) internal view returns (uint256) {
        uint8 decimals = IERC20Metadata(token).decimals();
        return OptionMath.scaleDecimals(value.unwrap(), 18, decimals);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

interface IRelayerAccessManager {
    error RelayerAccessManager__NotWhitelistedRelayer(address relayer);

    event AddWhitelistedRelayer(address indexed relayer);
    event RemoveWhitelistedRelayer(address indexed relayer);

    /// @notice Add relayers to the whitelist so that they can add price updates
    /// @param relayers The addresses to add to the whitelist
    function addWhitelistedRelayers(address[] calldata relayers) external;

    /// @notice Remove relayers from the whitelist so that they cannot add priced updates
    /// @param relayers The addresses to remove from the whitelist
    function removeWhitelistedRelayers(address[] calldata relayers) external;

    /// @notice Get the list of whitelisted relayers
    /// @return relayers The list of whitelisted relayers
    function getWhitelistedRelayers() external view returns (address[] memory relayers);
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";
import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";

import {IRelayerAccessManager} from "./IRelayerAccessManager.sol";
import {RelayerAccessManagerStorage} from "./RelayerAccessManagerStorage.sol";

abstract contract RelayerAccessManager is IRelayerAccessManager, OwnableInternal {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @inheritdoc IRelayerAccessManager
    function addWhitelistedRelayers(address[] calldata relayers) external virtual onlyOwner {
        RelayerAccessManagerStorage.Layout storage l = RelayerAccessManagerStorage.layout();

        for (uint256 i = 0; i < relayers.length; i++) {
            if (l.whitelistedRelayers.add(relayers[i])) {
                emit AddWhitelistedRelayer(relayers[i]);
            }
        }
    }

    /// @inheritdoc IRelayerAccessManager
    function removeWhitelistedRelayers(address[] calldata relayers) external virtual onlyOwner {
        RelayerAccessManagerStorage.Layout storage l = RelayerAccessManagerStorage.layout();

        for (uint256 i = 0; i < relayers.length; i++) {
            if (l.whitelistedRelayers.remove(relayers[i])) {
                emit RemoveWhitelistedRelayer(relayers[i]);
            }
        }
    }

    /// @inheritdoc IRelayerAccessManager
    function getWhitelistedRelayers() external view virtual returns (address[] memory relayers) {
        relayers = RelayerAccessManagerStorage.layout().whitelistedRelayers.toArray();
    }

    /// @notice Revert if `relayer` is not whitelisted
    function _revertIfNotWhitelistedRelayer(address relayer) internal view {
        if (!RelayerAccessManagerStorage.layout().whitelistedRelayers.contains(relayer))
            revert RelayerAccessManager__NotWhitelistedRelayer(relayer);
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

library RelayerAccessManagerStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.RelayerAccessManager");

    struct Layout {
        EnumerableSet.AddressSet whitelistedRelayers;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";

import {IPoolFactory} from "../factory/IPoolFactory.sol";

import {IERC20Router} from "./IERC20Router.sol";

contract ERC20Router is IERC20Router, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable POOL_FACTORY;

    constructor(address poolFactory) {
        POOL_FACTORY = poolFactory;
    }

    /// @inheritdoc IERC20Router
    function safeTransferFrom(address token, address from, address to, uint256 amount) external nonReentrant {
        if (!IPoolFactory(POOL_FACTORY).isPool(msg.sender)) revert ERC20Router__NotAuthorized();

        IERC20(token).safeTransferFrom(from, to, amount);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

interface IERC20Router {
    error ERC20Router__NotAuthorized();

    /// @notice Transfers tokens - caller must be an authorized pool
    /// @param token Address of token to transfer
    /// @param from Address to transfer tokens from
    /// @param to Address to transfer tokens to
    /// @param amount Amount of tokens to transfer
    function safeTransferFrom(address token, address from, address to, uint256 amount) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {IMulticall} from "@solidstate/contracts/utils/IMulticall.sol";

interface IUserSettings is IMulticall {
    /// @notice Enumeration representing different actions which `user` may authorize an `operator` to perform
    enum Action {
        __, // intentionally left blank to prevent 0 from being a valid action
        Annihilate,
        Exercise,
        Settle,
        SettlePosition,
        WriteFrom
    }

    error UserSettings__InvalidAction();
    error UserSettings__InvalidArrayLength();

    event ActionAuthorizationUpdated(
        address indexed user,
        address indexed operator,
        Action[] actions,
        bool[] authorization
    );

    event AuthorizedCostUpdated(address indexed user, UD60x18 amount);

    /// @notice Returns true if `operator` is authorized to perform `action` for `user`
    /// @param user The user who grants authorization
    /// @param operator The operator who is granted authorization
    /// @param action The action `operator` is authorized to perform
    /// @return True if `operator` is authorized to perform `action` for `user`
    function isActionAuthorized(address user, address operator, Action action) external view returns (bool);

    /// @notice Returns the actions and their corresponding authorization states. If the state of an action is true,
    ////        `operator` has been granted authorization by `user` to perform the action on their behalf. Note, the 0th
    ///         indexed enum in Action is omitted from `actions`.
    /// @param user The user who grants authorization
    /// @param operator The operator who is granted authorization
    /// @return actions All available actions a `user` may grant authorization to `operator` for
    /// @return authorization The authorization states of each `action`
    function getActionAuthorization(
        address user,
        address operator
    ) external view returns (Action[] memory actions, bool[] memory authorization);

    /// @notice Sets the authorization state for each action an `operator` may perform on behalf of `user`. `actions`
    ///         must be indexed in the same order as their corresponding `authorization` state.
    /// @param operator The operator who is granted authorization
    /// @param actions The actions to modify authorization state for
    /// @param authorization The authorization states to set for each action
    function setActionAuthorization(address operator, Action[] memory actions, bool[] memory authorization) external;

    /// @notice Returns the users authorized cost in the ERC20 Native token (WETH, WFTM, etc) used in conjunction with
    ///         `exerciseFor`, settleFor`, and `settlePositionFor`
    /// @return The users authorized cost in the ERC20 Native token (WETH, WFTM, etc) (18 decimals)
    function getAuthorizedCost(address user) external view returns (UD60x18);

    /// @notice Sets the users authorized cost in the ERC20 Native token (WETH, WFTM, etc) used in conjunction with
    ///         `exerciseFor`, `settleFor`, and `settlePositionFor`
    /// @param amount The users authorized cost in the ERC20 Native token (WETH, WFTM, etc) (18 decimals)
    function setAuthorizedCost(UD60x18 amount) external;
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import {Multicall} from "@solidstate/contracts/utils/Multicall.sol";

import {IUserSettings} from "./IUserSettings.sol";
import {UserSettingsStorage} from "./UserSettingsStorage.sol";

contract UserSettings is IUserSettings, Multicall, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    /// @inheritdoc IUserSettings
    function isActionAuthorized(address user, address operator, Action action) external view returns (bool) {
        return UserSettingsStorage.layout().authorizedActions[user][operator].contains(uint256(action));
    }

    /// @inheritdoc IUserSettings
    function getActionAuthorization(
        address user,
        address operator
    ) external view returns (Action[] memory actions, bool[] memory authorization) {
        uint256 length = uint256(type(Action).max);
        actions = new Action[](length);
        authorization = new bool[](length);

        UserSettingsStorage.Layout storage l = UserSettingsStorage.layout();
        for (uint256 i = 0; i < length; i++) {
            uint256 action = i + 1; // skip enum 0
            actions[i] = Action(action);
            authorization[i] = l.authorizedActions[user][operator].contains(action);
        }

        return (actions, authorization);
    }

    /// @inheritdoc IUserSettings
    function setActionAuthorization(
        address operator,
        Action[] memory actions,
        bool[] memory authorization
    ) external nonReentrant {
        if (actions.length != authorization.length) revert UserSettings__InvalidArrayLength();

        UserSettingsStorage.Layout storage l = UserSettingsStorage.layout();
        EnumerableSet.UintSet storage authorizedActions = l.authorizedActions[msg.sender][operator];

        for (uint256 i = 0; i < actions.length; i++) {
            Action action = actions[i];
            if (action == Action.__) revert UserSettings__InvalidAction();
            authorization[i] ? authorizedActions.add(uint256(action)) : authorizedActions.remove(uint256(action));
        }

        emit ActionAuthorizationUpdated(msg.sender, operator, actions, authorization);
    }

    /// @inheritdoc IUserSettings
    function getAuthorizedCost(address user) external view returns (UD60x18) {
        return UserSettingsStorage.layout().authorizedCost[user];
    }

    /// @inheritdoc IUserSettings
    function setAuthorizedCost(UD60x18 amount) external nonReentrant {
        UserSettingsStorage.layout().authorizedCost[msg.sender] = amount;
        emit AuthorizedCostUpdated(msg.sender, amount);
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

library UserSettingsStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.UserSettings");

    struct Layout {
        // A set of actions `operator` has been authorized to perform on behalf of `user`
        mapping(address user => mapping(address operator => EnumerableSet.UintSet actions)) authorizedActions;
        mapping(address user => UD60x18 cost) authorizedCost;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@solidstate/contracts/interfaces/IERC4626.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";

import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";

import {ONE} from "../libraries/Constants.sol";
import {IExchangeHelper} from "../utils/IExchangeHelper.sol";

import {FeeConverterStorage} from "./FeeConverterStorage.sol";
import {IFeeConverter} from "./IFeeConverter.sol";
import {IVxPremia} from "./IVxPremia.sol";

/// @author Premia
/// @title A contract receiving all protocol fees, swapping them for premia
contract FeeConverter is IFeeConverter, OwnableInternal, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address private immutable EXCHANGE_HELPER;
    address private immutable USDC;
    address private immutable VX_PREMIA;

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    modifier onlyAuthorized() {
        if (!FeeConverterStorage.layout().isAuthorized[msg.sender]) revert FeeConverter__NotAuthorized();
        _;
    }

    modifier isInitialized() {
        if (FeeConverterStorage.layout().treasury == address(0)) revert FeeConverter__NotInitialized();
        _;
    }

    constructor(address exchangeHelper, address usdc, address vxPremia) {
        EXCHANGE_HELPER = exchangeHelper;
        USDC = usdc;
        VX_PREMIA = vxPremia;
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    receive() external payable {}

    /// @inheritdoc IFeeConverter
    function getExchangeHelper() external view returns (address exchangeHelper) {
        exchangeHelper = EXCHANGE_HELPER;
    }

    /// @inheritdoc IFeeConverter
    function getTreasury() external view returns (address treasury, UD60x18 treasuryShare) {
        FeeConverterStorage.Layout storage l = FeeConverterStorage.layout();
        return (l.treasury, l.treasuryShare);
    }

    ///////////
    // Admin //
    ///////////

    /// @notice Set authorization for address to use the convert function
    /// @param account The account for which to set new authorization status
    /// @param isAuthorized Whether the account is authorized or not
    function setAuthorized(address account, bool isAuthorized) external onlyOwner {
        FeeConverterStorage.layout().isAuthorized[account] = isAuthorized;
        emit SetAuthorized(account, isAuthorized);
    }

    /// @notice Set a new treasury address, and its share (The % of funds allocated to the `treasury` address)
    function setTreasury(address newTreasury, UD60x18 newTreasuryShare) external onlyOwner {
        if (newTreasuryShare > ONE) revert FeeConverter__TreasuryShareGreaterThanOne();

        FeeConverterStorage.Layout storage l = FeeConverterStorage.layout();
        l.treasury = newTreasury;
        l.treasuryShare = newTreasuryShare;

        emit SetTreasury(newTreasury, newTreasuryShare);
    }

    //////////////////////////

    /// @inheritdoc IFeeConverter
    function convert(
        address sourceToken,
        address callee,
        address allowanceTarget,
        bytes calldata data
    ) external isInitialized nonReentrant onlyAuthorized {
        FeeConverterStorage.Layout storage l = FeeConverterStorage.layout();
        uint256 amount = IERC20(sourceToken).balanceOf(address(this));

        if (amount == 0) return;

        uint256 outAmount;

        if (sourceToken == USDC) {
            outAmount = amount;
        } else {
            IERC20(sourceToken).safeTransfer(EXCHANGE_HELPER, amount);

            (outAmount, ) = IExchangeHelper(EXCHANGE_HELPER).swapWithToken(
                sourceToken,
                USDC,
                amount,
                callee,
                allowanceTarget,
                data,
                address(this)
            );
        }

        if (outAmount == 0) return;

        uint256 treasuryAmount = (ud(outAmount) * l.treasuryShare).unwrap();
        uint256 vxPremiaAmount = outAmount - treasuryAmount;

        if (treasuryAmount > 0) {
            IERC20(USDC).safeTransfer(l.treasury, treasuryAmount);
        }

        if (vxPremiaAmount > 0) {
            IERC20(USDC).approve(VX_PREMIA, vxPremiaAmount);
            IVxPremia(VX_PREMIA).addRewards(vxPremiaAmount);
        }

        emit Converted(msg.sender, sourceToken, amount, outAmount, treasuryAmount);
    }

    /// @inheritdoc IFeeConverter
    function redeem(
        address vault,
        uint256 shareAmount
    ) external isInitialized nonReentrant onlyAuthorized returns (uint256 assetAmount) {
        return IERC4626(vault).redeem(shareAmount, address(this), address(this));
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

library FeeConverterStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.FeeConverter");

    struct Layout {
        // Whether the address is authorized to call the convert function or not
        mapping(address => bool) isAuthorized;
        // The treasury address which will receive a portion of the protocol fees
        address treasury;
        // The percentage of protocol fees the treasury will get
        UD60x18 treasuryShare;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

interface IFeeConverter {
    error FeeConverter__NotAuthorized();
    error FeeConverter__NotInitialized();
    error FeeConverter__TreasuryShareGreaterThanOne();

    event Converted(
        address indexed account,
        address indexed token,
        uint256 inAmount,
        uint256 outAmount,
        uint256 treasuryAmount
    );

    event SetAuthorized(address indexed account, bool isAuthorized);
    event SetTreasury(address indexed newTreasury, UD60x18 newTreasuryShare);

    /// @notice get the exchange helper address
    /// @return exchangeHelper exchange helper address
    function getExchangeHelper() external view returns (address exchangeHelper);

    /// @notice get the treasury address and treasuryShare
    /// @return treasury treasury address
    /// @return treasuryShare treasury share (The % of funds allocated to the `treasury` address)
    function getTreasury() external view returns (address treasury, UD60x18 treasuryShare);

    /// @notice convert held tokens to USDC and distribute as rewards
    /// @param sourceToken address of token to convert
    /// @param callee exchange address to call to execute the trade.
    /// @param allowanceTarget address for which to set allowance for the trade
    /// @param data calldata to execute the trade
    function convert(address sourceToken, address callee, address allowanceTarget, bytes calldata data) external;

    /// @notice Redeem shares from an ERC4626 vault
    /// @param vault address of the ERC4626 vault to redeem from
    /// @param shareAmount quantity of shares to redeem
    /// @return assetAmount quantity of assets received
    function redeem(address vault, uint256 shareAmount) external returns (uint256 assetAmount);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

interface IPoolV2ProxyManager {
    function getPoolList() external view returns (address[] memory);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {PremiaStakingStorage} from "./PremiaStakingStorage.sol";
import {IOFT} from "../layerZero/token/oft/IOFT.sol";

import {IERC2612} from "@solidstate/contracts/token/ERC20/permit/IERC2612.sol";

// IERC20Metadata inheritance not possible due to linearization issue
interface IPremiaStaking is IERC2612, IOFT {
    error PremiaStaking__CantTransfer();
    error PremiaStaking__ExcessiveStakePeriod();
    error PremiaStaking__InsufficientSwapOutput();
    error PremiaStaking__NoPendingWithdrawal();
    error PremiaStaking__NotEnoughLiquidity();
    error PremiaStaking__PeriodTooShort();
    error PremiaStaking__StakeLocked();
    error PremiaStaking__StakeNotLocked();
    error PremiaStaking__WithdrawalStillPending();

    event Stake(address indexed user, uint256 amount, uint64 stakePeriod, uint64 lockedUntil);

    event Unstake(address indexed user, uint256 amount, uint256 fee, uint256 startDate);

    event Harvest(address indexed user, uint256 amount);

    event EarlyUnstakeRewardCollected(address indexed user, uint256 amount);

    event Withdraw(address indexed user, uint256 amount);

    event RewardsAdded(uint256 amount);

    struct StakeLevel {
        uint256 amount; // Amount to stake
        uint256 discount; // Discount when amount is reached
    }

    struct SwapArgs {
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

    event BridgeLock(address indexed user, uint64 stakePeriod, uint64 lockedUntil);

    event UpdateLock(address indexed user, uint64 oldStakePeriod, uint64 newStakePeriod);

    /// @notice Returns the reward token address
    /// @return The reward token address
    function getRewardToken() external view returns (address);

    /// @notice add premia tokens as available tokens to be distributed as rewards
    /// @param amount amount of premia tokens to add as rewards
    function addRewards(uint256 amount) external;

    /// @notice get amount of tokens that have not yet been distributed as rewards
    /// @return rewards amount of tokens not yet distributed as rewards
    /// @return unstakeRewards amount of PREMIA not yet claimed from early unstake fees
    function getAvailableRewards() external view returns (uint256 rewards, uint256 unstakeRewards);

    /// @notice get pending amount of tokens to be distributed as rewards to stakers
    /// @return amount of tokens pending to be distributed as rewards
    function getPendingRewards() external view returns (uint256);

    /// @notice Return the total amount of premia pending withdrawal
    function getPendingWithdrawals() external view returns (uint256);

    /// @notice get pending withdrawal data of a user
    /// @return amount pending withdrawal amount
    /// @return startDate start timestamp of withdrawal
    /// @return unlockDate timestamp at which withdrawal becomes available
    function getPendingWithdrawal(
        address user
    ) external view returns (uint256 amount, uint256 startDate, uint256 unlockDate);

    /// @notice get the amount of PREMIA available for withdrawal
    /// @return amount of PREMIA available for withdrawal
    function getAvailablePremiaAmount() external view returns (uint256);

    /// @notice Stake using IERC2612 permit
    /// @param amount The amount of xPremia to stake
    /// @param period The lockup period (in seconds)
    /// @param deadline Deadline after which permit will fail
    /// @param v V
    /// @param r R
    /// @param s S
    function stakeWithPermit(uint256 amount, uint64 period, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /// @notice Lockup xPremia for protocol fee discounts
    ///         Longer period of locking will apply a multiplier on the amount staked, in the fee discount calculation
    /// @param amount The amount of xPremia to stake
    /// @param period The lockup period (in seconds)
    function stake(uint256 amount, uint64 period) external;

    /// @notice update vxPremia lock
    /// @param period The new lockup period (in seconds)
    function updateLock(uint64 period) external;

    /// @notice harvest rewards, convert to PREMIA using exchange helper, and stake
    /// @param s swap arguments
    /// @param stakePeriod The lockup period (in seconds)
    function harvestAndStake(IPremiaStaking.SwapArgs calldata s, uint64 stakePeriod) external;

    /// @notice Harvest rewards directly to user wallet
    function harvest() external;

    /// @notice Get pending rewards amount, including pending pool update
    /// @param user User for which to calculate pending rewards
    /// @return reward amount of pending rewards from protocol fees (in REWARD_TOKEN)
    /// @return unstakeReward amount of pending rewards from early unstake fees (in PREMIA)
    function getPendingUserRewards(address user) external view returns (uint256 reward, uint256 unstakeReward);

    /// @notice unstake tokens before end of the lock period, for a fee
    /// @param amount the amount of vxPremia to unstake
    function earlyUnstake(uint256 amount) external;

    /// @notice get early unstake fee for given user
    /// @param user address of the user
    /// @return feePercentage % fee to pay for early unstake (1e18 = 100%)
    function getEarlyUnstakeFee(address user) external view returns (uint256 feePercentage);

    /// @notice Initiate the withdrawal process by burning xPremia, starting the delay period
    /// @param amount quantity of xPremia to unstake
    function startWithdraw(uint256 amount) external;

    /// @notice Withdraw underlying premia
    function withdraw() external;

    //////////
    // View //
    //////////

    /// Calculate the stake amount of a user, after applying the bonus from the lockup period chosen
    /// @param user The user from which to query the stake amount
    /// @return The user stake amount after applying the bonus
    function getUserPower(address user) external view returns (uint256);

    /// Return the total power across all users (applying the bonus from lockup period chosen)
    /// @return The total power across all users
    function getTotalPower() external view returns (uint256);

    /// @notice Calculate the % of fee discount for user, based on his stake
    /// @param user The _user for which the discount is for
    /// @return Percentage of protocol fee discount
    ///         Ex : 1e17 = 10% fee discount
    function getDiscount(address user) external view returns (uint256);

    /// @notice Get stake levels
    /// @return Stake levels
    ///         Ex : 25e16 = -25%
    function getStakeLevels() external pure returns (StakeLevel[] memory);

    /// @notice Get stake period multiplier
    /// @param period The duration (in seconds) for which tokens are locked
    /// @return The multiplier for this staking period
    ///         Ex : 2e18 = x2
    function getStakePeriodMultiplier(uint256 period) external pure returns (uint256);

    /// @notice Get staking infos of a user
    /// @param user The user address for which to get staking infos
    /// @return The staking infos of the user
    function getUserInfo(address user) external view returns (PremiaStakingStorage.UserInfo memory);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {VxPremiaStorage} from "./VxPremiaStorage.sol";
import {IPremiaStaking} from "./IPremiaStaking.sol";

interface IVxPremia is IPremiaStaking {
    error VxPremia__InvalidPoolAddress();
    error VxPremia__InvalidVoteTarget();
    error VxPremia__NotEnoughVotingPower();

    event AddVote(address indexed voter, VoteVersion indexed version, bytes target, uint256 amount);
    event RemoveVote(address indexed voter, VoteVersion indexed version, bytes target, uint256 amount);

    enum VoteVersion {
        V2, // poolAddress : 20 bytes / isCallPool : 2 bytes
        VaultV3 // vaultAddress : 20 bytes
    }

    /// @notice get total votes for specific pools
    /// @param version version of target (used to know how to decode data)
    /// @param target ABI encoded target of the votes
    /// @return total votes for specific pool
    function getPoolVotes(VoteVersion version, bytes calldata target) external view returns (uint256);

    /// @notice get votes of user
    /// @param user user from which to get votes
    /// @return votes of user
    function getUserVotes(address user) external view returns (VxPremiaStorage.Vote[] memory);

    /// @notice add or remove votes, in the limit of the user voting power
    /// @param votes votes to cast
    function castVotes(VxPremiaStorage.Vote[] calldata votes) external;
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {AddressUtils} from "@solidstate/contracts/utils/AddressUtils.sol";
import {Math} from "@solidstate/contracts/utils/Math.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC2612} from "@solidstate/contracts/token/ERC20/permit/IERC2612.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";

import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";

import {ONE, WAD} from "../libraries/Constants.sol";
import {IExchangeHelper} from "../utils/IExchangeHelper.sol";
import {IPremiaStaking} from "./IPremiaStaking.sol";
import {PremiaStakingStorage} from "./PremiaStakingStorage.sol";
import {OFT} from "../layerZero/token/oft/OFT.sol";
import {OFTCore} from "../layerZero/token/oft/OFTCore.sol";
import {IOFTCore} from "../layerZero/token/oft/IOFTCore.sol";
import {BytesLib} from "../layerZero/util/BytesLib.sol";

contract PremiaStaking is IPremiaStaking, OFT, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using AddressUtils for address;
    using BytesLib for bytes;

    address internal immutable PREMIA;
    address internal immutable REWARD_TOKEN;
    address internal immutable EXCHANGE_HELPER;

    UD60x18 internal constant DECAY_RATE = UD60x18.wrap(270000000000); // 2.7e-7 -> Distribute around half of the current balance over a month
    uint64 internal constant MAX_PERIOD = 4 * 365 days;
    uint256 internal constant ACC_REWARD_PRECISION = 1e30;
    uint256 internal constant MAX_CONTRACT_DISCOUNT = 0.3e18; // -30%
    uint256 internal constant WITHDRAWAL_DELAY = 10 days;
    uint256 internal constant BPS_CONVERSION = 1e14; // 1e18 / 1e4

    struct UpdateArgsInternal {
        address user;
        uint256 balance;
        uint256 oldPower;
        uint256 newPower;
        uint256 reward;
        uint256 unstakeReward;
    }

    constructor(address lzEndpoint, address premia, address rewardToken, address exchangeHelper) OFT(lzEndpoint) {
        PREMIA = premia;
        REWARD_TOKEN = rewardToken;
        EXCHANGE_HELPER = exchangeHelper;
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal virtual override {
        if (from == address(0) || to == address(0)) return;

        revert PremiaStaking__CantTransfer();
    }

    /// @inheritdoc IPremiaStaking
    function getRewardToken() external view returns (address) {
        return REWARD_TOKEN;
    }

    function estimateSendFee(
        uint16 dstChainId,
        bytes memory toAddress,
        uint256 amount,
        bool useZro,
        bytes memory adapterParams
    ) public view virtual override(OFTCore, IOFTCore) returns (uint256 nativeFee, uint256 zroFee) {
        // Convert bytes to address
        address to;
        assembly {
            to := mload(add(toAddress, 32))
        }

        PremiaStakingStorage.UserInfo storage u = PremiaStakingStorage.layout().userInfo[to];

        return
            lzEndpoint.estimateFees(
                dstChainId,
                address(this),
                abi.encode(PT_SEND, to, amount, u.stakePeriod, u.lockedUntil),
                useZro,
                adapterParams
            );
    }

    function _send(
        address from,
        uint16 dstChainId,
        bytes memory,
        uint256 amount,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes memory adapterParams
    ) internal virtual override {
        _updateRewards();
        _beforeUnstake(from, amount);

        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        PremiaStakingStorage.UserInfo storage u = l.userInfo[from];

        UpdateArgsInternal memory args = _getInitialUpdateArgsInternal(l, u, from);

        bytes memory toAddress = abi.encodePacked(from);
        _debitFrom(from, dstChainId, toAddress, amount);

        args.newPower = _calculateUserPower(args.balance - amount + args.unstakeReward, u.stakePeriod);

        _updateUser(l, u, args);

        _lzSend(
            dstChainId,
            abi.encode(PT_SEND, toAddress, amount, u.stakePeriod, u.lockedUntil),
            refundAddress,
            zroPaymentAddress,
            adapterParams,
            msg.value
        );

        emit SendToChain(from, dstChainId, toAddress, amount);
    }

    function _sendAck(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64,
        bytes memory payload
    ) internal virtual override {
        (, bytes memory toAddressBytes, uint256 amount, uint64 stakePeriod, uint64 lockedUntil) = abi.decode(
            payload,
            (uint16, bytes, uint256, uint64, uint64)
        );

        address to = toAddressBytes.toAddress(0);

        _creditTo(to, amount, stakePeriod, lockedUntil, true);
        emit ReceiveFromChain(srcChainId, srcAddress, to, amount);
    }

    function _creditTo(
        address toAddress,
        uint256 amount,
        uint64 stakePeriod,
        uint64 creditLockedUntil,
        bool bridge
    ) internal {
        unchecked {
            _updateRewards();

            PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
            PremiaStakingStorage.UserInfo storage u = l.userInfo[toAddress];

            UpdateArgsInternal memory args = _getInitialUpdateArgsInternal(l, u, toAddress);

            uint64 lockedUntil = u.lockedUntil;

            uint64 lockLeft = uint64(
                _calculateWeightedAverage(
                    creditLockedUntil > block.timestamp ? creditLockedUntil - block.timestamp : 0,
                    lockedUntil > block.timestamp ? lockedUntil - block.timestamp : 0,
                    amount + args.unstakeReward,
                    args.balance
                )
            );

            u.lockedUntil = lockedUntil = uint64(block.timestamp) + lockLeft;
            u.stakePeriod = uint64(
                _calculateWeightedAverage(stakePeriod, u.stakePeriod, amount + args.unstakeReward, args.balance)
            );

            args.newPower = _calculateUserPower(args.balance + amount + args.unstakeReward, u.stakePeriod);

            _mint(toAddress, amount);
            _updateUser(l, u, args);

            if (bridge) {
                emit BridgeLock(toAddress, u.stakePeriod, lockedUntil);
            } else {
                emit Stake(toAddress, amount, u.stakePeriod, lockedUntil);
            }
        }
    }

    /// @inheritdoc IPremiaStaking
    function addRewards(uint256 amount) external nonReentrant {
        _updateRewards();

        IERC20(REWARD_TOKEN).safeTransferFrom(msg.sender, address(this), amount);
        PremiaStakingStorage.layout().availableRewards += amount;

        emit RewardsAdded(amount);
    }

    /// @inheritdoc IPremiaStaking
    function getAvailableRewards() external view returns (uint256 rewards, uint256 unstakeRewards) {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        unchecked {
            rewards = l.availableRewards - getPendingRewards();
        }
        unstakeRewards = l.availableUnstakeRewards;
    }

    /// @inheritdoc IPremiaStaking
    function getPendingRewards() public view returns (uint256) {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        return l.availableRewards - _decay(l.availableRewards, l.lastRewardUpdate, block.timestamp);
    }

    function _updateRewards() internal {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();

        if (l.lastRewardUpdate == 0 || l.totalPower == 0 || l.availableRewards == 0) {
            l.lastRewardUpdate = block.timestamp;
            return;
        }

        uint256 pendingRewards = getPendingRewards();
        l.accRewardPerShare += (pendingRewards * ACC_REWARD_PRECISION) / l.totalPower;

        unchecked {
            l.availableRewards -= pendingRewards;
        }

        l.lastRewardUpdate = block.timestamp;
    }

    /// @inheritdoc IPremiaStaking
    function stakeWithPermit(
        uint256 amount,
        uint64 period,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        IERC2612(PREMIA).permit(msg.sender, address(this), amount, deadline, v, r, s);
        IERC20(PREMIA).safeTransferFrom(msg.sender, address(this), amount);

        _stake(msg.sender, amount, period);
    }

    /// @inheritdoc IPremiaStaking
    function stake(uint256 amount, uint64 period) external nonReentrant {
        IERC20(PREMIA).safeTransferFrom(msg.sender, address(this), amount);
        _stake(msg.sender, amount, period);
    }

    /// @inheritdoc IPremiaStaking
    function updateLock(uint64 period) external nonReentrant {
        if (period > MAX_PERIOD) revert PremiaStaking__ExcessiveStakePeriod();

        _updateRewards();

        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        PremiaStakingStorage.UserInfo storage u = l.userInfo[msg.sender];

        uint64 oldPeriod = u.stakePeriod;

        if (period <= oldPeriod) revert PremiaStaking__PeriodTooShort();

        UpdateArgsInternal memory args = _getInitialUpdateArgsInternal(l, u, msg.sender);

        unchecked {
            uint64 lockToAdd = period - oldPeriod;
            u.lockedUntil = uint64(Math.max(u.lockedUntil, block.timestamp)) + lockToAdd;
            u.stakePeriod = period;

            args.newPower = _calculateUserPower(args.balance + args.unstakeReward, period);
        }

        _updateUser(l, u, args);

        emit UpdateLock(msg.sender, oldPeriod, period);
    }

    /// @inheritdoc IPremiaStaking
    function harvestAndStake(IPremiaStaking.SwapArgs calldata s, uint64 stakePeriod) external nonReentrant {
        uint256 amountRewardToken = _harvest(msg.sender);

        if (amountRewardToken == 0) return;

        IERC20(REWARD_TOKEN).safeTransfer(EXCHANGE_HELPER, amountRewardToken);

        (uint256 amountPremia, ) = IExchangeHelper(EXCHANGE_HELPER).swapWithToken(
            REWARD_TOKEN,
            PREMIA,
            amountRewardToken,
            s.callee,
            s.allowanceTarget,
            s.data,
            s.refundAddress
        );

        if (amountPremia < s.amountOutMin) revert PremiaStaking__InsufficientSwapOutput();

        _stake(msg.sender, amountPremia, stakePeriod);
    }

    function _calculateWeightedAverage(
        uint256 A,
        uint256 B,
        uint256 weightA,
        uint256 weightB
    ) internal pure returns (uint256) {
        return (A * weightA + B * weightB) / (weightA + weightB);
    }

    function _stake(address toAddress, uint256 amount, uint64 stakePeriod) internal {
        if (stakePeriod > MAX_PERIOD) revert PremiaStaking__ExcessiveStakePeriod();

        unchecked {
            _creditTo(toAddress, amount, stakePeriod, uint64(block.timestamp) + stakePeriod, false);
        }
    }

    /// @inheritdoc IPremiaStaking
    function getPendingUserRewards(address user) external view returns (uint256 reward, uint256 unstakeReward) {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        PremiaStakingStorage.UserInfo storage u = l.userInfo[user];

        uint256 accRewardPerShare = l.accRewardPerShare;
        if (l.lastRewardUpdate > 0 && l.availableRewards > 0) {
            accRewardPerShare += (getPendingRewards() * ACC_REWARD_PRECISION) / l.totalPower;
        }

        uint256 power = _calculateUserPower(_balanceOf(user), u.stakePeriod);
        reward = u.reward + _calculateReward(accRewardPerShare, power, u.rewardDebt);

        unstakeReward = _calculateReward(l.accUnstakeRewardPerShare, power, u.unstakeRewardDebt);
    }

    /// @inheritdoc IPremiaStaking
    function harvest() external nonReentrant {
        uint256 amount = _harvest(msg.sender);
        IERC20(REWARD_TOKEN).safeTransfer(msg.sender, amount);
    }

    function _harvest(address account) internal returns (uint256 amount) {
        _updateRewards();

        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        PremiaStakingStorage.UserInfo storage u = l.userInfo[account];

        UpdateArgsInternal memory args = _getInitialUpdateArgsInternal(l, u, account);

        if (args.unstakeReward > 0) {
            args.newPower = _calculateUserPower(args.balance + args.unstakeReward, u.stakePeriod);
        } else {
            args.newPower = args.oldPower;
        }

        _updateUser(l, u, args);

        amount = u.reward;
        u.reward = 0;

        emit Harvest(account, amount);
    }

    function _updateTotalPower(
        PremiaStakingStorage.Layout storage l,
        uint256 oldUserPower,
        uint256 newUserPower
    ) internal {
        if (newUserPower > oldUserPower) {
            l.totalPower += newUserPower - oldUserPower;
        } else if (newUserPower < oldUserPower) {
            l.totalPower -= oldUserPower - newUserPower;
        }
    }

    function _beforeUnstake(address user, uint256 amount) internal virtual {}

    /// @inheritdoc IPremiaStaking
    function earlyUnstake(uint256 amount) external nonReentrant {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();

        _startWithdraw(l, l.userInfo[msg.sender], amount, (ud(amount) * ud(getEarlyUnstakeFee(msg.sender))).unwrap());
    }

    /// @inheritdoc IPremiaStaking
    function getEarlyUnstakeFee(address user) public view returns (uint256 feePercentage) {
        uint256 lockedUntil = PremiaStakingStorage.layout().userInfo[user].lockedUntil;

        if (lockedUntil <= block.timestamp) revert PremiaStaking__StakeNotLocked();

        uint256 lockLeft;

        unchecked {
            lockLeft = lockedUntil - block.timestamp;
            feePercentage = (lockLeft * 0.25e18) / 365 days; // 25% fee per year left
        }

        if (feePercentage > 0.75e18) {
            feePercentage = 0.75e18; // Capped at 75%
        }
    }

    // @dev `getEarlyUnstakeFee` is preferred as it is more precise. This function is kept for backwards compatibility.
    function getEarlyUnstakeFeeBPS(address user) external view returns (uint256 feePercentageBPS) {
        return getEarlyUnstakeFee(user) / BPS_CONVERSION;
    }

    /// @inheritdoc IPremiaStaking
    function startWithdraw(uint256 amount) external nonReentrant {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        PremiaStakingStorage.UserInfo storage u = l.userInfo[msg.sender];

        if (u.lockedUntil > block.timestamp) revert PremiaStaking__StakeLocked();

        _startWithdraw(l, u, amount, 0);
    }

    function _startWithdraw(
        PremiaStakingStorage.Layout storage l,
        PremiaStakingStorage.UserInfo storage u,
        uint256 amount,
        uint256 fee
    ) internal {
        uint256 amountMinusFee;
        unchecked {
            amountMinusFee = amount - fee;
        }

        if (getAvailablePremiaAmount() < amountMinusFee) revert PremiaStaking__NotEnoughLiquidity();

        _updateRewards();
        _beforeUnstake(msg.sender, amount);

        UpdateArgsInternal memory args = _getInitialUpdateArgsInternal(l, u, msg.sender);

        _burn(msg.sender, amount);
        l.pendingWithdrawal += amountMinusFee;

        if (fee > 0) {
            l.accUnstakeRewardPerShare += (fee * ACC_REWARD_PRECISION) / (l.totalPower - args.oldPower); // User who early unstake doesnt collect any of the fee
            l.availableUnstakeRewards += fee;
        }

        args.newPower = _calculateUserPower(args.balance - amount + args.unstakeReward, u.stakePeriod);

        _updateUser(l, u, args);

        l.withdrawals[msg.sender].amount += amountMinusFee;
        l.withdrawals[msg.sender].startDate = block.timestamp;

        emit Unstake(msg.sender, amount, fee, block.timestamp);
    }

    /// @inheritdoc IPremiaStaking
    function withdraw() external nonReentrant {
        _updateRewards();

        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();

        uint256 startDate = l.withdrawals[msg.sender].startDate;

        if (startDate == 0) revert PremiaStaking__NoPendingWithdrawal();

        unchecked {
            if (block.timestamp <= startDate + WITHDRAWAL_DELAY) revert PremiaStaking__WithdrawalStillPending();
        }

        uint256 amount = l.withdrawals[msg.sender].amount;
        l.pendingWithdrawal -= amount;
        delete l.withdrawals[msg.sender];

        IERC20(PREMIA).safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    /// @inheritdoc IPremiaStaking
    function getTotalPower() external view returns (uint256) {
        return PremiaStakingStorage.layout().totalPower;
    }

    /// @inheritdoc IPremiaStaking
    function getUserPower(address user) external view returns (uint256) {
        return _calculateUserPower(_balanceOf(user), PremiaStakingStorage.layout().userInfo[user].stakePeriod);
    }

    /// @inheritdoc IPremiaStaking
    function getDiscount(address user) public view returns (uint256) {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();

        uint256 userPower = _calculateUserPower(_balanceOf(user), l.userInfo[user].stakePeriod);

        if (userPower == 0) return 0;

        // If user is a contract, we use a different formula based on % of total power owned by the contract
        if (user.isContract()) {
            // Require 50% of overall staked power for contract to have max discount
            if (userPower >= l.totalPower >> 1) {
                return MAX_CONTRACT_DISCOUNT;
            } else {
                return (userPower * MAX_CONTRACT_DISCOUNT) / (l.totalPower >> 1);
            }
        }

        IPremiaStaking.StakeLevel[] memory stakeLevels = getStakeLevels();

        uint256 length = stakeLevels.length;

        unchecked {
            for (uint256 i = 0; i < length; i++) {
                IPremiaStaking.StakeLevel memory level = stakeLevels[i];

                if (userPower < level.amount) {
                    uint256 amountPrevLevel;
                    uint256 discountPrevLevel;

                    // If stake is lower, user is in this level, and we need to LERP with prev level to get discount value
                    if (i > 0) {
                        amountPrevLevel = stakeLevels[i - 1].amount;
                        discountPrevLevel = stakeLevels[i - 1].discount;
                    } else {
                        // If this is the first level, prev level is 0 / 0
                        amountPrevLevel = 0;
                        discountPrevLevel = 0;
                    }

                    uint256 remappedDiscount = level.discount - discountPrevLevel;

                    uint256 remappedAmount = level.amount - amountPrevLevel;
                    uint256 remappedPower = userPower - amountPrevLevel;
                    UD60x18 levelProgress = ud(remappedPower * WAD) / ud(remappedAmount * WAD);

                    return discountPrevLevel + (ud(remappedDiscount) * levelProgress).unwrap();
                }
            }

            // If no match found it means user is >= max possible stake, and therefore has max discount possible
            return stakeLevels[length - 1].discount;
        }
    }

    // @dev `getDiscount` is preferred as it is more precise. This function is kept for backwards compatibility.
    function getDiscountBPS(address user) external view returns (uint256) {
        return getDiscount(user) / BPS_CONVERSION;
    }

    /// @inheritdoc IPremiaStaking
    function getUserInfo(address user) external view returns (PremiaStakingStorage.UserInfo memory) {
        return PremiaStakingStorage.layout().userInfo[user];
    }

    /// @inheritdoc IPremiaStaking
    function getPendingWithdrawals() external view returns (uint256) {
        return PremiaStakingStorage.layout().pendingWithdrawal;
    }

    /// @inheritdoc IPremiaStaking
    function getPendingWithdrawal(
        address user
    ) external view returns (uint256 amount, uint256 startDate, uint256 unlockDate) {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        amount = l.withdrawals[user].amount;
        startDate = l.withdrawals[user].startDate;

        unchecked {
            if (startDate > 0) {
                unlockDate = startDate + WITHDRAWAL_DELAY;
            }
        }
    }

    function _decay(
        uint256 pendingRewards,
        uint256 oldTimestamp,
        uint256 newTimestamp
    ) internal pure returns (uint256) {
        return ((ONE - DECAY_RATE).powu(newTimestamp - oldTimestamp) * ud(pendingRewards)).unwrap();
    }

    /// @inheritdoc IPremiaStaking
    function getStakeLevels() public pure returns (IPremiaStaking.StakeLevel[] memory stakeLevels) {
        stakeLevels = new IPremiaStaking.StakeLevel[](4);

        stakeLevels[0] = IPremiaStaking.StakeLevel(5000e18, 0.1e18); // -10%
        stakeLevels[1] = IPremiaStaking.StakeLevel(50000e18, 0.25e18); // -25%
        stakeLevels[2] = IPremiaStaking.StakeLevel(500000e18, 0.35e18); // -35%
        stakeLevels[3] = IPremiaStaking.StakeLevel(2500000e18, 0.6e18); // -60%
    }

    /// @inheritdoc IPremiaStaking
    function getStakePeriodMultiplier(uint256 period) public pure returns (uint256) {
        unchecked {
            uint256 oneYear = 365 days;

            if (period == 0) return 0.25e18; // x0.25
            if (period >= 4 * oneYear) return 4.25e18; // x4.25

            return 0.25e18 + (period * WAD) / oneYear; // 0.25x + 1.0x per year lockup
        }
    }

    /// @dev `getStakePeriodMultiplier` is preferred as it is more precise. This function is kept for backwards compatibility.
    function getStakePeriodMultiplierBPS(uint256 period) external pure returns (uint256) {
        return getStakePeriodMultiplier(period) / BPS_CONVERSION;
    }

    function _calculateUserPower(uint256 balance, uint64 stakePeriod) internal pure returns (uint256) {
        return (ud(balance) * ud(getStakePeriodMultiplier(stakePeriod))).unwrap();
    }

    function _calculateReward(
        uint256 accRewardPerShare,
        uint256 power,
        uint256 rewardDebt
    ) internal pure returns (uint256) {
        return ((accRewardPerShare * power) / ACC_REWARD_PRECISION) - rewardDebt;
    }

    function _creditRewards(
        PremiaStakingStorage.Layout storage l,
        PremiaStakingStorage.UserInfo storage u,
        address user,
        uint256 reward,
        uint256 unstakeReward
    ) internal {
        u.reward += reward;

        if (unstakeReward > 0) {
            l.availableUnstakeRewards -= unstakeReward;
            _mint(user, unstakeReward);
            emit EarlyUnstakeRewardCollected(user, unstakeReward);
        }
    }

    function _getInitialUpdateArgsInternal(
        PremiaStakingStorage.Layout storage l,
        PremiaStakingStorage.UserInfo storage u,
        address user
    ) internal view returns (UpdateArgsInternal memory) {
        UpdateArgsInternal memory args;
        args.user = user;
        args.balance = _balanceOf(user);

        if (args.balance > 0) {
            args.oldPower = _calculateUserPower(args.balance, u.stakePeriod);
        }

        args.reward = _calculateReward(l.accRewardPerShare, args.oldPower, u.rewardDebt);
        args.unstakeReward = _calculateReward(l.accUnstakeRewardPerShare, args.oldPower, u.unstakeRewardDebt);

        return args;
    }

    function _calculateRewardDebt(uint256 accRewardPerShare, uint256 power) internal pure returns (uint256) {
        return (power * accRewardPerShare) / ACC_REWARD_PRECISION;
    }

    function _updateUser(
        PremiaStakingStorage.Layout storage l,
        PremiaStakingStorage.UserInfo storage u,
        UpdateArgsInternal memory args
    ) internal {
        // Update reward debt
        u.rewardDebt = _calculateRewardDebt(l.accRewardPerShare, args.newPower);
        u.unstakeRewardDebt = _calculateRewardDebt(l.accUnstakeRewardPerShare, args.newPower);

        _creditRewards(l, u, args.user, args.reward, args.unstakeReward);
        _updateTotalPower(l, args.oldPower, args.newPower);
    }

    /// @inheritdoc IPremiaStaking
    function getAvailablePremiaAmount() public view returns (uint256) {
        return IERC20(PREMIA).balanceOf(address(this)) - PremiaStakingStorage.layout().pendingWithdrawal;
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

library PremiaStakingStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.staking.PremiaStaking");

    struct Withdrawal {
        uint256 amount; // Premia amount
        uint256 startDate; // Will unlock at startDate + withdrawalDelay
    }

    struct UserInfo {
        uint256 reward; // Amount of rewards accrued which havent been claimed yet
        uint256 rewardDebt; // Debt to subtract from reward calculation
        uint256 unstakeRewardDebt; // Debt to subtract from reward calculation from early unstake fee
        uint64 stakePeriod; // Stake period selected by user
        uint64 lockedUntil; // Timestamp at which the lock ends
    }

    struct Layout {
        uint256 pendingWithdrawal;
        uint256 _deprecated_withdrawalDelay;
        mapping(address => Withdrawal) withdrawals;
        uint256 availableRewards;
        uint256 lastRewardUpdate; // Timestamp of last reward distribution update
        uint256 totalPower; // Total power of all staked tokens (underlying amount with multiplier applied)
        mapping(address => UserInfo) userInfo;
        uint256 accRewardPerShare;
        uint256 accUnstakeRewardPerShare;
        uint256 availableUnstakeRewards;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {ERC20MetadataInternal} from "@solidstate/contracts/token/ERC20/metadata/ERC20MetadataInternal.sol";

import {ProxyUpgradeableOwnable} from "../proxy/ProxyUpgradeableOwnable.sol";

contract VxPremiaProxy is ProxyUpgradeableOwnable, ERC20MetadataInternal {
    constructor(address implementation) ProxyUpgradeableOwnable(implementation) {
        _setName("vxPremia");
        _setSymbol("vxPREMIA");
        _setDecimals(18);
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {IVxPremia} from "./IVxPremia.sol";

library VxPremiaStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.staking.VxPremia");

    struct Vote {
        uint256 amount;
        IVxPremia.VoteVersion version;
        bytes target;
    }

    struct Layout {
        mapping(address => Vote[]) userVotes;
        // Vote version -> Pool identifier -> Vote amount
        mapping(IVxPremia.VoteVersion => mapping(bytes => uint256)) votes;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {ChainlinkAdapterStorage} from "../../adapter/chainlink/ChainlinkAdapterStorage.sol";

contract ChainlinkOraclePriceStub {
    uint16 internal PHASE_ID = 1;
    uint64 internal AGGREGATOR_ROUND_ID;

    uint256[] internal updatedAtTimestamps;
    int256[] internal prices;

    FailureMode internal failureMode;

    enum FailureMode {
        None,
        GetRoundDataRevertWithReason,
        GetRoundDataRevert,
        LastRoundDataRevertWithReason,
        LastRoundDataRevert
    }

    function setup(FailureMode _failureMode, int256[] memory _prices, uint256[] memory _updatedAtTimestamps) external {
        failureMode = _failureMode;

        require(_prices.length == _updatedAtTimestamps.length, "length mismatch");

        AGGREGATOR_ROUND_ID = uint64(_prices.length);

        prices = _prices;
        updatedAtTimestamps = _updatedAtTimestamps;
    }

    function price(uint256 index) external view returns (int256) {
        return prices[index];
    }

    function getRoundData(uint80 roundId) external view returns (uint80, int256, uint256, uint256, uint80) {
        (, uint64 aggregatorRoundId) = ChainlinkAdapterStorage.parseRoundId(roundId);

        if (failureMode == FailureMode.GetRoundDataRevertWithReason) {
            require(false, "reverted with reason");
        }

        if (failureMode == FailureMode.GetRoundDataRevert) {
            revert();
        }

        return (roundId, prices[aggregatorRoundId], 0, updatedAtTimestamps[aggregatorRoundId], 0);
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        uint80 roundId = ChainlinkAdapterStorage.formatRoundId(PHASE_ID, AGGREGATOR_ROUND_ID);
        uint64 aggregatorRoundId = AGGREGATOR_ROUND_ID - 1;

        if (failureMode == FailureMode.LastRoundDataRevertWithReason) {
            require(false, "reverted with reason");
        }

        if (failureMode == FailureMode.LastRoundDataRevert) {
            revert();
        }

        return (roundId, prices[aggregatorRoundId], 0, updatedAtTimestamps[aggregatorRoundId], 0);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";

import {IOracleAdapter} from "../../adapter/IOracleAdapter.sol";

contract OracleAdapterMock {
    address internal immutable BASE;
    address internal immutable QUOTE;

    UD60x18 internal getPriceAmount;
    UD60x18 internal getPriceAtAmount;

    mapping(uint256 => UD60x18) internal getPriceAtAmountMap;

    constructor(address _base, address _quote, UD60x18 _getPriceAmount, UD60x18 _getPriceAtAmount) {
        BASE = _base;
        QUOTE = _quote;
        getPriceAmount = _getPriceAmount;
        getPriceAtAmount = _getPriceAtAmount;
    }

    function upsertPair(address tokenA, address tokenB) external {}

    function setPrice(UD60x18 _getPriceAmount) external {
        getPriceAmount = _getPriceAmount;
    }

    function setPriceAt(uint256 maturity, UD60x18 _getPriceAtAmount) external {
        getPriceAtAmountMap[maturity] = _getPriceAtAmount;
    }

    function setPriceAt(UD60x18 _getPriceAtAmount) external {
        getPriceAtAmount = _getPriceAtAmount;
    }

    function getPrice(address, address) external view returns (UD60x18) {
        return getPriceAmount;
    }

    function getPriceAt(address, address, uint256 maturity) external view returns (UD60x18) {
        if (getPriceAtAmountMap[maturity] != ud(0)) {
            return getPriceAtAmountMap[maturity];
        }

        return getPriceAtAmount;
    }

    function describePricingPath(
        address token
    ) external view returns (IOracleAdapter.AdapterType adapterType, address[][] memory path, uint8[] memory decimals) {
        adapterType = IOracleAdapter.AdapterType.Chainlink;

        path = new address[][](1);
        address[] memory aggregator = new address[](1);

        aggregator[0] = token == BASE
            ? 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
            : 0x158228e08C52F3e2211Ccbc8ec275FA93f6033FC;

        path[0] = aggregator;

        decimals = new uint8[](1);
        decimals[0] = 18;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {SolidStateERC20} from "@solidstate/contracts/token/ERC20/SolidStateERC20.sol";
import {ERC20MetadataStorage} from "@solidstate/contracts/token/ERC20/metadata/ERC20MetadataStorage.sol";

contract ERC20Mock is SolidStateERC20 {
    constructor(string memory symbol, uint8 decimals) {
        ERC20MetadataStorage.layout().symbol = symbol;
        ERC20MetadataStorage.layout().name = symbol;
        ERC20MetadataStorage.layout().decimals = decimals;
    }

    function mint(address _account, uint256 _amount) public {
        _mint(_account, _amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {SD59x18} from "lib/prb-math/src/SD59x18.sol";

import {OptionMath} from "../../libraries/OptionMath.sol";

contract OptionMathMock {
    function helperNormal(SD59x18 x) external pure returns (SD59x18) {
        return OptionMath.helperNormal(x);
    }

    function normalCdf(SD59x18 x) external pure returns (SD59x18) {
        return OptionMath.normalCdf(x);
    }

    function normalPdf(SD59x18 x) external pure returns (SD59x18) {
        return OptionMath.normalPdf(x);
    }

    function relu(SD59x18 x) external pure returns (UD60x18) {
        return OptionMath.relu(x);
    }

    function optionDelta(
        UD60x18 spot,
        UD60x18 strike,
        UD60x18 timeToMaturity,
        UD60x18 volAnnualized,
        UD60x18 riskFreeRate,
        bool isCall
    ) external pure returns (SD59x18) {
        return OptionMath.optionDelta(spot, strike, timeToMaturity, volAnnualized, riskFreeRate, isCall);
    }

    function blackScholesPrice(
        UD60x18 spot,
        UD60x18 strike,
        UD60x18 timeToMaturity,
        UD60x18 volAnnualized,
        UD60x18 riskFreeRate,
        bool isCall
    ) external pure returns (UD60x18) {
        return OptionMath.blackScholesPrice(spot, strike, timeToMaturity, volAnnualized, riskFreeRate, isCall);
    }

    function d1d2(
        UD60x18 spot,
        UD60x18 strike,
        UD60x18 timeToMaturity,
        UD60x18 volAnnualized,
        UD60x18 riskFreeRate
    ) external pure returns (SD59x18 d1, SD59x18 d2) {
        (d1, d2) = OptionMath.d1d2(spot, strike, timeToMaturity, volAnnualized, riskFreeRate);
    }

    function isFriday(uint256 maturity) external pure returns (bool) {
        return OptionMath.isFriday(maturity);
    }

    function isLastFriday(uint256 maturity) external pure returns (bool) {
        return OptionMath.isLastFriday(maturity);
    }

    function calculateTimeToMaturity(uint256 maturity) external view returns (uint256) {
        return OptionMath.calculateTimeToMaturity(maturity);
    }

    function calculateStrikeInterval(UD60x18 strike) external pure returns (UD60x18) {
        return OptionMath.calculateStrikeInterval(strike);
    }

    function logMoneyness(UD60x18 spot, UD60x18 strike) external pure returns (UD60x18) {
        return OptionMath.logMoneyness(spot, strike);
    }

    function initializationFee(UD60x18 spot, UD60x18 strike, uint256 maturity) external view returns (UD60x18) {
        return OptionMath.initializationFee(spot, strike, maturity);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {PoolName} from "../../libraries/PoolName.sol";

contract PoolNameMock {
    function monthToString(uint256 month) external pure returns (string memory) {
        return PoolName.monthToString(month);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {SD59x18} from "lib/prb-math/src/SD59x18.sol";

import {UD50x28} from "../../libraries/UD50x28.sol";
import {Position} from "../../libraries/Position.sol";

contract PositionMock {
    function keyHash(Position.KeyInternal memory self) external pure returns (bytes32) {
        return Position.keyHash(self);
    }

    function isShort(Position.OrderType orderType) external pure returns (bool) {
        return Position.isShort(orderType);
    }

    function isLong(Position.OrderType orderType) external pure returns (bool) {
        return Position.isLong(orderType);
    }

    function pieceWiseLinear(Position.KeyInternal memory self, UD50x28 price) external pure returns (UD50x28) {
        return Position.pieceWiseLinear(self, price);
    }

    function pieceWiseQuadratic(Position.KeyInternal memory self, UD50x28 price) external pure returns (UD50x28) {
        return Position.pieceWiseQuadratic(self, price);
    }

    function collateralToContracts(UD60x18 _collateral, UD60x18 strike, bool isCall) external pure returns (UD60x18) {
        return Position.collateralToContracts(_collateral, strike, isCall);
    }

    function contractsToCollateral(UD60x18 _collateral, UD60x18 strike, bool isCall) external pure returns (UD60x18) {
        return Position.contractsToCollateral(_collateral, strike, isCall);
    }

    function liquidityPerTick(Position.KeyInternal memory self, UD60x18 size) external pure returns (UD50x28) {
        return Position.liquidityPerTick(self, size);
    }

    function bid(Position.KeyInternal memory self, UD60x18 size, UD50x28 price) external pure returns (UD60x18) {
        return Position.bid(self, size, price);
    }

    function collateral(Position.KeyInternal memory self, UD60x18 size, UD50x28 price) external pure returns (UD60x18) {
        return Position.collateral(self, size, price);
    }

    function contracts(Position.KeyInternal memory self, UD60x18 size, UD50x28 price) external pure returns (UD60x18) {
        return Position.contracts(self, size, price);
    }

    function long(Position.KeyInternal memory self, UD60x18 size, UD50x28 price) external pure returns (UD60x18) {
        return Position.long(self, size, price);
    }

    function short(Position.KeyInternal memory self, UD60x18 size, UD50x28 price) external pure returns (UD60x18) {
        return Position.short(self, size, price);
    }

    function calculatePositionUpdate(
        Position.KeyInternal memory self,
        UD60x18 currentBalance,
        SD59x18 amount,
        UD50x28 price
    ) external pure returns (Position.Delta memory delta) {
        return Position.calculatePositionUpdate(self, currentBalance, amount, price);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {Pricing} from "../../libraries/Pricing.sol";
import {UD50x28} from "../../libraries/UD50x28.sol";

contract PricingMock {
    function proportion(UD60x18 lower, UD60x18 upper, UD50x28 marketPrice) external pure returns (UD50x28) {
        return Pricing.proportion(lower, upper, marketPrice);
    }

    function amountOfTicksBetween(UD60x18 lower, UD60x18 upper) external pure returns (UD60x18) {
        return Pricing.amountOfTicksBetween(lower, upper);
    }

    function liquidity(Pricing.Args memory args) external pure returns (UD60x18) {
        return Pricing.liquidity(args);
    }

    function bidLiquidity(Pricing.Args memory args) external pure returns (UD60x18) {
        return Pricing.bidLiquidity(args);
    }

    function askLiquidity(Pricing.Args memory args) external pure returns (UD60x18) {
        return Pricing.askLiquidity(args);
    }

    function maxTradeSize(Pricing.Args memory args) external pure returns (UD60x18) {
        return Pricing.maxTradeSize(args);
    }

    function price(Pricing.Args memory args, UD60x18 tradeSize) external pure returns (UD50x28) {
        return Pricing.price(args, tradeSize);
    }

    function nextPrice(Pricing.Args memory args, UD60x18 tradeSize) external pure returns (UD50x28) {
        return Pricing.nextPrice(args, tradeSize);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {ERC165Base} from "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {ERC1155Base} from "@solidstate/contracts/token/ERC1155/base/ERC1155Base.sol";

contract OptionRewardMock is ERC1155Base, ERC165Base {
    address internal immutable BASE;

    constructor(address base) {
        BASE = base;
    }

    function underwrite(address longReceiver, UD60x18 contractSize) external {
        IERC20(BASE).transferFrom(msg.sender, address(this), contractSize.unwrap());
        _mint(longReceiver, 0, contractSize.unwrap(), "");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";
import {SD59x18} from "lib/prb-math/src/SD59x18.sol";

import {VolatilityOracle} from "../../oracle/VolatilityOracle.sol";
import {VolatilityOracleStorage} from "../../oracle/VolatilityOracleStorage.sol";

contract VolatilityOracleMock is VolatilityOracle {
    using VolatilityOracleStorage for VolatilityOracleStorage.Layout;

    mapping(bytes32 => UD60x18) internal volatilityMap;
    UD60x18 internal riskFreeRate;

    function findInterval(SD59x18[5] memory arr, SD59x18 value) external pure returns (uint256) {
        return VolatilityOracle._findInterval(arr, value);
    }

    function getRiskFreeRate() external view override returns (UD60x18) {
        if (riskFreeRate != ud(0)) return riskFreeRate;

        return VolatilityOracleStorage.layout().riskFreeRate;
    }

    function setRiskFreeRate(UD60x18 value) external {
        riskFreeRate = value;
    }

    function setVolatility(
        address token,
        UD60x18 spot,
        UD60x18 strike,
        UD60x18 timeToMaturity,
        UD60x18 volatility
    ) external {
        volatilityMap[keccak256(abi.encode(token, spot, strike, timeToMaturity))] = volatility;
    }

    function getVolatility(
        address token,
        UD60x18 spot,
        UD60x18 strike,
        UD60x18 timeToMaturity
    ) public view override returns (UD60x18) {
        UD60x18 volatility = volatilityMap[keccak256(abi.encode(token, spot, strike, timeToMaturity))];

        if (volatility != ud(0)) return volatility;

        return super.getVolatility(token, spot, strike, timeToMaturity);
    }

    function getVolatility(
        address token,
        UD60x18 spot,
        UD60x18[] memory strike,
        UD60x18[] memory timeToMaturity
    ) external view override returns (UD60x18[] memory) {
        UD60x18[] memory result = new UD60x18[](strike.length);

        for (uint256 i = 0; i < strike.length; i++) {
            result[i] = volatilityMap[keccak256(abi.encode(token, spot, strike[i], timeToMaturity[i]))];

            if (result[i] == ud(0)) {
                result[i] = super.getVolatility(token, spot, strike[i], timeToMaturity[i]);
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC3156FlashBorrower} from "@solidstate/contracts/interfaces/IERC3156FlashBorrower.sol";

import {IPool} from "../../pool/IPool.sol";

contract FlashLoanMock is IERC3156FlashBorrower {
    bytes32 internal constant FLASH_LOAN_CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    struct FlashLoan {
        address pool;
        address token;
        uint256 amount;
    }

    function singleFlashLoan(FlashLoan memory loan, bool repayFull) external {
        IPool(loan.pool).flashLoan(this, loan.token, loan.amount, abi.encode(new FlashLoan[](0), repayFull));
    }

    function multiFlashLoan(FlashLoan[] memory loans) external {
        FlashLoan memory loan = loans[loans.length - 1];

        // Remove last element from array
        assembly {
            mstore(loans, sub(mload(loans), 1))
        }

        IPool(loan.pool).flashLoan(this, loan.token, loan.amount, abi.encode(loans, true));
    }

    function onFlashLoan(
        address,
        address token,
        uint256 amount,
        uint256 fee,
        bytes memory data
    ) external returns (bytes32) {
        (FlashLoan[] memory loans, bool repayFull) = abi.decode(data, (FlashLoan[], bool));

        if (loans.length > 0) {
            FlashLoan memory nextLoan = loans[loans.length - 1];

            // Remove last element from array
            assembly {
                mstore(loans, sub(mload(loans), 1))
            }

            IPool(nextLoan.pool).flashLoan(this, nextLoan.token, nextLoan.amount, abi.encode(loans, true));
        } else {
            // Logic can be inserted here to do something with the funds, before repaying all flash loans
        }

        uint256 amountToRepay = amount + fee;
        IERC20(token).transfer(msg.sender, repayFull ? amountToRepay : amountToRepay - 1);

        return FLASH_LOAN_CALLBACK_SUCCESS;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {Position} from "../../libraries/Position.sol";
import {Pricing} from "../../libraries/Pricing.sol";
import {UD50x28} from "../../libraries/UD50x28.sol";

import {IPoolInternal} from "../../pool/IPoolInternal.sol";

interface IPoolCoreMock {
    function _getPricing(bool isBuy) external view returns (Pricing.Args memory);

    function formatTokenId(
        address operator,
        UD60x18 lower,
        UD60x18 upper,
        Position.OrderType orderType
    ) external pure returns (uint256 tokenId);

    function quoteOBHash(IPoolInternal.QuoteOB memory quoteOB) external view returns (bytes32);

    function parseTokenId(
        uint256 tokenId
    )
        external
        pure
        returns (uint8 version, address operator, UD60x18 lower, UD60x18 upper, Position.OrderType orderType);

    function exerciseFee(
        address taker,
        UD60x18 size,
        UD60x18 intrinsicValue,
        UD60x18 strike,
        bool isCallPool
    ) external view returns (UD60x18);

    function protocolFees() external view returns (uint256);

    function exposed_cross(bool isBuy) external;

    function exposed_getStrandedArea() external view returns (UD60x18 lower, UD60x18 upper);

    function exposed_getStrandedMarketPriceUpdate(
        Position.KeyInternal memory p,
        bool isBid
    ) external pure returns (UD50x28);

    function exposed_isMarketPriceStranded(Position.KeyInternal memory p, bool isBid) external view returns (bool);

    function exposed_mint(address account, uint256 id, UD60x18 amount) external;

    function getCurrentTick() external view returns (UD60x18);

    function getLiquidityRate() external view returns (UD50x28);

    function getLongRate() external view returns (UD50x28);

    function getShortRate() external view returns (UD50x28);

    function exposed_getTick(UD60x18 price) external view returns (IPoolInternal.Tick memory);

    function exposed_isRateNonTerminating(UD60x18 lower, UD60x18 upper) external pure returns (bool);

    function mint(address account, uint256 id, UD60x18 amount) external;

    function getPositionData(Position.KeyInternal memory p) external view returns (Position.Data memory);

    function forceUpdateClaimableFees(Position.KeyInternal memory p) external;

    function forceUpdateLastDeposit(Position.KeyInternal memory p, uint256 timestamp) external;

    function safeTransferIgnoreDust(address to, uint256 value) external;

    function safeTransferIgnoreDustUD60x18(address to, UD60x18 value) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {IPool} from "../../pool/IPool.sol";

import {IPoolCoreMock} from "./IPoolCoreMock.sol";

interface IPoolMock is IPool, IPoolCoreMock {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";
import {SD59x18, sd} from "lib/prb-math/src/SD59x18.sol";

import {Position} from "../../libraries/Position.sol";
import {Pricing} from "../../libraries/Pricing.sol";
import {UD50x28} from "../../libraries/UD50x28.sol";

import {PoolInternal} from "../../pool/PoolInternal.sol";
import {PoolStorage} from "../../pool/PoolStorage.sol";
import {IPoolInternal} from "../../pool/IPoolInternal.sol";

import {IPoolCoreMock} from "./IPoolCoreMock.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";

contract PoolCoreMock is IPoolCoreMock, PoolInternal {
    using PoolStorage for IERC20;
    using PoolStorage for PoolStorage.Layout;
    using Position for Position.KeyInternal;

    constructor(
        address factory,
        address router,
        address wrappedNativeToken,
        address feeReceiver,
        address referral,
        address settings,
        address vaultRegistry,
        address vxPremia
    ) PoolInternal(factory, router, wrappedNativeToken, feeReceiver, referral, settings, vaultRegistry, vxPremia) {}

    function _getPricing(bool isBuy) external view returns (Pricing.Args memory) {
        PoolStorage.Layout storage l = PoolStorage.layout();
        return _getPricing(l, isBuy);
    }

    function formatTokenId(
        address operator,
        UD60x18 lower,
        UD60x18 upper,
        Position.OrderType orderType
    ) external pure returns (uint256 tokenId) {
        return PoolStorage.formatTokenId(operator, lower, upper, orderType);
    }

    function quoteOBHash(QuoteOB memory quoteOB) external view returns (bytes32) {
        return _quoteOBHash(quoteOB);
    }

    function parseTokenId(
        uint256 tokenId
    )
        external
        pure
        returns (uint8 version, address operator, UD60x18 lower, UD60x18 upper, Position.OrderType orderType)
    {
        return PoolStorage.parseTokenId(tokenId);
    }

    function exerciseFee(
        address taker,
        UD60x18 size,
        UD60x18 intrinsicValue,
        UD60x18 strike,
        bool isCallPool
    ) external view returns (UD60x18) {
        return _exerciseFee(taker, size, intrinsicValue, strike, isCallPool);
    }

    function protocolFees() external view returns (uint256) {
        PoolStorage.Layout storage l = PoolStorage.layout();
        return l.toPoolTokenDecimals(l.protocolFees);
    }

    function exposed_cross(bool isBuy) external {
        _cross(isBuy);
    }

    function exposed_getStrandedArea() external view returns (UD60x18 lower, UD60x18 upper) {
        PoolStorage.Layout storage l = PoolStorage.layout();
        return _getStrandedArea(l);
    }

    function exposed_getStrandedMarketPriceUpdate(
        Position.KeyInternal memory p,
        bool isBid
    ) external pure returns (UD50x28) {
        return _getStrandedMarketPriceUpdate(p, isBid);
    }

    function exposed_isMarketPriceStranded(Position.KeyInternal memory p, bool isBid) external view returns (bool) {
        PoolStorage.Layout storage l = PoolStorage.layout();
        return _isMarketPriceStranded(l, p, isBid);
    }

    function exposed_mint(address account, uint256 id, UD60x18 amount) external {
        _mint(account, id, amount.unwrap(), "");
    }

    function getCurrentTick() external view returns (UD60x18) {
        PoolStorage.Layout storage l = PoolStorage.layout();
        return l.currentTick;
    }

    function getLiquidityRate() external view returns (UD50x28) {
        PoolStorage.Layout storage l = PoolStorage.layout();
        return l.liquidityRate;
    }

    function exposed_getTick(UD60x18 price) external view returns (IPoolInternal.Tick memory) {
        return _getTick(price);
    }

    function exposed_isRateNonTerminating(UD60x18 lower, UD60x18 upper) external pure returns (bool) {
        return _isRateNonTerminating(lower, upper);
    }

    function getLongRate() external view returns (UD50x28) {
        PoolStorage.Layout storage l = PoolStorage.layout();
        return l.longRate;
    }

    function getShortRate() external view returns (UD50x28) {
        PoolStorage.Layout storage l = PoolStorage.layout();
        return l.shortRate;
    }

    function mint(address account, uint256 id, UD60x18 amount) external {
        _mint(account, id, amount.unwrap(), "");
    }

    function getPositionData(Position.KeyInternal memory p) external view returns (Position.Data memory) {
        return PoolStorage.layout().positions[p.keyHash()];
    }

    function forceUpdateClaimableFees(Position.KeyInternal memory p) external {
        PoolStorage.Layout storage l = PoolStorage.layout();

        _updateClaimableFees(
            l,
            p,
            l.positions[p.keyHash()],
            _balanceOfUD60x18(p.owner, PoolStorage.formatTokenId(p.operator, p.lower, p.upper, p.orderType))
        );
    }

    function forceUpdateLastDeposit(Position.KeyInternal memory p, uint256 timestamp) external {
        PoolStorage.layout().positions[p.keyHash()].lastDeposit = timestamp;
    }

    function safeTransferIgnoreDustUD60x18(address to, UD60x18 value) external {
        PoolStorage.Layout storage l = PoolStorage.layout();
        IERC20(l.getPoolToken()).safeTransferIgnoreDust(to, value);
    }

    function safeTransferIgnoreDust(address to, uint256 value) external {
        PoolStorage.Layout storage l = PoolStorage.layout();
        IERC20(l.getPoolToken()).safeTransferIgnoreDust(to, value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {IReferral} from "../../referral/IReferral.sol";

interface IReferralMock is IReferral {
    function __trySetReferrer(address referrer) external returns (address cachedReferrer);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {Referral} from "../../referral/Referral.sol";

import {IReferralMock} from "./IReferralMock.sol";

contract ReferralMock is IReferralMock, Referral {
    constructor(address factory) Referral(factory) {}

    function __trySetReferrer(address referrer) external returns (address) {
        return _trySetReferrer(msg.sender, referrer);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {RelayerAccessManager} from "../../relayer/RelayerAccessManager.sol";

contract RelayerAccessManagerMock is RelayerAccessManager {
    function __revertIfNotWhitelistedRelayer(address relayer) external view {
        _revertIfNotWhitelistedRelayer(relayer);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {PremiaStaking, PremiaStakingStorage} from "../../staking/PremiaStaking.sol";

contract PremiaStakingMock is PremiaStaking {
    constructor(
        address lzEndpoint,
        address premia,
        address rewardToken,
        address exchangeHelper
    ) PremiaStaking(lzEndpoint, premia, rewardToken, exchangeHelper) {}

    function decay(uint256 pendingRewards, uint256 oldTimestamp, uint256 newTimestamp) external pure returns (uint256) {
        return _decay(pendingRewards, oldTimestamp, newTimestamp);
    }

    function _send(
        address from,
        uint16 dstChainId,
        bytes memory,
        uint256 amount,
        address payable,
        address,
        bytes memory
    ) internal virtual override {
        _updateRewards();

        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        PremiaStakingStorage.UserInfo storage u = l.userInfo[from];

        UpdateArgsInternal memory args = _getInitialUpdateArgsInternal(l, u, from);

        bytes memory toAddress = abi.encodePacked(from);
        _debitFrom(from, dstChainId, toAddress, amount);

        args.newPower = _calculateUserPower(args.balance - amount + args.unstakeReward, u.stakePeriod);

        _updateUser(l, u, args);

        emit SendToChain(from, dstChainId, toAddress, amount);
    }

    function creditTo(address toAddress, uint256 amount, uint64 stakePeriod, uint64 lockedUntil) external {
        _creditTo(toAddress, amount, stakePeriod, lockedUntil, false);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {ERC20MetadataStorage} from "@solidstate/contracts/token/ERC20/metadata/ERC20MetadataStorage.sol";

import {ProxyUpgradeableOwnable} from "../../proxy/ProxyUpgradeableOwnable.sol";

contract PremiaStakingProxyMock is ProxyUpgradeableOwnable {
    constructor(address implementation) ProxyUpgradeableOwnable(implementation) {
        ERC20MetadataStorage.Layout storage l = ERC20MetadataStorage.layout();

        l.name = "Staked Premia";
        l.symbol = "vxPREMIA";
        l.decimals = 18;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {SD59x18} from "lib/prb-math/src/SD59x18.sol";
import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {SafeCast} from "@solidstate/contracts/utils/SafeCast.sol";
import {ERC20BaseStorage} from "@solidstate/contracts/token/ERC20/base/ERC20BaseStorage.sol";

import {ZERO} from "../../../../libraries/Constants.sol";
import {DoublyLinkedList} from "../../../../libraries/DoublyLinkedListUD60x18.sol";
import {EnumerableSetUD60x18, EnumerableSet} from "../../../../libraries/EnumerableSetUD60x18.sol";
import {OptionMath} from "../../../../libraries/OptionMath.sol";
import {IPool} from "../../../../pool/IPool.sol";
import {UnderwriterVault} from "../../../../vault/strategies/underwriter/UnderwriterVault.sol";
import {UnderwriterVaultStorage} from "../../../../vault/strategies/underwriter/UnderwriterVaultStorage.sol";

contract UnderwriterVaultMock is UnderwriterVault {
    using DoublyLinkedList for DoublyLinkedList.Uint256List;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSetUD60x18 for EnumerableSet.Bytes32Set;
    using UnderwriterVaultStorage for UnderwriterVaultStorage.Layout;
    using SafeERC20 for IERC20;
    using SafeCast for int256;
    using SafeCast for uint256;

    struct MaturityInfo {
        uint256 maturity;
        UD60x18[] strikes;
        UD60x18[] sizes;
    }

    // Mock variables
    uint256 internal mockTimestamp;
    UD60x18 internal mockSpot;

    constructor(
        address vaultRegistry,
        address feeReceiver,
        address oracle,
        address factory,
        address router,
        address vxPremia,
        address poolDiamond
    ) UnderwriterVault(vaultRegistry, feeReceiver, oracle, factory, router, vxPremia, poolDiamond, address(0)) {}

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        // Leave empty to disable liquidity mining
    }

    function _getBlockTimestamp() internal view override returns (uint256) {
        return mockTimestamp == 0 ? block.timestamp : mockTimestamp;
    }

    function setTimestamp(uint256 newTimestamp) external {
        mockTimestamp = newTimestamp;
    }

    function _getSpotPrice() internal view override returns (UD60x18) {
        return mockSpot == ZERO ? super._getSpotPrice() : mockSpot;
    }

    function setSpotPrice(UD60x18 newSpot) external {
        mockSpot = newSpot;
    }

    function assetDecimals() external view returns (uint8) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        return l.assetDecimals();
    }

    function convertAssetToUD60x18(uint256 value) external view returns (UD60x18) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        return l.convertAssetToUD60x18(value);
    }

    function convertAssetFromUD60x18(UD60x18 value) external view returns (uint256) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        return l.convertAssetFromUD60x18(value);
    }

    function getMaturityAfterTimestamp(uint256 timestamp) external view returns (uint256) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        return l.getMaturityAfterTimestamp(timestamp);
    }

    function getNumberOfUnexpiredListings(uint256 timestamp) external view returns (uint256) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        return l.getNumberOfUnexpiredListings(timestamp);
    }

    function getTotalLiabilitiesExpired() external view returns (UD60x18) {
        return _getTotalLiabilitiesExpired(UnderwriterVaultStorage.layout());
    }

    function getTotalLiabilitiesUnexpired() external view returns (UD60x18) {
        return _getTotalLiabilitiesUnexpired(UnderwriterVaultStorage.layout());
    }

    function getTotalLiabilities() external view returns (UD60x18) {
        return _getTotalLiabilities(UnderwriterVaultStorage.layout());
    }

    function getTotalFairValue() external view returns (UD60x18) {
        return _getTotalFairValue(UnderwriterVaultStorage.layout());
    }

    function getNumberOfListings() external view returns (uint256) {
        return _getNumberOfListings();
    }

    function _getNumberOfListings() internal view returns (uint256) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        uint256 current = l.minMaturity;
        uint256 n = 0;

        while (current <= l.maxMaturity && current != 0) {
            n += l.maturityToStrikes[current].length();
            current = l.maturities.next(current);
        }
        return n;
    }

    function getNumberOfListingsOnMaturity(uint256 maturity) external view returns (uint256) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        if (!l.maturities.contains(maturity)) return 0;
        return l.maturityToStrikes[maturity].length();
    }

    function updateState() external {
        return _updateState(UnderwriterVaultStorage.layout());
    }

    function getLockedSpreadInternal() external view returns (LockedSpreadInternal memory) {
        return _getLockedSpreadInternal(UnderwriterVaultStorage.layout());
    }

    function increasePositionSize(uint256 maturity, UD60x18 strike, UD60x18 posSize) external {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        l.positionSizes[maturity][strike] = l.positionSizes[maturity][strike] + posSize;
    }

    function decreasePositionSize(uint256 maturity, UD60x18 strike, UD60x18 posSize) external {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        l.positionSizes[maturity][strike] = l.positionSizes[maturity][strike] - posSize;
    }

    function getPositionSize(UD60x18 strike, uint256 maturity) external view returns (UD60x18) {
        return UnderwriterVaultStorage.layout().positionSizes[maturity][strike];
    }

    function setLastTradeTimestamp(uint256 timestamp) external {
        UnderwriterVaultStorage.layout().lastTradeTimestamp = timestamp;
    }

    function setTotalLockedAssets(UD60x18 value) external {
        UnderwriterVaultStorage.layout().totalLockedAssets = value;
    }

    function setLastSpreadUnlockUpdate(uint256 value) external {
        UnderwriterVaultStorage.layout().lastSpreadUnlockUpdate = value;
    }

    function getMinMaturity() external view returns (uint256) {
        return UnderwriterVaultStorage.layout().minMaturity;
    }

    function setMinMaturity(uint256 value) external {
        UnderwriterVaultStorage.layout().minMaturity = value;
    }

    function getMaxMaturity() external view returns (uint256) {
        return UnderwriterVaultStorage.layout().maxMaturity;
    }

    function setMaxMaturity(uint256 value) external {
        UnderwriterVaultStorage.layout().maxMaturity = value;
    }

    function setIsCall(bool value) external {
        UnderwriterVaultStorage.layout().isCall = value;
    }

    function setListingsAndSizes(MaturityInfo[] memory infos) external {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        uint256 n = infos.length;

        // Setup data
        l.minMaturity = infos[0].maturity;
        uint256 current = 0;

        for (uint256 i = 0; i < n; i++) {
            l.maturities.insertAfter(current, infos[i].maturity);
            current = infos[i].maturity;

            for (uint256 j = 0; j < infos[i].strikes.length; j++) {
                l.maturityToStrikes[current].add(infos[i].strikes[j]);
                l.positionSizes[current][infos[i].strikes[j]] =
                    l.positionSizes[current][infos[i].strikes[j]] +
                    infos[i].sizes[j];
            }
        }

        l.maxMaturity = current;
    }

    function clearListingsAndSizes() external {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        uint256 current = l.minMaturity;

        while (current <= l.maxMaturity) {
            for (uint256 i = 0; i < l.maturityToStrikes[current].length(); i++) {
                l.positionSizes[current][l.maturityToStrikes[current].at(i)] = ZERO;

                l.maturityToStrikes[current].remove(l.maturityToStrikes[current].at(i));
            }

            uint256 next = l.maturities.next(current);
            if (current > next) {
                l.maturities.remove(current);
                break;
            }

            l.maturities.remove(current);
            current = next;
        }

        l.minMaturity = 0;
        l.maxMaturity = 0;
    }

    function insertMaturity(uint256 maturity, uint256 newMaturity) external {
        UnderwriterVaultStorage.layout().maturities.insertAfter(maturity, newMaturity);
    }

    function insertStrike(uint256 maturity, UD60x18 strike) external {
        UnderwriterVaultStorage.layout().maturityToStrikes[maturity].add(strike);
    }

    function increaseSpreadUnlockingRate(UD60x18 value) external {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        l.spreadUnlockingRate = l.spreadUnlockingRate + value;
    }

    function increaseSpreadUnlockingTick(uint256 maturity, UD60x18 value) external {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        l.spreadUnlockingTicks[maturity] = l.spreadUnlockingTicks[maturity] + value;
    }

    function increaseTotalLockedAssetsNoTransfer(UD60x18 value) external {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        l.totalLockedAssets = l.totalLockedAssets + value;
    }

    function increaseTotalLockedAssets(UD60x18 value) external {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        l.totalLockedAssets = l.totalLockedAssets + value;
        uint256 transfer = l.convertAssetFromUD60x18(value);
        IERC20(_asset()).transfer(address(1), transfer);
    }

    function increaseTotalLockedSpread(UD60x18 value) external {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        l.totalLockedSpread = l.totalLockedSpread + value;
    }

    function increaseTotalShares(uint256 value) external {
        ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
        l.totalSupply += value;
    }

    function setTotalAssets(UD60x18 value) external {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        l.totalAssets = value;
    }

    function increaseTotalAssets(UD60x18 value) external {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        l.totalAssets = l.totalAssets + value;
    }

    function mintMock(address receiver, uint256 value) external {
        _mint(receiver, value);
    }

    function getAvailableAssets() external view returns (UD60x18) {
        return _availableAssetsUD60x18(UnderwriterVaultStorage.layout());
    }

    function getPricePerShare() external view returns (UD60x18) {
        return _getPricePerShareUD60x18();
    }

    function positionSize(uint256 maturity, UD60x18 strike) external view returns (UD60x18) {
        return UnderwriterVaultStorage.layout().positionSizes[maturity][strike];
    }

    function lastSpreadUnlockUpdate() external view returns (uint256) {
        return UnderwriterVaultStorage.layout().lastSpreadUnlockUpdate;
    }

    function spreadUnlockingRate() external view returns (UD60x18) {
        return UnderwriterVaultStorage.layout().spreadUnlockingRate;
    }

    function spreadUnlockingTicks(uint256 maturity) external view returns (UD60x18) {
        return UnderwriterVaultStorage.layout().spreadUnlockingTicks[maturity];
    }

    function totalLockedAssets() external view returns (UD60x18) {
        return UnderwriterVaultStorage.layout().totalLockedAssets;
    }

    function totalLockedSpread() external view returns (UD60x18) {
        return UnderwriterVaultStorage.layout().totalLockedSpread;
    }

    function settleMaturity(uint256 maturity) external {
        _settleMaturity(UnderwriterVaultStorage.layout(), maturity);
    }

    function contains(UD60x18 strike, uint256 maturity) external view returns (bool) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        return l.contains(strike, maturity);
    }

    function addListing(UD60x18 strike, uint256 maturity) external {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        return l.addListing(strike, maturity);
    }

    function removeListing(UD60x18 strike, uint256 maturity) external {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        return l.removeListing(strike, maturity);
    }

    function getPoolAddress(UD60x18 strike, uint256 maturity) external view returns (address) {
        return _getPoolAddress(UnderwriterVaultStorage.layout(), strike, maturity);
    }

    function afterBuy(UD60x18 strike, uint256 maturity, UD60x18 size, UD60x18 spread, UD60x18 premium) external {
        _afterBuy(UnderwriterVaultStorage.layout(), strike, maturity, size, spread, premium);
    }

    function getSpotPrice() public view returns (UD60x18) {
        return _getSpotPrice();
    }

    function getSettlementPrice(uint256 timestamp) public view returns (UD60x18) {
        return _getSettlementPrice(UnderwriterVaultStorage.layout(), timestamp);
    }

    function getTradeBounds() public view returns (UD60x18, UD60x18, UD60x18, UD60x18) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        return (l.minDTE, l.maxDTE, l.minDelta, l.maxDelta);
    }

    function getClevelParams() public view returns (UD60x18, UD60x18, UD60x18, UD60x18) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        return (l.minCLevel, l.maxCLevel, l.alphaCLevel, l.hourlyDecayDiscount);
    }

    function getLastTradeTimestamp() public view returns (uint256) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        return l.lastTradeTimestamp;
    }

    function setMaxClevel(UD60x18 maxCLevel) public {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        l.maxCLevel = maxCLevel;
    }

    function setAlphaCLevel(UD60x18 alphaCLevel) public {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        l.alphaCLevel = alphaCLevel;
    }

    function getDelta(
        UD60x18 spot,
        UD60x18 strike,
        UD60x18 tau,
        UD60x18 sigma,
        UD60x18 rfRate,
        bool isCallOption
    ) public pure returns (SD59x18) {
        return OptionMath.optionDelta(spot, strike, tau, sigma, rfRate, isCallOption);
    }

    function getBlackScholesPrice(
        UD60x18 spot,
        UD60x18 strike,
        UD60x18 tau,
        UD60x18 sigma,
        UD60x18 rfRate,
        bool isCallOption
    ) public pure returns (UD60x18) {
        return OptionMath.blackScholesPrice(spot, strike, tau, sigma, rfRate, isCallOption);
    }

    function isCall() public view returns (bool) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        return l.isCall;
    }

    function maxMaturity() public view returns (uint256) {
        return UnderwriterVaultStorage.layout().maxMaturity;
    }

    function minMaturity() public view returns (uint256) {
        return UnderwriterVaultStorage.layout().minMaturity;
    }

    function mintFromPool(UD60x18 strike, uint256 maturity, UD60x18 size) public {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        address pool = _getPoolAddress(l, strike, maturity);
        UD60x18 allowance = UD60x18.wrap(2e18) * size;
        UD60x18 locked;
        if (!l.isCall) {
            allowance = allowance * strike;
            locked = size * strike;
        } else {
            locked = size;
        }
        IERC20(_asset()).approve(ROUTER, allowance.unwrap());

        UD60x18 mintingFee = l.convertAssetToUD60x18(
            IPool(pool).takerFee(address(0), size, l.convertAssetFromUD60x18(ZERO), true, false)
        );

        IPool(pool).writeFrom(address(this), msg.sender, size, address(0));

        l.totalLockedAssets = l.totalLockedAssets + locked;
        l.totalAssets = l.totalAssets - mintingFee;
    }

    function revertIfNotTradeableWithVault(bool isCallVault, bool isCallOption, bool isBuy) external pure {
        _revertIfNotTradeableWithVault(isCallVault, isCallOption, isBuy);
    }

    function revertIfOptionInvalid(UD60x18 strike, uint256 maturity) external view {
        _revertIfOptionInvalid(strike, maturity);
    }

    function revertIfInsufficientFunds(UD60x18 strike, UD60x18 size, UD60x18 availableAssets) external view {
        _revertIfInsufficientFunds(strike, size, availableAssets);
    }

    function revertIfOutOfDTEBounds(UD60x18 value, UD60x18 minimum, UD60x18 maximum) external pure {
        _revertIfOutOfDTEBounds(value, minimum, maximum);
    }

    function revertIfOutOfDeltaBounds(UD60x18 value, UD60x18 minimum, UD60x18 maximum) external pure {
        _revertIfOutOfDeltaBounds(value, minimum, maximum);
    }

    function computeCLevel(
        UD60x18 utilisation,
        UD60x18 duration,
        UD60x18 alpha,
        UD60x18 minCLevel,
        UD60x18 maxCLevel,
        UD60x18 decayRate
    ) external pure returns (UD60x18) {
        return _computeCLevel(utilisation, duration, alpha, minCLevel, maxCLevel, decayRate);
    }

    function setProtocolFees(UD60x18 value) external {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        l.protocolFees = value;
    }

    function setManagementFeeRate(UD60x18 value) external {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        l.managementFeeRate = value;
    }

    function setPerformanceFeeRate(UD60x18 value) external {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        l.performanceFeeRate = value;
    }

    function getProtocolFees() external view returns (UD60x18) {
        return UnderwriterVaultStorage.layout().protocolFees;
    }

    function claimFees() external {
        _claimFees(UnderwriterVaultStorage.layout());
    }

    function afterDeposit(address receiver, uint256 assetAmount, uint256 shareAmount) external {
        return _afterDeposit(receiver, assetAmount, shareAmount);
    }

    function beforeWithdraw(address receiver, uint256 assetAmount, uint256 shareAmount) external {
        return _beforeWithdraw(receiver, assetAmount, shareAmount);
    }

    function getLastManagementFeeTimestamp() external view returns (uint256) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        return l.lastManagementFeeTimestamp;
    }

    function setLastManagementFeeTimestamp(uint256 timestamp) external {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        l.lastManagementFeeTimestamp = timestamp;
    }

    function chargeManagementFees() external {
        _chargeManagementFees();
    }

    function computeManagementFees() external view returns (UD60x18) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        return _computeManagementFee(l, _getBlockTimestamp());
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {IPoolFactory} from "../../factory/IPoolFactory.sol";
import {Vault} from "../../vault/Vault.sol";

contract VaultMock is Vault {
    UD60x18 public utilisation = UD60x18.wrap(1e18);

    constructor(address vaultMining) Vault(vaultMining) {}

    function getUtilisation() public view override returns (UD60x18) {
        return utilisation;
    }

    function setUtilisation(UD60x18 value) external {
        utilisation = value;
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function _totalAssets() internal view override returns (uint256) {
        return _totalSupply();
    }

    function updateSettings(bytes memory settings) external {}

    function getQuote(IPoolFactory.PoolKey calldata, UD60x18, bool, address) external pure returns (uint256 premium) {
        return 0;
    }

    function trade(IPoolFactory.PoolKey calldata poolKey, UD60x18, bool, uint256, address) external {}
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";

import {IExchangeHelper} from "./IExchangeHelper.sol";

/// @title Premia Exchange Helper
/// @dev deployed standalone and referenced by ExchangeProxy
/// @dev do NOT set additional approval to this contract!
contract ExchangeHelper is IExchangeHelper, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @inheritdoc IExchangeHelper
    function swapWithToken(
        address sourceToken,
        address targetToken,
        uint256 sourceTokenAmount,
        address callee,
        address allowanceTarget,
        bytes calldata data,
        address refundAddress
    ) external nonReentrant returns (uint256 amountOut, uint256 sourceLeft) {
        IERC20(sourceToken).approve(allowanceTarget, sourceTokenAmount);

        (bool success, ) = callee.call(data);
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        IERC20(sourceToken).approve(allowanceTarget, 0);

        // refund unused sourceToken
        sourceLeft = IERC20(sourceToken).balanceOf(address(this));
        if (sourceLeft > 0) IERC20(sourceToken).safeTransfer(refundAddress, sourceLeft);

        // send the final amount back to the pool
        amountOut = IERC20(targetToken).balanceOf(address(this));
        IERC20(targetToken).safeTransfer(msg.sender, amountOut);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

/// @title Premia Exchange Helper
/// @dev deployed standalone and referenced by internal functions
/// @dev do NOT set approval to this contract!
interface IExchangeHelper {
    /// @notice perform arbitrary swap transaction
    /// @param sourceToken source token to pull into this address
    /// @param targetToken target token to buy
    /// @param sourceTokenAmount amount of source token to start the trade
    /// @param callee exchange address to call to execute the trade.
    /// @param allowanceTarget address for which to set allowance for the trade
    /// @param data calldata to execute the trade
    /// @param refundAddress address that un-used source token goes to
    /// @return amountOut quantity of targetToken yielded by swap
    /// @return sourceLeft quantity of sourceToken left and refunded to refundAddress
    function swapWithToken(
        address sourceToken,
        address targetToken,
        uint256 sourceTokenAmount,
        address callee,
        address allowanceTarget,
        bytes calldata data,
        address refundAddress
    ) external returns (uint256 amountOut, uint256 sourceLeft);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

/// @notice Placeholder contract that can be used to deploy a proxy without initial implementation
contract Placeholder {
    function placeholder() external {}
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {ISolidStateERC4626} from "@solidstate/contracts/token/ERC4626/ISolidStateERC4626.sol";

import {IPoolFactory} from "../factory/IPoolFactory.sol";

interface IVault is ISolidStateERC4626 {
    // Errors
    error Vault__AboveMaxSlippage(UD60x18 totalPremium, UD60x18 premiumLimit);
    error Vault__AddressZero();
    error Vault__InsufficientFunds();
    error Vault__InvariantViolated();
    error Vault__MaximumAmountExceeded(UD60x18 maximum, UD60x18 amount);
    error Vault__OptionExpired(uint256 timestamp, uint256 maturity);
    error Vault__OptionPoolNotListed();
    error Vault__OptionTypeMismatchWithVault();
    error Vault__OutOfDeltaBounds();
    error Vault__OutOfDTEBounds();
    error Vault__SettingsNotFromRegistry();
    error Vault__SettingsUpdateIsEmpty();
    error Vault__StrikeZero();
    error Vault__TradeMustBeBuy();
    error Vault__TransferExceedsBalance(UD60x18 balance, UD60x18 amount);
    error Vault__ZeroAsset();
    error Vault__ZeroShares();
    error Vault__ZeroSize();

    // Events
    event UpdateQuotes();

    event Trade(
        address indexed user,
        address indexed pool,
        UD60x18 contractSize,
        bool isBuy,
        UD60x18 premium,
        UD60x18 takerFee,
        UD60x18 makerRebate,
        UD60x18 vaultFee
    );

    event Swap(
        address indexed sender,
        address recipient,
        address indexed tokenIn,
        address indexed tokenOut,
        UD60x18 amountIn,
        UD60x18 amountOut,
        UD60x18 takerFee,
        UD60x18 makerRebate,
        UD60x18 vaultFee
    );

    event Borrow(
        bytes32 indexed borrowId,
        address indexed from,
        address indexed borrowToken,
        address collateralToken,
        UD60x18 sizeBorrowed,
        UD60x18 collateralLocked,
        UD60x18 borrowFee
    );

    event BorrowLiquidated(
        bytes32 indexed borrowId,
        address indexed from,
        address indexed collateralToken,
        UD60x18 collateralLiquidated
    );

    event RepayBorrow(
        bytes32 indexed borrowId,
        address indexed from,
        address indexed borrowToken,
        address collateralToken,
        UD60x18 amountRepaid,
        UD60x18 collateralUnlocked,
        UD60x18 repayFee
    );

    event ManagementFeePaid(address indexed recipient, uint256 managementFee);

    event PerformanceFeePaid(address indexed recipient, uint256 performanceFee);

    event ClaimProtocolFees(address indexed feeReceiver, uint256 feesClaimed);

    /// @notice Updates the vault settings
    /// @param settings Encoding of the new settings
    function updateSettings(bytes memory settings) external;

    /// @notice Returns the trade quote premium
    /// @param poolKey The option pool key
    /// @param size The size of the trade
    /// @param isBuy Whether the trade is a buy or sell
    /// @param taker The address of the taker
    /// @return premium The trade quote premium
    function getQuote(
        IPoolFactory.PoolKey calldata poolKey,
        UD60x18 size,
        bool isBuy,
        address taker
    ) external view returns (uint256 premium);

    /// @notice Executes a trade with the vault
    /// @param poolKey The option pool key
    /// @param size The size of the trade
    /// @param isBuy Whether the trade is a buy or sell
    /// @param premiumLimit The premium limit of the trade
    /// @param referrer The address of the referrer
    function trade(
        IPoolFactory.PoolKey calldata poolKey,
        UD60x18 size,
        bool isBuy,
        uint256 premiumLimit,
        address referrer
    ) external;

    /// @notice Returns the utilisation rate of the vault
    /// @return The utilisation rate of the vault
    function getUtilisation() external view returns (UD60x18);
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

    /// @notice Gets the settings for the vaultType.
    /// @param vaultType The vault type.
    /// @return The vault settings.
    function getSettings(bytes32 vaultType) external view returns (bytes memory);

    /// @notice Sets the settings for the vaultType.
    /// @param vaultType The vault type.
    /// @param updatedSettings The updated settings for the vault type.
    function updateSettings(bytes32 vaultType, bytes memory updatedSettings) external;

    /// @notice Gets the implementation for the vaultType.
    /// @param vaultType The vault type.
    /// @return The implementation address.
    function getImplementation(bytes32 vaultType) external view returns (address);

    /// @notice Sets the implementation for the vaultType.
    /// @param vaultType The vault type.
    /// @param implementation The implementation contract address
    function setImplementation(bytes32 vaultType, address implementation) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {SD59x18} from "lib/prb-math/src/SD59x18.sol";
import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

import {IVault} from "../../../vault/IVault.sol";

interface IUnderwriterVault is IVault {
    // Errors
    error Vault__UtilisationOutOfBounds();

    // Structs
    struct UnderwriterVaultSettings {
        // The curvature parameter
        UD60x18 alpha;
        // The decay rate of the C-level back down to ordinary level
        UD60x18 hourlyDecayDiscount;
        // The minimum C-level allowed by the C-level mechanism
        UD60x18 minCLevel;
        // The maximum C-level allowed by the C-level mechanism
        UD60x18 maxCLevel;
        // The maximum time until maturity the vault will underwrite
        UD60x18 maxDTE;
        // The minimum time until maturity the vault will underwrite
        UD60x18 minDTE;
        // The maximum delta the vault will underwrite
        UD60x18 minDelta;
        // The minimum delta the vault will underwrite
        UD60x18 maxDelta;
    }

    // The structs below are used as a way to reduce stack depth and avoid "stack too deep" errors
    struct UnexpiredListingVars {
        UD60x18 spot;
        UD60x18 riskFreeRate;
        // A list of strikes for a set of listings
        UD60x18[] strikes;
        // A list of time until maturity (years) for a set of listings
        UD60x18[] timeToMaturities;
        // A list of maturities for a set of listings
        uint256[] maturities;
        UD60x18[] sigmas;
    }

    struct LockedSpreadInternal {
        UD60x18 totalLockedSpread;
        UD60x18 spreadUnlockingRate;
        uint256 lastSpreadUnlockUpdate;
    }

    struct QuoteVars {
        // spot price
        UD60x18 spot;
        // time until maturity (years)
        UD60x18 tau;
        // implied volatility of the listing
        UD60x18 sigma;
        // risk-free rate
        UD60x18 riskFreeRate;
        // option delta
        SD59x18 delta;
        // option price
        UD60x18 price;
        // C-level post-trade
        UD60x18 cLevel;
    }

    struct QuoteInternal {
        // strike price of the listing
        address pool;
        // premium associated to the BSM price of the option (price * size)
        UD60x18 premium;
        // spread added on to premium due to C-level
        UD60x18 spread;
        // fee for minting the option through the pool
        UD60x18 mintingFee;
    }

    struct QuoteArgsInternal {
        // the strike price of the option
        UD60x18 strike;
        // the maturity of the option
        uint256 maturity;
        // whether the option is a call or a put
        bool isCall;
        // the amount of contracts
        UD60x18 size;
        // whether the trade is a buy or a sell
        bool isBuy;
        // the address of the taker
        address taker;
    }

    /// @notice Settles all expired option positions.
    function settle() external;
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";
import {DoublyLinkedList} from "@solidstate/contracts/data/DoublyLinkedList.sol";
import {IERC1155} from "@solidstate/contracts/interfaces/IERC1155.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {ERC4626BaseInternal} from "@solidstate/contracts/token/ERC4626/base/ERC4626BaseInternal.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";

import {IOracleAdapter} from "../../../adapter/IOracleAdapter.sol";
import {IPoolFactory} from "../../../factory/IPoolFactory.sol";
import {ZERO, ONE} from "../../../libraries/Constants.sol";
import {EnumerableSetUD60x18, EnumerableSet} from "../../../libraries/EnumerableSetUD60x18.sol";
import {OptionMath} from "../../../libraries/OptionMath.sol";
import {OptionMathExternal} from "../../../libraries/OptionMathExternal.sol";
import {PRBMathExtra} from "../../../libraries/PRBMathExtra.sol";
import {IVolatilityOracle} from "../../../oracle/IVolatilityOracle.sol";
import {IPool} from "../../../pool/IPool.sol";

import {IUnderwriterVault, IVault} from "./IUnderwriterVault.sol";
import {Vault} from "../../Vault.sol";
import {UnderwriterVaultStorage} from "./UnderwriterVaultStorage.sol";

/// @title An ERC-4626 implementation for underwriting call/put option contracts by using collateral deposited by users
contract UnderwriterVault is IUnderwriterVault, Vault, ReentrancyGuard {
    using DoublyLinkedList for DoublyLinkedList.Uint256List;
    using EnumerableSetUD60x18 for EnumerableSet.Bytes32Set;
    using UnderwriterVaultStorage for UnderwriterVaultStorage.Layout;
    using SafeERC20 for IERC20;

    uint256 internal constant WAD = 1e18;
    uint256 internal constant ONE_YEAR = 365 days;
    uint256 internal constant ONE_HOUR = 1 hours;

    address internal immutable VAULT_REGISTRY;
    address internal immutable FEE_RECEIVER;
    address internal immutable IV_ORACLE;
    address internal immutable FACTORY;
    address internal immutable ROUTER;
    address internal immutable VX_PREMIA;
    address internal immutable POOL_DIAMOND;

    constructor(
        address vaultRegistry,
        address feeReceiver,
        address oracle,
        address factory,
        address router,
        address vxPremia,
        address poolDiamond,
        address vaultMining
    ) Vault(vaultMining) {
        VAULT_REGISTRY = vaultRegistry;
        FEE_RECEIVER = feeReceiver;
        IV_ORACLE = oracle;
        FACTORY = factory;
        ROUTER = router;
        VX_PREMIA = vxPremia;
        POOL_DIAMOND = poolDiamond;
    }

    function getUtilisation() public view override(IVault, Vault) returns (UD60x18) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        UD60x18 totalAssets = l.totalAssets + l.convertAssetToUD60x18(l.pendingAssetsDeposit);
        if (totalAssets == ZERO) return ZERO;

        return l.totalLockedAssets / totalAssets;
    }

    function updateSettings(bytes memory settings) external {
        if (msg.sender != VAULT_REGISTRY) revert Vault__SettingsNotFromRegistry();

        // Decode data and update storage variable
        UnderwriterVaultStorage.layout().updateSettings(settings);
    }

    /// @notice Gets the timestamp of the current block.
    /// @dev We are using a virtual internal function to be able to override in Mock contract for testing purpose
    function _getBlockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @inheritdoc ERC4626BaseInternal
    function _totalAssets() internal view override returns (uint256) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        return l.convertAssetFromUD60x18(l.totalAssets);
    }

    /// @notice Gets the spot price at the current time
    /// @return The spot price at the current time
    function _getSpotPrice() internal view virtual returns (UD60x18) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        return IOracleAdapter(l.oracleAdapter).getPrice(l.base, l.quote);
    }

    /// @notice Gets the spot price at the given timestamp
    /// @param timestamp The time to get the spot price for.
    /// @return The spot price at the given timestamp
    function _getSettlementPrice(
        UnderwriterVaultStorage.Layout storage l,
        uint256 timestamp
    ) internal view returns (UD60x18) {
        return IOracleAdapter(l.oracleAdapter).getPriceAt(l.base, l.quote, timestamp);
    }

    /// @notice Gets the total liabilities value of the basket of expired
    ///         options underwritten by this vault at the current time
    /// @return The total liabilities of the basket of expired options underwritten
    function _getTotalLiabilitiesExpired(UnderwriterVaultStorage.Layout storage l) internal view returns (UD60x18) {
        // Compute fair value for expired unsettled options
        uint256 current = l.minMaturity;

        UD60x18 total;
        while (current <= _getBlockTimestamp() && current != 0) {
            UD60x18 settlement = _getSettlementPrice(l, current);

            for (uint256 i = 0; i < l.maturityToStrikes[current].length(); i++) {
                UD60x18 strike = l.maturityToStrikes[current].at(i);

                UD60x18 price = OptionMathExternal.blackScholesPrice(settlement, strike, ZERO, ONE, ZERO, l.isCall);

                UD60x18 premium = l.isCall ? (price / settlement) : price;
                total = total + premium * l.positionSizes[current][strike];
            }

            current = l.maturities.next(current);
        }

        return total;
    }

    /// @notice Gets the total liabilities value of the basket of unexpired
    ///         options underwritten by this vault at the current time
    /// @return The the total liabilities of the basket of unexpired options underwritten
    function _getTotalLiabilitiesUnexpired(UnderwriterVaultStorage.Layout storage l) internal view returns (UD60x18) {
        uint256 timestamp = _getBlockTimestamp();

        if (l.maxMaturity <= timestamp) return ZERO;

        uint256 current = l.getMaturityAfterTimestamp(timestamp);
        UD60x18 total;

        // Compute fair value for options that have not expired
        uint256 n = l.getNumberOfUnexpiredListings(timestamp);

        UnexpiredListingVars memory vars = UnexpiredListingVars({
            spot: _getSpotPrice(),
            riskFreeRate: IVolatilityOracle(IV_ORACLE).getRiskFreeRate(),
            strikes: new UD60x18[](n),
            timeToMaturities: new UD60x18[](n),
            maturities: new uint256[](n),
            sigmas: new UD60x18[](n)
        });

        {
            uint256 i = 0;
            while (current <= l.maxMaturity && current != 0) {
                for (uint256 j = 0; j < l.maturityToStrikes[current].length(); j++) {
                    vars.strikes[i] = l.maturityToStrikes[current].at(j);
                    vars.timeToMaturities[i] = ud((current - timestamp) * WAD) / ud(OptionMath.ONE_YEAR_TTM * WAD);
                    vars.maturities[i] = current;
                    i++;
                }

                current = l.maturities.next(current);
            }
        }

        vars.sigmas = IVolatilityOracle(IV_ORACLE).getVolatility(
            l.base,
            vars.spot,
            vars.strikes,
            vars.timeToMaturities
        );

        for (uint256 k = 0; k < n; k++) {
            UD60x18 price = OptionMathExternal.blackScholesPrice(
                vars.spot,
                vars.strikes[k],
                vars.timeToMaturities[k],
                vars.sigmas[k],
                vars.riskFreeRate,
                l.isCall
            );
            total = total + price * l.positionSizes[vars.maturities[k]][vars.strikes[k]];
        }

        return l.isCall ? total / vars.spot : total;
    }

    /// @notice Gets the total liabilities of the basket of options underwritten
    ///         by this vault at the current time
    /// @return The total liabilities of the basket of options underwritten
    function _getTotalLiabilities(UnderwriterVaultStorage.Layout storage l) internal view returns (UD60x18) {
        return _getTotalLiabilitiesUnexpired(l) + _getTotalLiabilitiesExpired(l);
    }

    /// @notice Gets the total fair value of the basket of options underwritten
    ///         by this vault at the current time
    /// @return The total fair value of the basket of options underwritten
    function _getTotalFairValue(UnderwriterVaultStorage.Layout storage l) internal view returns (UD60x18) {
        return l.totalLockedAssets - _getTotalLiabilities(l);
    }

    /// @notice Gets the total locked spread for the vault
    /// @return vars The total locked spread
    function _getLockedSpreadInternal(
        UnderwriterVaultStorage.Layout storage l
    ) internal view returns (LockedSpreadInternal memory vars) {
        uint256 current = l.getMaturityAfterTimestamp(l.lastSpreadUnlockUpdate);
        uint256 timestamp = _getBlockTimestamp();

        vars.spreadUnlockingRate = l.spreadUnlockingRate;
        vars.totalLockedSpread = l.totalLockedSpread;
        vars.lastSpreadUnlockUpdate = l.lastSpreadUnlockUpdate;

        while (current <= timestamp && current != 0) {
            vars.totalLockedSpread =
                vars.totalLockedSpread -
                ud((current - vars.lastSpreadUnlockUpdate) * WAD) *
                vars.spreadUnlockingRate;

            vars.spreadUnlockingRate = vars.spreadUnlockingRate - l.spreadUnlockingTicks[current];
            vars.lastSpreadUnlockUpdate = current;
            current = l.maturities.next(current);
        }

        vars.totalLockedSpread =
            vars.totalLockedSpread -
            ud((timestamp - vars.lastSpreadUnlockUpdate) * WAD) *
            vars.spreadUnlockingRate;
        vars.lastSpreadUnlockUpdate = timestamp;
    }

    /// @dev _balanceOf returns the balance of the ERC20 share token which is always in 18 decimal places,
    ///      therefore no further scaling has to be applied
    function _balanceOfUD60x18(address owner) internal view returns (UD60x18) {
        return ud(_balanceOf(owner));
    }

    function _totalSupplyUD60x18() internal view returns (UD60x18) {
        return ud(_totalSupply());
    }

    /// @notice Gets the current amount of available assets
    /// @return The amount of available assets
    function _availableAssetsUD60x18(UnderwriterVaultStorage.Layout storage l) internal view returns (UD60x18) {
        return l.totalAssets - l.totalLockedAssets - _getLockedSpreadInternal(l).totalLockedSpread;
    }

    /// @notice Gets the current price per share for the vault
    /// @return The current price per share
    function _getPricePerShareUD60x18() internal view returns (UD60x18) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        if ((_totalSupplyUD60x18() != ZERO) && (l.totalAssets != ZERO)) {
            UD60x18 managementFeeInShares = _computeManagementFee(l, _getBlockTimestamp());
            UD60x18 totalAssets = _availableAssetsUD60x18(l) + _getTotalFairValue(l);
            return totalAssets / (_totalSupplyUD60x18() + managementFeeInShares);
        }

        return ONE;
    }

    /// @notice updates total spread in storage to be able to compute the price per share
    function _updateState(UnderwriterVaultStorage.Layout storage l) internal {
        if (l.maxMaturity > l.lastSpreadUnlockUpdate) {
            LockedSpreadInternal memory vars = _getLockedSpreadInternal(l);

            l.totalLockedSpread = vars.totalLockedSpread;
            l.spreadUnlockingRate = vars.spreadUnlockingRate;
            l.lastSpreadUnlockUpdate = vars.lastSpreadUnlockUpdate;
        }
    }

    function _convertToSharesUD60x18(UD60x18 assetAmount, UD60x18 pps) internal view returns (UD60x18 shareAmount) {
        if (_totalSupplyUD60x18() == ZERO) {
            shareAmount = assetAmount;
        } else {
            if (UnderwriterVaultStorage.layout().totalAssets == ZERO) {
                shareAmount = assetAmount;
            } else {
                shareAmount = assetAmount / pps;
            }
        }
    }

    /// @inheritdoc ERC4626BaseInternal
    function _convertToShares(uint256 assetAmount) internal view override returns (uint256 shareAmount) {
        return
            _convertToSharesUD60x18(
                UnderwriterVaultStorage.layout().convertAssetToUD60x18(assetAmount),
                _getPricePerShareUD60x18()
            ).unwrap();
    }

    function _convertToAssetsUD60x18(UD60x18 shareAmount, UD60x18 pps) internal view returns (UD60x18 assetAmount) {
        _revertIfZeroShares(_totalSupplyUD60x18().unwrap());

        assetAmount = shareAmount * pps;
    }

    /// @inheritdoc ERC4626BaseInternal
    function _convertToAssets(uint256 shareAmount) internal view virtual override returns (uint256 assetAmount) {
        UD60x18 assets = _convertToAssetsUD60x18(ud(shareAmount), _getPricePerShareUD60x18());
        assetAmount = UnderwriterVaultStorage.layout().convertAssetFromUD60x18(assets);
    }

    /// @inheritdoc ERC4626BaseInternal
    function _deposit(
        uint256 assetAmount,
        address receiver
    ) internal virtual override nonReentrant returns (uint256 shareAmount) {
        _revertIfAddressZero(receiver);
        _revertIfZeroAsset(assetAmount);

        // charge management fees such that the timestamp is up to date
        _chargeManagementFees();

        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        l.pendingAssetsDeposit = assetAmount;
        shareAmount = super._deposit(assetAmount, receiver);
        if (l.pendingAssetsDeposit != assetAmount) revert Vault__InvariantViolated(); // Safety check, should never happen
        delete l.pendingAssetsDeposit;
    }

    function _previewMintUD60x18(UD60x18 shareAmount) internal view returns (UD60x18 assetAmount) {
        assetAmount = _totalSupplyUD60x18() == ZERO ? shareAmount : shareAmount * _getPricePerShareUD60x18();
    }

    /// @inheritdoc ERC4626BaseInternal
    function _previewMint(uint256 shareAmount) internal view virtual override returns (uint256 assetAmount) {
        UD60x18 assets = _previewMintUD60x18(ud(shareAmount));
        assetAmount = UnderwriterVaultStorage.layout().convertAssetFromUD60x18(assets);
    }

    /// @inheritdoc ERC4626BaseInternal
    function _mint(
        uint256 shareAmount,
        address receiver
    ) internal virtual override nonReentrant returns (uint256 assetAmount) {
        // charge management fees such that the timestamp is up to date
        _chargeManagementFees();
        return super._mint(shareAmount, receiver);
    }

    function _maxRedeemUD60x18(
        UnderwriterVaultStorage.Layout storage l,
        address owner,
        UD60x18 pps
    ) internal view returns (UD60x18 shareAmount) {
        _revertIfAddressZero(owner);

        return _maxWithdrawUD60x18(l, owner, pps) / pps;
    }

    /// @inheritdoc ERC4626BaseInternal
    function _maxRedeem(address owner) internal view virtual override returns (uint256) {
        return _maxRedeemUD60x18(UnderwriterVaultStorage.layout(), owner, _getPricePerShareUD60x18()).unwrap();
    }

    /// @inheritdoc ERC4626BaseInternal
    function _redeem(
        uint256 shareAmount,
        address receiver,
        address owner
    ) internal virtual override nonReentrant returns (uint256 assetAmount) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        // charge management fees such that vault share holder pays management fees due
        _chargeManagementFees();

        UD60x18 shares = ud(shareAmount);
        UD60x18 pps = _getPricePerShareUD60x18();
        UD60x18 maxRedeem = _maxRedeemUD60x18(l, owner, pps);

        _revertIfMaximumAmountExceeded(maxRedeem, shares);

        assetAmount = l.convertAssetFromUD60x18(shares * pps);

        _withdraw(msg.sender, receiver, owner, assetAmount, shareAmount, 0, 0);
    }

    function _maxWithdrawUD60x18(
        UnderwriterVaultStorage.Layout storage l,
        address owner,
        UD60x18 pps
    ) internal view returns (UD60x18 withdrawableAssets) {
        _revertIfAddressZero(owner);

        UD60x18 assetsOwner = _balanceOfUD60x18(owner) * pps;
        UD60x18 availableAssets = _availableAssetsUD60x18(l);

        withdrawableAssets = assetsOwner > availableAssets ? availableAssets : assetsOwner;
    }

    /// @inheritdoc ERC4626BaseInternal
    function _maxWithdraw(address owner) internal view virtual override returns (uint256 withdrawableAssets) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        withdrawableAssets = l.convertAssetFromUD60x18(_maxWithdrawUD60x18(l, owner, _getPricePerShareUD60x18()));
    }

    function _previewWithdrawUD60x18(
        UnderwriterVaultStorage.Layout storage l,
        UD60x18 assetAmount,
        UD60x18 pps
    ) internal view returns (UD60x18 shareAmount) {
        _revertIfZeroShares(_totalSupplyUD60x18().unwrap());
        if (_availableAssetsUD60x18(l) == ZERO) revert Vault__InsufficientFunds();
        shareAmount = assetAmount / pps;
    }

    /// @inheritdoc ERC4626BaseInternal
    function _previewWithdraw(uint256 assetAmount) internal view virtual override returns (uint256 shareAmount) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        shareAmount = _previewWithdrawUD60x18(l, l.convertAssetToUD60x18(assetAmount), _getPricePerShareUD60x18())
            .unwrap();
    }

    /// @inheritdoc ERC4626BaseInternal
    function _withdraw(
        uint256 assetAmount,
        address receiver,
        address owner
    ) internal virtual override nonReentrant returns (uint256 shareAmount) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        // charge management fees such that vault share holder pays management fees due
        _chargeManagementFees();

        UD60x18 assets = l.convertAssetToUD60x18(assetAmount);
        UD60x18 pps = _getPricePerShareUD60x18();
        UD60x18 maxWithdraw = _maxWithdrawUD60x18(l, owner, pps);

        _revertIfMaximumAmountExceeded(maxWithdraw, assets);

        shareAmount = _previewWithdrawUD60x18(l, assets, pps).unwrap();

        _withdraw(msg.sender, receiver, owner, assetAmount, shareAmount, 0, 0);
    }

    /// @inheritdoc ERC4626BaseInternal
    function _afterDeposit(address, uint256 assetAmount, uint256 shareAmount) internal virtual override {
        _revertIfZeroShares(shareAmount);

        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        // Add assetAmount deposited to user's balance
        // This is needed to compute average price per share
        l.totalAssets = l.totalAssets + l.convertAssetToUD60x18(assetAmount);

        emit UpdateQuotes();
    }

    /// @inheritdoc ERC4626BaseInternal
    function _beforeWithdraw(address owner, uint256 assetAmount, uint256 shareAmount) internal virtual override {
        _revertIfAddressZero(owner);
        _revertIfZeroAsset(assetAmount);
        _revertIfZeroShares(shareAmount);

        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        // Remove the assets from totalAssets
        l.totalAssets = l.totalAssets - l.convertAssetToUD60x18(assetAmount);

        emit UpdateQuotes();
    }

    /// @notice An internal hook inside the buy function that is called after
    ///         logic inside the buy function is run to update state variables
    /// @param strike The strike price of the option.
    /// @param maturity The maturity of the option.
    /// @param size The amount of contracts.
    /// @param spread The spread added on to the premium due to C-level
    function _afterBuy(
        UnderwriterVaultStorage.Layout storage l,
        UD60x18 strike,
        uint256 maturity,
        UD60x18 size,
        UD60x18 spread,
        UD60x18 premium
    ) internal {
        // @magnus: spread state needs to be updated otherwise spread dispersion is inconsistent
        // we can make this function more efficient later on by not writing twice to storage, i.e.
        // compute the updated state, then increment values, then write to storage
        _updateState(l);

        UD60x18 spreadProtocol = spread * l.performanceFeeRate;
        UD60x18 spreadLP = spread - spreadProtocol;

        UD60x18 spreadRateLP = spreadLP / ud((maturity - _getBlockTimestamp()) * WAD);

        l.totalAssets = l.totalAssets + premium + spreadLP;
        l.spreadUnlockingRate = l.spreadUnlockingRate + spreadRateLP;
        l.spreadUnlockingTicks[maturity] = l.spreadUnlockingTicks[maturity] + spreadRateLP;
        l.totalLockedSpread = l.totalLockedSpread + spreadLP;
        l.totalLockedAssets = l.totalLockedAssets + l.collateral(size, strike);
        l.positionSizes[maturity][strike] = l.positionSizes[maturity][strike] + size;
        l.lastTradeTimestamp = _getBlockTimestamp();
        // we cannot mint new shares as we did for management fees as this would require computing the fair value of the options which would be inefficient.
        l.protocolFees = l.protocolFees + spreadProtocol;
        emit PerformanceFeePaid(FEE_RECEIVER, l.convertAssetFromUD60x18(spreadProtocol));
    }

    /// @notice Gets the pool address corresponding to the given strike and maturity. Returns zero address if pool is not deployed.
    /// @param strike The strike price for the pool
    /// @param maturity The maturity for the pool
    /// @return The pool address (zero address if pool is not deployed)
    function _getPoolAddress(
        UnderwriterVaultStorage.Layout storage l,
        UD60x18 strike,
        uint256 maturity
    ) internal view returns (address) {
        // generate struct to grab pool address
        IPoolFactory.PoolKey memory _poolKey = IPoolFactory.PoolKey({
            base: l.base,
            quote: l.quote,
            oracleAdapter: l.oracleAdapter,
            strike: strike,
            maturity: maturity,
            isCallPool: l.isCall
        });

        (address pool, bool isDeployed) = IPoolFactory(FACTORY).getPoolAddress(_poolKey);

        return isDeployed ? pool : address(0);
    }

    /// @notice Calculates the C-level given a utilisation value and time since last trade value (duration).
    ///         (https://www.desmos.com/calculator/0uzv50t7jy)
    /// @param utilisation The utilisation after some collateral is utilised
    /// @param duration The time since last trade (hours)
    /// @param alpha (needs to be filled in)
    /// @param minCLevel The minimum C-level
    /// @param maxCLevel The maximum C-level
    /// @param decayRate The decay rate of the C-level back down to minimum level (decay/hour)
    /// @return The C-level corresponding to the post-utilisation value.
    function _computeCLevel(
        UD60x18 utilisation,
        UD60x18 duration,
        UD60x18 alpha,
        UD60x18 minCLevel,
        UD60x18 maxCLevel,
        UD60x18 decayRate
    ) internal pure returns (UD60x18) {
        if (utilisation > ONE) revert Vault__UtilisationOutOfBounds();

        UD60x18 posExp = (alpha * (ONE - utilisation)).exp();
        UD60x18 alphaExp = alpha.exp();
        UD60x18 k = (alpha * (minCLevel * alphaExp - maxCLevel)) / (alphaExp - ONE);

        UD60x18 cLevel = (k * posExp + maxCLevel * alpha - k) / (alpha * posExp);
        UD60x18 decay = decayRate * duration;

        return PRBMathExtra.max(cLevel <= decay ? ZERO : cLevel - decay, minCLevel);
    }

    /// @notice Ensures that an option is tradeable with the vault.
    /// @param size The amount of contracts
    function _revertIfZeroSize(UD60x18 size) internal pure {
        if (size == ZERO) revert Vault__ZeroSize();
    }

    /// @notice Ensures that a share amount is non zero.
    /// @param shares The amount of shares
    function _revertIfZeroShares(uint256 shares) internal pure {
        if (shares == 0) revert Vault__ZeroShares();
    }

    /// @notice Ensures that an asset amount is non zero.
    /// @param amount The amount of assets
    function _revertIfZeroAsset(uint256 amount) internal pure {
        if (amount == 0) revert Vault__ZeroAsset();
    }

    /// @notice Ensures that an address is non zero.
    /// @param addr The address to check
    function _revertIfAddressZero(address addr) internal pure {
        if (addr == address(0)) revert Vault__AddressZero();
    }

    /// @notice Ensures that an amount is not above maximum
    /// @param maximum The maximum amount
    /// @param amount The amount to check
    function _revertIfMaximumAmountExceeded(UD60x18 maximum, UD60x18 amount) internal pure {
        if (amount > maximum) revert Vault__MaximumAmountExceeded(maximum, amount);
    }

    /// @notice Ensures that an option is tradeable with the vault.
    /// @param isCallVault Whether the vault is a call or put vault.
    /// @param isCallOption Whether the option is a call or put.
    /// @param isBuy Whether the trade is a buy or a sell.
    function _revertIfNotTradeableWithVault(bool isCallVault, bool isCallOption, bool isBuy) internal pure {
        if (!isBuy) revert Vault__TradeMustBeBuy();
        if (isCallOption != isCallVault) revert Vault__OptionTypeMismatchWithVault();
    }

    /// @notice Ensures that an option is valid for trading.
    /// @param strike The strike price of the option.
    /// @param maturity The maturity of the option.
    function _revertIfOptionInvalid(UD60x18 strike, uint256 maturity) internal view {
        // Check non Zero Strike
        if (strike == ZERO) revert Vault__StrikeZero();
        // Check valid maturity
        if (_getBlockTimestamp() >= maturity) revert Vault__OptionExpired(_getBlockTimestamp(), maturity);
    }

    /// @notice Ensures there is sufficient funds for processing a trade.
    /// @param strike The strike price.
    /// @param size The amount of contracts.
    /// @param availableAssets The amount of available assets currently in the vault.
    function _revertIfInsufficientFunds(UD60x18 strike, UD60x18 size, UD60x18 availableAssets) internal view {
        // Check if the vault has sufficient funds
        if (UnderwriterVaultStorage.layout().collateral(size, strike) >= availableAssets)
            revert Vault__InsufficientFunds();
    }

    /// @notice Ensures that a value is within the DTE bounds.
    /// @param value The observed value of the variable.
    /// @param minimum The minimum value the variable can be.
    /// @param maximum The maximum value the variable can be.
    function _revertIfOutOfDTEBounds(UD60x18 value, UD60x18 minimum, UD60x18 maximum) internal pure {
        if (value < minimum || value > maximum) revert Vault__OutOfDTEBounds();
    }

    /// @notice Ensures that a value is within the delta bounds.
    /// @param value The observed value of the variable.
    /// @param minimum The minimum value the variable can be.
    /// @param maximum The maximum value the variable can be.
    function _revertIfOutOfDeltaBounds(UD60x18 value, UD60x18 minimum, UD60x18 maximum) internal pure {
        if (value < minimum || value > maximum) revert Vault__OutOfDeltaBounds();
    }

    /// @notice Ensures that a value is within the delta bounds.
    /// @param totalPremium The total premium of the trade
    /// @param premiumLimit The premium limit of the trade
    /// @param isBuy Whether the trade is a buy or a sell.
    function _revertIfAboveTradeMaxSlippage(UD60x18 totalPremium, UD60x18 premiumLimit, bool isBuy) internal pure {
        if (isBuy && totalPremium > premiumLimit) revert Vault__AboveMaxSlippage(totalPremium, premiumLimit);
        if (!isBuy && totalPremium < premiumLimit) revert Vault__AboveMaxSlippage(totalPremium, premiumLimit);
    }

    /// @notice Get the variables needed in order to compute the quote for a trade
    function _getQuoteInternal(
        UnderwriterVaultStorage.Layout storage l,
        QuoteArgsInternal memory args,
        bool revertIfPoolNotDeployed
    ) internal view returns (QuoteInternal memory quote) {
        _revertIfZeroSize(args.size);
        _revertIfNotTradeableWithVault(l.isCall, args.isCall, args.isBuy);
        _revertIfOptionInvalid(args.strike, args.maturity);

        _revertIfInsufficientFunds(args.strike, args.size, _availableAssetsUD60x18(l));

        QuoteVars memory vars;

        {
            // Compute C-level
            UD60x18 utilisation = (l.totalLockedAssets + l.collateral(args.size, args.strike)) / l.totalAssets;

            UD60x18 hoursSinceLastTx = ud((_getBlockTimestamp() - l.lastTradeTimestamp) * WAD) / ud(ONE_HOUR * WAD);

            vars.cLevel = _computeCLevel(
                utilisation,
                hoursSinceLastTx,
                l.alphaCLevel,
                l.minCLevel,
                l.maxCLevel,
                l.hourlyDecayDiscount
            );
        }

        vars.spot = _getSpotPrice();

        // Compute time until maturity and check bounds
        vars.tau = ud((args.maturity - _getBlockTimestamp()) * WAD) / ud(ONE_YEAR * WAD);
        _revertIfOutOfDTEBounds(vars.tau * ud(365e18), l.minDTE, l.maxDTE);

        vars.sigma = IVolatilityOracle(IV_ORACLE).getVolatility(l.base, vars.spot, args.strike, vars.tau);

        vars.riskFreeRate = IVolatilityOracle(IV_ORACLE).getRiskFreeRate();

        // Compute delta and check bounds
        vars.delta = OptionMathExternal
            .optionDelta(vars.spot, args.strike, vars.tau, vars.sigma, vars.riskFreeRate, l.isCall)
            .abs();

        _revertIfOutOfDeltaBounds(vars.delta.intoUD60x18(), l.minDelta, l.maxDelta);

        vars.price = OptionMathExternal.blackScholesPrice(
            vars.spot,
            args.strike,
            vars.tau,
            vars.sigma,
            vars.riskFreeRate,
            l.isCall
        );

        vars.price = l.isCall ? vars.price / vars.spot : vars.price;

        // Compute output variables
        quote.premium = vars.price * args.size;
        quote.spread = (vars.cLevel - l.minCLevel) * quote.premium;
        quote.pool = _getPoolAddress(l, args.strike, args.maturity);

        if (revertIfPoolNotDeployed && quote.pool == address(0)) revert Vault__OptionPoolNotListed();

        // This is to deal with the scenario where user request a quote for a pool not yet deployed
        // Instead of calling `takerFee` on the pool, we call `_takerFeeLowLevel` directly on `POOL_DIAMOND`.
        // This function doesnt require any data from pool storage and therefore will succeed even if pool is not deployed yet.
        quote.mintingFee = IPool(POOL_DIAMOND)._takerFeeLowLevel(
            args.taker,
            args.size,
            ZERO,
            true,
            false,
            args.strike,
            l.isCall
        );
    }

    /// @inheritdoc IVault
    function getQuote(
        IPoolFactory.PoolKey calldata poolKey,
        UD60x18 size,
        bool isBuy,
        address taker
    ) external view returns (uint256 premium) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        QuoteInternal memory quote = _getQuoteInternal(
            l,
            QuoteArgsInternal({
                strike: poolKey.strike,
                maturity: poolKey.maturity,
                isCall: poolKey.isCallPool,
                size: size,
                isBuy: isBuy,
                taker: taker
            }),
            false
        );

        premium = l.convertAssetFromUD60x18(quote.premium + quote.spread + quote.mintingFee);
    }

    /// @inheritdoc IVault
    function trade(
        IPoolFactory.PoolKey calldata poolKey,
        UD60x18 size,
        bool isBuy,
        uint256 premiumLimit,
        address referrer
    ) external override nonReentrant {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        QuoteInternal memory quote = _getQuoteInternal(
            l,
            QuoteArgsInternal({
                strike: poolKey.strike,
                maturity: poolKey.maturity,
                isCall: poolKey.isCallPool,
                size: size,
                isBuy: isBuy,
                taker: msg.sender
            }),
            true
        );

        UD60x18 totalPremium = quote.premium + quote.spread + quote.mintingFee;

        _revertIfAboveTradeMaxSlippage(totalPremium, l.convertAssetToUD60x18(premiumLimit), isBuy);

        // Add listing
        l.addListing(poolKey.strike, poolKey.maturity);

        // Collect option premium from buyer
        IERC20(_asset()).safeTransferFrom(msg.sender, address(this), l.convertAssetFromUD60x18(totalPremium));

        // Approve transfer of base / quote token
        uint256 approveAmountScaled = l.convertAssetFromUD60x18(l.collateral(size, poolKey.strike) + quote.mintingFee);

        IERC20(_asset()).approve(ROUTER, approveAmountScaled);

        // Mint option and allocate long token
        IPool(quote.pool).writeFrom(address(this), msg.sender, size, referrer);

        // Handle the premiums and spread capture generated
        _afterBuy(l, poolKey.strike, poolKey.maturity, size, quote.spread, quote.premium);

        // Annihilate shorts and longs for user
        UD60x18 shorts = ud(IERC1155(quote.pool).balanceOf(msg.sender, 0));
        UD60x18 longs = ud(IERC1155(quote.pool).balanceOf(msg.sender, 1));
        UD60x18 annihilateSize = PRBMathExtra.min(shorts, longs);
        if (annihilateSize > ZERO) {
            IPool(quote.pool).annihilateFor(msg.sender, annihilateSize);
        }

        // Emit trade event
        emit Trade(msg.sender, quote.pool, size, true, totalPremium, quote.mintingFee, ZERO, quote.spread);

        // Emit event for updated quotes
        emit UpdateQuotes();
    }

    /// @notice Settles all options that are on a single maturity
    /// @param maturity The maturity that options will be settled for
    function _settleMaturity(UnderwriterVaultStorage.Layout storage l, uint256 maturity) internal {
        for (uint256 i = 0; i < l.maturityToStrikes[maturity].length(); i++) {
            UD60x18 strike = l.maturityToStrikes[maturity].at(i);
            UD60x18 positionSize = l.positionSizes[maturity][strike];
            UD60x18 unlockedCollateral = l.isCall ? positionSize : positionSize * strike;
            l.totalLockedAssets = l.totalLockedAssets - unlockedCollateral;
            address pool = _getPoolAddress(l, strike, maturity);
            UD60x18 collateralValue = l.convertAssetToUD60x18(IPool(pool).settle());
            l.totalAssets = l.totalAssets - (unlockedCollateral - collateralValue);
        }
    }

    /// @inheritdoc IUnderwriterVault
    function settle() external override nonReentrant {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();
        // Needs to update state as settle effects the listed postions, i.e. maturities and maturityToStrikes.
        _updateState(l);

        uint256 timestamp = _getBlockTimestamp();

        // Get last maturity that is greater than the current time
        uint256 lastExpired = timestamp >= l.maxMaturity
            ? l.maxMaturity
            : l.maturities.prev(l.getMaturityAfterTimestamp(timestamp));

        uint256 current = l.minMaturity;

        while (current <= lastExpired && current != 0) {
            _settleMaturity(l, current);

            // Remove maturity from data structure
            uint256 next = l.maturities.next(current);
            uint256 numStrikes = l.maturityToStrikes[current].length();
            for (uint256 i = 0; i < numStrikes; i++) {
                UD60x18 strike = l.maturityToStrikes[current].at(0);
                l.positionSizes[current][strike] = ZERO;
                l.removeListing(strike, current);
            }
            current = next;
        }

        // Claim protocol fees
        _claimFees(l);

        emit UpdateQuotes();
    }

    /// @notice Computes and returns the management fee in shares that have to be paid by vault share holders for using the vault.
    /// @param l Contains stored parameters of the vault, including the managementFeeRate and the lastManagementFeeTimestamp
    /// @param timestamp The block's current timestamp.
    /// @return managementFeeInShares Returns the amount due in management fees in terms of shares (18 decimals).
    function _computeManagementFee(
        UnderwriterVaultStorage.Layout storage l,
        uint256 timestamp
    ) internal view returns (UD60x18 managementFeeInShares) {
        if (l.totalAssets == ZERO) {
            managementFeeInShares = ZERO;
        } else {
            UD60x18 timeSinceLastDeposit = ud((timestamp - l.lastManagementFeeTimestamp) * WAD) /
                ud(OptionMath.ONE_YEAR_TTM * WAD);
            // gamma is the percentage we charge in management fees from the totalAssets resulting in the new pps
            // newPPS = A * (1 - gamma) / S = A / ( S * ( 1 / (1 - gamma) )
            // from this we can compute the shares that need to be minted
            // sharesToMint = S * (1 / (1 - gamma)) - S = S * gamma / (1 - gamma)
            UD60x18 gamma = l.managementFeeRate * timeSinceLastDeposit;
            managementFeeInShares = _totalSupplyUD60x18() * (gamma / (ONE - gamma));
        }
    }

    /// @notice Charges the management fees from by liquidity providers.
    function _chargeManagementFees() internal {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        uint256 timestamp = _getBlockTimestamp();
        if (timestamp == l.lastManagementFeeTimestamp) return;

        // if there are no totalAssets we won't charge management fees
        if (l.totalAssets > ZERO) {
            UD60x18 managementFeeInShares = _computeManagementFee(l, timestamp);
            _mint(FEE_RECEIVER, managementFeeInShares.unwrap());
            emit ManagementFeePaid(FEE_RECEIVER, managementFeeInShares.unwrap());
        }

        l.lastManagementFeeTimestamp = timestamp;
    }

    /// @notice Transfers fees to the FEE_RECEIVER.
    function _claimFees(UnderwriterVaultStorage.Layout storage l) internal {
        uint256 claimedFees = l.convertAssetFromUD60x18(l.protocolFees);

        if (claimedFees == 0) return;

        l.protocolFees = ZERO;
        IERC20(_asset()).safeTransfer(FEE_RECEIVER, claimedFees);
        emit ClaimProtocolFees(FEE_RECEIVER, claimedFees);
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {Proxy} from "@solidstate/contracts/proxy/Proxy.sol";
import {ERC20MetadataStorage} from "@solidstate/contracts/token/ERC20/metadata/ERC20MetadataStorage.sol";
import {IERC20Metadata} from "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";
import {ERC4626BaseStorage} from "@solidstate/contracts/token/ERC4626/base/ERC4626BaseStorage.sol";

import {UnderwriterVaultStorage} from "./UnderwriterVaultStorage.sol";
import {IVaultRegistry} from "../../IVaultRegistry.sol";

contract UnderwriterVaultProxy is Proxy {
    using UnderwriterVaultStorage for UnderwriterVaultStorage.Layout;

    // Constants
    bytes32 public constant VAULT_TYPE = keccak256("UnderwriterVault");
    address internal immutable VAULT_REGISTRY;

    constructor(
        address vaultRegistry,
        address base,
        address quote,
        address oracleAdapter,
        string memory name,
        string memory symbol,
        bool isCall
    ) {
        VAULT_REGISTRY = vaultRegistry;

        ERC20MetadataStorage.Layout storage metadata = ERC20MetadataStorage.layout();
        metadata.name = name;
        metadata.symbol = symbol;
        metadata.decimals = 18;

        ERC4626BaseStorage.layout().asset = isCall ? base : quote;

        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        bytes memory settings = IVaultRegistry(VAULT_REGISTRY).getSettings(VAULT_TYPE);
        l.updateSettings(settings);

        l.isCall = isCall;
        l.base = base;
        l.quote = quote;

        uint8 baseDecimals = IERC20Metadata(base).decimals();
        uint8 quoteDecimals = IERC20Metadata(quote).decimals();
        l.baseDecimals = baseDecimals;
        l.quoteDecimals = quoteDecimals;

        l.lastTradeTimestamp = block.timestamp;
        l.oracleAdapter = oracleAdapter;
    }

    receive() external payable {}

    /// @inheritdoc Proxy
    function _getImplementation() internal view override returns (address) {
        return IVaultRegistry(VAULT_REGISTRY).getImplementation(VAULT_TYPE);
    }

    /// @notice get address of implementation contract
    /// @return implementation address
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {DoublyLinkedList} from "@solidstate/contracts/data/DoublyLinkedList.sol";

import {IVault} from "../../IVault.sol";
import {EnumerableSetUD60x18, EnumerableSet} from "../../../libraries/EnumerableSetUD60x18.sol";
import {OptionMath} from "../../../libraries/OptionMath.sol";

library UnderwriterVaultStorage {
    using UnderwriterVaultStorage for UnderwriterVaultStorage.Layout;
    using DoublyLinkedList for DoublyLinkedList.Uint256List;
    using EnumerableSetUD60x18 for EnumerableSet.Bytes32Set;

    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.UnderwriterVaultStorage");

    struct Layout {
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Vault Specification
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // ERC20 token address for the base asset
        address base;
        // ERC20 token address for the quote asset
        address quote;
        // Base precision
        uint8 baseDecimals;
        // Quote precision
        uint8 quoteDecimals;
        // Address for the oracle adapter to get spot prices for base/quote
        address oracleAdapter;
        // Whether the vault is underwriting calls or puts
        bool isCall;
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Vault Accounting
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // The total assets held in the vault from deposits
        UD60x18 totalAssets;
        // The total assets that have been locked up as collateral for underwritten options.
        UD60x18 totalLockedAssets;
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Trading Parameters
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Minimum days until maturity which can be underwritten by the vault, default 3
        UD60x18 minDTE;
        // Maximum days until maturity which can be underwritten by the vault, default 30
        UD60x18 maxDTE;
        // Minimum option delta which can be underwritten by the vault, default 0.1
        UD60x18 minDelta;
        // Maximum option delta which can be underwritten by the vault, default 0.7
        UD60x18 maxDelta;
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // C-Level Parameters
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        UD60x18 minCLevel; // 1
        UD60x18 maxCLevel; // 1.2
        UD60x18 alphaCLevel; // 3
        UD60x18 hourlyDecayDiscount; // 0.005
        uint256 lastTradeTimestamp;
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Data structures for information on listings
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // The minimum maturity over all unsettled options
        uint256 minMaturity;
        // The maximum maturity over all unsettled options
        uint256 maxMaturity;
        // A SortedDoublyLinkedList for maturities
        DoublyLinkedList.Uint256List maturities;
        // maturity => set of strikes
        mapping(uint256 => EnumerableSet.Bytes32Set) maturityToStrikes;
        // (maturity, strike) => number of short contracts
        mapping(uint256 => mapping(UD60x18 => UD60x18)) positionSizes;
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Dispersing Profit Variables
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Tracks the total profits/spreads that are locked such that we can deduct it from the total assets
        UD60x18 totalLockedSpread;
        // Tracks the rate at which ask spreads are dispersed
        UD60x18 spreadUnlockingRate;
        // Tracks the time spreadUnlockingRate was updated
        uint256 lastSpreadUnlockUpdate;
        // Tracks the unlockingRate for maturities that need to be deducted upon crossing
        // maturity => spreadUnlockingRate
        mapping(uint256 => UD60x18) spreadUnlockingTicks;
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Management/Performance Fee Variables
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        UD60x18 managementFeeRate;
        UD60x18 performanceFeeRate;
        UD60x18 protocolFees;
        uint256 lastManagementFeeTimestamp;
        // Amount of assets about to be deposited in the vault. This is set in `_deposit` before `super._deposit` call, and reset after.
        // We have the following function flow : _deposit -> _mint -> _beforeTokenTransfer -> getUtilisation
        // When `getUtilisation` is called here, we want it to return the new utilisation after the deposit, not the current one.
        // As `_beforeTokenTransfer` know the share amount change, but not the asset amount change, we need to store it here temporarily.
        uint256 pendingAssetsDeposit;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function updateSettings(Layout storage l, bytes memory settings) internal {
        // Handle decoding of settings and updating storage
        if (settings.length == 0) revert IVault.Vault__SettingsUpdateIsEmpty();

        UD60x18[] memory arr = abi.decode(settings, (UD60x18[]));

        l.alphaCLevel = arr[0];
        l.hourlyDecayDiscount = arr[1];
        l.minCLevel = arr[2];
        l.maxCLevel = arr[3];
        l.minDTE = arr[4];
        l.maxDTE = arr[5];
        l.minDelta = arr[6];
        l.maxDelta = arr[7];
        l.performanceFeeRate = arr[8];
        l.managementFeeRate = arr[9];
    }

    function assetDecimals(Layout storage l) internal view returns (uint8) {
        return l.isCall ? l.baseDecimals : l.quoteDecimals;
    }

    function collateral(Layout storage l, UD60x18 size, UD60x18 strike) internal view returns (UD60x18) {
        return l.isCall ? size : size * strike;
    }

    function convertAssetToUD60x18(Layout storage l, uint256 value) internal view returns (UD60x18) {
        return UD60x18.wrap(OptionMath.scaleDecimals(value, l.assetDecimals(), 18));
    }

    function convertAssetFromUD60x18(Layout storage l, UD60x18 value) internal view returns (uint256) {
        return OptionMath.scaleDecimals(value.unwrap(), 18, l.assetDecimals());
    }

    /// @notice Gets the nearest maturity after the given timestamp, exclusive
    ///         of the timestamp being on a maturity
    /// @param timestamp The given timestamp
    /// @return The nearest maturity after the given timestamp
    function getMaturityAfterTimestamp(Layout storage l, uint256 timestamp) internal view returns (uint256) {
        uint256 current = l.minMaturity;

        while (current <= timestamp && current != 0) {
            current = l.maturities.next(current);
        }
        return current;
    }

    /// @notice Gets the number of unexpired listings within the basket of
    ///         options underwritten by this vault at the current time
    /// @param timestamp The given timestamp
    /// @return The number of unexpired listings
    function getNumberOfUnexpiredListings(Layout storage l, uint256 timestamp) internal view returns (uint256) {
        uint256 n = 0;

        if (l.maxMaturity <= timestamp) return 0;

        uint256 current = l.getMaturityAfterTimestamp(timestamp);

        while (current <= l.maxMaturity && current != 0) {
            n += l.maturityToStrikes[current].length();
            current = l.maturities.next(current);
        }

        return n;
    }

    /// @notice Checks if a listing exists within internal data structures
    /// @param strike The strike price of the listing
    /// @param maturity The maturity of the listing
    /// @return If listing exists, return true, false otherwise
    function contains(Layout storage l, UD60x18 strike, uint256 maturity) internal view returns (bool) {
        if (!l.maturities.contains(maturity)) return false;

        return l.maturityToStrikes[maturity].contains(strike);
    }

    /// @notice Adds a listing to the internal data structures
    /// @param strike The strike price of the listing
    /// @param maturity The maturity of the listing
    function addListing(Layout storage l, UD60x18 strike, uint256 maturity) internal {
        // Insert maturity if it doesn't exist
        if (!l.maturities.contains(maturity)) {
            if (maturity < l.minMaturity) {
                l.maturities.insertBefore(l.minMaturity, maturity);
                l.minMaturity = maturity;
            } else if ((l.minMaturity < maturity) && (maturity) < l.maxMaturity) {
                uint256 next = l.getMaturityAfterTimestamp(maturity);
                l.maturities.insertBefore(next, maturity);
            } else {
                l.maturities.insertAfter(l.maxMaturity, maturity);

                if (l.minMaturity == 0) l.minMaturity = maturity;

                l.maxMaturity = maturity;
            }
        }

        // Insert strike into the set of strikes for given maturity
        if (!l.maturityToStrikes[maturity].contains(strike)) l.maturityToStrikes[maturity].add(strike);
    }

    /// @notice Removes a listing from internal data structures
    /// @param strike The strike price of the listing
    /// @param maturity The maturity of the listing
    function removeListing(Layout storage l, UD60x18 strike, uint256 maturity) internal {
        if (l.contains(strike, maturity)) {
            l.maturityToStrikes[maturity].remove(strike);

            // Remove maturity if there are no strikes left
            if (l.maturityToStrikes[maturity].length() == 0) {
                if (maturity == l.minMaturity) l.minMaturity = l.maturities.next(maturity);
                if (maturity == l.maxMaturity) l.maxMaturity = l.maturities.prev(maturity);

                l.maturities.remove(maturity);
            }
        }
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";

import {SolidStateERC4626} from "@solidstate/contracts/token/ERC4626/SolidStateERC4626.sol";

import {ZERO} from "../libraries/Constants.sol";
import {IVaultMining} from "../mining/vaultMining/IVaultMining.sol";
import {IVault} from "./IVault.sol";

abstract contract Vault is IVault, SolidStateERC4626 {
    address internal immutable VAULT_MINING;

    constructor(address vaultMining) {
        VAULT_MINING = vaultMining;
    }

    /// @notice `_beforeTokenTransfer` wrapper, updates VaultMining user state
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (from == to) return;

        uint256 newTotalShares = _totalSupply();
        uint256 newFromShares = _balanceOf(from);
        uint256 newToShares = _balanceOf(to);

        if (from == address(0)) newTotalShares += amount;
        if (to == address(0)) newTotalShares -= amount;

        UD60x18 newUtilisation = getUtilisation();

        if (from != address(0)) {
            newFromShares -= amount;
            IVaultMining(VAULT_MINING).updateUser(
                from,
                address(this),
                ud(newFromShares),
                ud(newTotalShares),
                newUtilisation
            );
        }

        if (to != address(0)) {
            newToShares += amount;
            IVaultMining(VAULT_MINING).updateUser(
                to,
                address(this),
                ud(newToShares),
                ud(newTotalShares),
                newUtilisation
            );
        }
    }

    function getUtilisation() public view virtual returns (UD60x18) {
        return ZERO;
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";
import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";

import {IVault} from "./IVault.sol";
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
    function getSettings(bytes32 vaultType) external view returns (bytes memory) {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();
        return l.settings[vaultType];
    }

    /// @inheritdoc IVaultRegistry
    function updateSettings(bytes32 vaultType, bytes memory updatedSettings) external onlyOwner {
        VaultRegistryStorage.Layout storage l = VaultRegistryStorage.layout();
        l.settings[vaultType] = updatedSettings;

        // Loop through the vaults == vaultType
        for (uint256 i = 0; i < l.vaultsByType[vaultType].length(); i++) {
            IVault(l.vaultsByType[vaultType].at(i)).updateSettings(updatedSettings);
        }
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
        mapping(bytes32 vaultType => bytes) settings;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

/// @notice Wrapper interface for the AggregatorProxy contracts
interface AggregatorProxyInterface is AggregatorV2V3Interface {
    function phaseAggregators(uint16 phaseId) external view returns (address);

    function phaseId() external view returns (uint16);

    function proposedAggregator() external view returns (address);

    function proposedGetRoundData(
        uint80 roundId
    ) external view returns (uint80 id, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function proposedLatestRoundData()
        external
        view
        returns (uint80 id, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function aggregator() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

// Common.sol
//
// Common mathematical functions needed by both SD59x18 and UD60x18. Note that these global functions do not
// always operate with SD59x18 and UD60x18 numbers.

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Thrown when the resultant value in {mulDiv} overflows uint256.
error PRBMath_MulDiv_Overflow(uint256 x, uint256 y, uint256 denominator);

/// @notice Thrown when the resultant value in {mulDiv18} overflows uint256.
error PRBMath_MulDiv18_Overflow(uint256 x, uint256 y);

/// @notice Thrown when one of the inputs passed to {mulDivSigned} is `type(int256).min`.
error PRBMath_MulDivSigned_InputTooSmall();

/// @notice Thrown when the resultant value in {mulDivSigned} overflows int256.
error PRBMath_MulDivSigned_Overflow(int256 x, int256 y);

/*//////////////////////////////////////////////////////////////////////////
                                    CONSTANTS
//////////////////////////////////////////////////////////////////////////*/

/// @dev The maximum value a uint128 number can have.
uint128 constant MAX_UINT128 = type(uint128).max;

/// @dev The maximum value a uint40 number can have.
uint40 constant MAX_UINT40 = type(uint40).max;

/// @dev The unit number, which the decimal precision of the fixed-point types.
uint256 constant UNIT = 1e18;

/// @dev The unit number inverted mod 2^256.
uint256 constant UNIT_INVERSE = 78156646155174841979727994598816262306175212592076161876661_508869554232690281;

/// @dev The the largest power of two that divides the decimal value of `UNIT`. The logarithm of this value is the least significant
/// bit in the binary representation of `UNIT`.
uint256 constant UNIT_LPOTD = 262144;

/*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Calculates the binary exponent of x using the binary fraction method.
/// @dev Has to use 192.64-bit fixed-point numbers. See https://ethereum.stackexchange.com/a/96594/24693.
/// @param x The exponent as an unsigned 192.64-bit fixed-point number.
/// @return result The result as an unsigned 60.18-decimal fixed-point number.
/// @custom:smtchecker abstract-function-nondet
function exp2(uint256 x) pure returns (uint256 result) {
    unchecked {
        // Start from 0.5 in the 192.64-bit fixed-point format.
        result = 0x800000000000000000000000000000000000000000000000;

        // The following logic multiplies the result by $\sqrt{2^{-i}}$ when the bit at position i is 1. Key points:
        //
        // 1. Intermediate results will not overflow, as the starting point is 2^191 and all magic factors are under 2^65.
        // 2. The rationale for organizing the if statements into groups of 8 is gas savings. If the result of performing
        // a bitwise AND operation between x and any value in the array [0x80; 0x40; 0x20; 0x10; 0x08; 0x04; 0x02; 0x01] is 1,
        // we know that `x & 0xFF` is also 1.
        if (x & 0xFF00000000000000 > 0) {
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
        }

        if (x & 0xFF000000000000 > 0) {
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
        }

        if (x & 0xFF0000000000 > 0) {
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
        }

        if (x & 0xFF00000000 > 0) {
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
        }

        if (x & 0xFF000000 > 0) {
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
        }

        if (x & 0xFF0000 > 0) {
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
        }

        if (x & 0xFF00 > 0) {
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
        }

        if (x & 0xFF > 0) {
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
        }

        // In the code snippet below, two operations are executed simultaneously:
        //
        // 1. The result is multiplied by $(2^n + 1)$, where $2^n$ represents the integer part, and the additional 1
        // accounts for the initial guess of 0.5. This is achieved by subtracting from 191 instead of 192.
        // 2. The result is then converted to an unsigned 60.18-decimal fixed-point format.
        //
        // The underlying logic is based on the relationship $2^{191-ip} = 2^{ip} / 2^{191}$, where $ip$ denotes the,
        // integer part, $2^n$.
        result *= UNIT;
        result >>= (191 - (x >> 64));
    }
}

/// @notice Finds the zero-based index of the first 1 in the binary representation of x.
///
/// @dev See the note on "msb" in this Wikipedia article: https://en.wikipedia.org/wiki/Find_first_set
///
/// Each step in this implementation is equivalent to this high-level code:
///
/// ```solidity
/// if (x >= 2 ** 128) {
///     x >>= 128;
///     result += 128;
/// }
/// ```
///
/// Where 128 is replaced with each respective power of two factor. See the full high-level implementation here:
/// https://gist.github.com/PaulRBerg/f932f8693f2733e30c4d479e8e980948
///
/// The Yul instructions used below are:
///
/// - "gt" is "greater than"
/// - "or" is the OR bitwise operator
/// - "shl" is "shift left"
/// - "shr" is "shift right"
///
/// @param x The uint256 number for which to find the index of the most significant bit.
/// @return result The index of the most significant bit as a uint256.
/// @custom:smtchecker abstract-function-nondet
function msb(uint256 x) pure returns (uint256 result) {
    // 2^128
    assembly ("memory-safe") {
        let factor := shl(7, gt(x, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^64
    assembly ("memory-safe") {
        let factor := shl(6, gt(x, 0xFFFFFFFFFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^32
    assembly ("memory-safe") {
        let factor := shl(5, gt(x, 0xFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^16
    assembly ("memory-safe") {
        let factor := shl(4, gt(x, 0xFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^8
    assembly ("memory-safe") {
        let factor := shl(3, gt(x, 0xFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^4
    assembly ("memory-safe") {
        let factor := shl(2, gt(x, 0xF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^2
    assembly ("memory-safe") {
        let factor := shl(1, gt(x, 0x3))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^1
    // No need to shift x any more.
    assembly ("memory-safe") {
        let factor := gt(x, 0x1)
        result := or(result, factor)
    }
}

/// @notice Calculates floor(x*y÷denominator) with 512-bit precision.
///
/// @dev Credits to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
///
/// Notes:
/// - The result is rounded down.
///
/// Requirements:
/// - The denominator must not be zero.
/// - The result must fit in uint256.
///
/// @param x The multiplicand as a uint256.
/// @param y The multiplier as a uint256.
/// @param denominator The divisor as a uint256.
/// @return result The result as a uint256.
/// @custom:smtchecker abstract-function-nondet
function mulDiv(uint256 x, uint256 y, uint256 denominator) pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
    // use the Chinese Remainder Theorem to reconstruct the 512-bit result. The result is stored in two 256
    // variables such that product = prod1 * 2^256 + prod0.
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly ("memory-safe") {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division.
    if (prod1 == 0) {
        unchecked {
            return prod0 / denominator;
        }
    }

    // Make sure the result is less than 2^256. Also prevents denominator == 0.
    if (prod1 >= denominator) {
        revert PRBMath_MulDiv_Overflow(x, y, denominator);
    }

    ////////////////////////////////////////////////////////////////////////////
    // 512 by 256 division
    ////////////////////////////////////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0].
    uint256 remainder;
    assembly ("memory-safe") {
        // Compute remainder using the mulmod Yul instruction.
        remainder := mulmod(x, y, denominator)

        // Subtract 256 bit number from 512-bit number.
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
    }

    unchecked {
        // Calculate the largest power of two divisor of the denominator using the unary operator ~. This operation cannot overflow
        // because the denominator cannot be zero at this point in the function execution. The result is always >= 1.
        // For more detail, see https://cs.stackexchange.com/q/138556/92363.
        uint256 lpotdod = denominator & (~denominator + 1);
        uint256 flippedLpotdod;

        assembly ("memory-safe") {
            // Factor powers of two out of denominator.
            denominator := div(denominator, lpotdod)

            // Divide [prod1 prod0] by lpotdod.
            prod0 := div(prod0, lpotdod)

            // Get the flipped value `2^256 / lpotdod`. If the `lpotdod` is zero, the flipped value is one.
            // `sub(0, lpotdod)` produces the two's complement version of `lpotdod`, which is equivalent to flipping all the bits.
            // However, `div` interprets this value as an unsigned value: https://ethereum.stackexchange.com/q/147168/24693
            flippedLpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
        }

        // Shift in bits from prod1 into prod0.
        prod0 |= prod1 * flippedLpotdod;

        // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
        // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
        // four bits. That is, denominator * inv = 1 mod 2^4.
        uint256 inverse = (3 * denominator) ^ 2;

        // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
        // in modular arithmetic, doubling the correct bits in each step.
        inverse *= 2 - denominator * inverse; // inverse mod 2^8
        inverse *= 2 - denominator * inverse; // inverse mod 2^16
        inverse *= 2 - denominator * inverse; // inverse mod 2^32
        inverse *= 2 - denominator * inverse; // inverse mod 2^64
        inverse *= 2 - denominator * inverse; // inverse mod 2^128
        inverse *= 2 - denominator * inverse; // inverse mod 2^256

        // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
        // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
        // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inverse;
    }
}

/// @notice Calculates floor(x*y÷1e18) with 512-bit precision.
///
/// @dev A variant of {mulDiv} with constant folding, i.e. in which the denominator is hard coded to 1e18.
///
/// Notes:
/// - The body is purposely left uncommented; to understand how this works, see the documentation in {mulDiv}.
/// - The result is rounded down.
/// - We take as an axiom that the result cannot be `MAX_UINT256` when x and y solve the following system of equations:
///
/// $$
/// \begin{cases}
///     x * y = MAX\_UINT256 * UNIT \\
///     (x * y) \% UNIT \geq \frac{UNIT}{2}
/// \end{cases}
/// $$
///
/// Requirements:
/// - Refer to the requirements in {mulDiv}.
/// - The result must fit in uint256.
///
/// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
/// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
/// @return result The result as an unsigned 60.18-decimal fixed-point number.
/// @custom:smtchecker abstract-function-nondet
function mulDiv18(uint256 x, uint256 y) pure returns (uint256 result) {
    uint256 prod0;
    uint256 prod1;
    assembly ("memory-safe") {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    if (prod1 == 0) {
        unchecked {
            return prod0 / UNIT;
        }
    }

    if (prod1 >= UNIT) {
        revert PRBMath_MulDiv18_Overflow(x, y);
    }

    uint256 remainder;
    assembly ("memory-safe") {
        remainder := mulmod(x, y, UNIT)
        result :=
            mul(
                or(
                    div(sub(prod0, remainder), UNIT_LPOTD),
                    mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, UNIT_LPOTD), UNIT_LPOTD), 1))
                ),
                UNIT_INVERSE
            )
    }
}

/// @notice Calculates floor(x*y÷denominator) with 512-bit precision.
///
/// @dev This is an extension of {mulDiv} for signed numbers, which works by computing the signs and the absolute values separately.
///
/// Notes:
/// - Unlike {mulDiv}, the result is rounded toward zero.
///
/// Requirements:
/// - Refer to the requirements in {mulDiv}.
/// - None of the inputs can be `type(int256).min`.
/// - The result must fit in int256.
///
/// @param x The multiplicand as an int256.
/// @param y The multiplier as an int256.
/// @param denominator The divisor as an int256.
/// @return result The result as an int256.
/// @custom:smtchecker abstract-function-nondet
function mulDivSigned(int256 x, int256 y, int256 denominator) pure returns (int256 result) {
    if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
        revert PRBMath_MulDivSigned_InputTooSmall();
    }

    // Get hold of the absolute values of x, y and the denominator.
    uint256 xAbs;
    uint256 yAbs;
    uint256 dAbs;
    unchecked {
        xAbs = x < 0 ? uint256(-x) : uint256(x);
        yAbs = y < 0 ? uint256(-y) : uint256(y);
        dAbs = denominator < 0 ? uint256(-denominator) : uint256(denominator);
    }

    // Compute the absolute value of x*y÷denominator. The result must fit in int256.
    uint256 resultAbs = mulDiv(xAbs, yAbs, dAbs);
    if (resultAbs > uint256(type(int256).max)) {
        revert PRBMath_MulDivSigned_Overflow(x, y);
    }

    // Get the signs of x, y and the denominator.
    uint256 sx;
    uint256 sy;
    uint256 sd;
    assembly ("memory-safe") {
        // This works thanks to two's complement.
        // "sgt" stands for "signed greater than" and "sub(0,1)" is max uint256.
        sx := sgt(x, sub(0, 1))
        sy := sgt(y, sub(0, 1))
        sd := sgt(denominator, sub(0, 1))
    }

    // XOR over sx, sy and sd. What this does is to check whether there are 1 or 3 negative signs in the inputs.
    // If there are, the result should be negative. Otherwise, it should be positive.
    unchecked {
        result = sx ^ sy ^ sd == 0 ? -int256(resultAbs) : int256(resultAbs);
    }
}

/// @notice Calculates the square root of x using the Babylonian method.
///
/// @dev See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
///
/// Notes:
/// - If x is not a perfect square, the result is rounded down.
/// - Credits to OpenZeppelin for the explanations in comments below.
///
/// @param x The uint256 number for which to calculate the square root.
/// @return result The result as a uint256.
/// @custom:smtchecker abstract-function-nondet
function sqrt(uint256 x) pure returns (uint256 result) {
    if (x == 0) {
        return 0;
    }

    // For our first guess, we calculate the biggest power of 2 which is smaller than the square root of x.
    //
    // We know that the "msb" (most significant bit) of x is a power of 2 such that we have:
    //
    // $$
    // msb(x) <= x <= 2*msb(x)$
    // $$
    //
    // We write $msb(x)$ as $2^k$, and we get:
    //
    // $$
    // k = log_2(x)
    // $$
    //
    // Thus, we can write the initial inequality as:
    //
    // $$
    // 2^{log_2(x)} <= x <= 2*2^{log_2(x)+1} \\
    // sqrt(2^k) <= sqrt(x) < sqrt(2^{k+1}) \\
    // 2^{k/2} <= sqrt(x) < 2^{(k+1)/2} <= 2^{(k/2)+1}
    // $$
    //
    // Consequently, $2^{log_2(x) /2} is a good first approximation of sqrt(x) with at least one correct bit.
    uint256 xAux = uint256(x);
    result = 1;
    if (xAux >= 2 ** 128) {
        xAux >>= 128;
        result <<= 64;
    }
    if (xAux >= 2 ** 64) {
        xAux >>= 64;
        result <<= 32;
    }
    if (xAux >= 2 ** 32) {
        xAux >>= 32;
        result <<= 16;
    }
    if (xAux >= 2 ** 16) {
        xAux >>= 16;
        result <<= 8;
    }
    if (xAux >= 2 ** 8) {
        xAux >>= 8;
        result <<= 4;
    }
    if (xAux >= 2 ** 4) {
        xAux >>= 4;
        result <<= 2;
    }
    if (xAux >= 2 ** 2) {
        result <<= 1;
    }

    // At this point, `result` is an estimation with at least one bit of precision. We know the true value has at
    // most 128 bits, since  it is the square root of a uint256. Newton's method converges quadratically (precision
    // doubles at every iteration). We thus need at most 7 iteration to turn our partial result with one bit of
    // precision into the expected uint128 result.
    unchecked {
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;

        // If x is not a perfect square, round down the result.
        uint256 roundedDownResult = x / result;
        if (result >= roundedDownResult) {
            result = roundedDownResult;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "../Common.sol" as Common;
import "./Errors.sol" as CastingErrors;
import { SD59x18 } from "../sd59x18/ValueType.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "../ud60x18/ValueType.sol";
import { SD1x18 } from "./ValueType.sol";

/// @notice Casts an SD1x18 number into SD59x18.
/// @dev There is no overflow check because the domain of SD1x18 is a subset of SD59x18.
function intoSD59x18(SD1x18 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(int256(SD1x18.unwrap(x)));
}

/// @notice Casts an SD1x18 number into UD2x18.
/// - x must be positive.
function intoUD2x18(SD1x18 x) pure returns (UD2x18 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUD2x18_Underflow(x);
    }
    result = UD2x18.wrap(uint64(xInt));
}

/// @notice Casts an SD1x18 number into UD60x18.
/// @dev Requirements:
/// - x must be positive.
function intoUD60x18(SD1x18 x) pure returns (UD60x18 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUD60x18_Underflow(x);
    }
    result = UD60x18.wrap(uint64(xInt));
}

/// @notice Casts an SD1x18 number into uint256.
/// @dev Requirements:
/// - x must be positive.
function intoUint256(SD1x18 x) pure returns (uint256 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUint256_Underflow(x);
    }
    result = uint256(uint64(xInt));
}

/// @notice Casts an SD1x18 number into uint128.
/// @dev Requirements:
/// - x must be positive.
function intoUint128(SD1x18 x) pure returns (uint128 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUint128_Underflow(x);
    }
    result = uint128(uint64(xInt));
}

/// @notice Casts an SD1x18 number into uint40.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(SD1x18 x) pure returns (uint40 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUint40_Underflow(x);
    }
    if (xInt > int64(uint64(Common.MAX_UINT40))) {
        revert CastingErrors.PRBMath_SD1x18_ToUint40_Overflow(x);
    }
    result = uint40(uint64(xInt));
}

/// @notice Alias for {wrap}.
function sd1x18(int64 x) pure returns (SD1x18 result) {
    result = SD1x18.wrap(x);
}

/// @notice Unwraps an SD1x18 number into int64.
function unwrap(SD1x18 x) pure returns (int64 result) {
    result = SD1x18.unwrap(x);
}

/// @notice Wraps an int64 number into SD1x18.
function wrap(int64 x) pure returns (SD1x18 result) {
    result = SD1x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { SD1x18 } from "./ValueType.sol";

/// @dev Euler's number as an SD1x18 number.
SD1x18 constant E = SD1x18.wrap(2_718281828459045235);

/// @dev The maximum value an SD1x18 number can have.
int64 constant uMAX_SD1x18 = 9_223372036854775807;
SD1x18 constant MAX_SD1x18 = SD1x18.wrap(uMAX_SD1x18);

/// @dev The maximum value an SD1x18 number can have.
int64 constant uMIN_SD1x18 = -9_223372036854775808;
SD1x18 constant MIN_SD1x18 = SD1x18.wrap(uMIN_SD1x18);

/// @dev PI as an SD1x18 number.
SD1x18 constant PI = SD1x18.wrap(3_141592653589793238);

/// @dev The unit number, which gives the decimal precision of SD1x18.
SD1x18 constant UNIT = SD1x18.wrap(1e18);
int256 constant uUNIT = 1e18;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { SD1x18 } from "./ValueType.sol";

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in UD2x18.
error PRBMath_SD1x18_ToUD2x18_Underflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in UD60x18.
error PRBMath_SD1x18_ToUD60x18_Underflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in uint128.
error PRBMath_SD1x18_ToUint128_Underflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in uint256.
error PRBMath_SD1x18_ToUint256_Underflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in uint40.
error PRBMath_SD1x18_ToUint40_Overflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in uint40.
error PRBMath_SD1x18_ToUint40_Underflow(SD1x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Casting.sol" as Casting;

/// @notice The signed 1.18-decimal fixed-point number representation, which can have up to 1 digit and up to 18
/// decimals. The values of this are bound by the minimum and the maximum values permitted by the underlying Solidity
/// type int64. This is useful when end users want to use int64 to save gas, e.g. with tight variable packing in contract
/// storage.
type SD1x18 is int64;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using {
    Casting.intoSD59x18,
    Casting.intoUD2x18,
    Casting.intoUD60x18,
    Casting.intoUint256,
    Casting.intoUint128,
    Casting.intoUint40,
    Casting.unwrap
} for SD1x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

/*

██████╗ ██████╗ ██████╗ ███╗   ███╗ █████╗ ████████╗██╗  ██╗
██╔══██╗██╔══██╗██╔══██╗████╗ ████║██╔══██╗╚══██╔══╝██║  ██║
██████╔╝██████╔╝██████╔╝██╔████╔██║███████║   ██║   ███████║
██╔═══╝ ██╔══██╗██╔══██╗██║╚██╔╝██║██╔══██║   ██║   ██╔══██║
██║     ██║  ██║██████╔╝██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║
╚═╝     ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝

███████╗██████╗ ███████╗ █████╗ ██╗  ██╗ ██╗ █████╗
██╔════╝██╔══██╗██╔════╝██╔══██╗╚██╗██╔╝███║██╔══██╗
███████╗██║  ██║███████╗╚██████║ ╚███╔╝ ╚██║╚█████╔╝
╚════██║██║  ██║╚════██║ ╚═══██║ ██╔██╗  ██║██╔══██╗
███████║██████╔╝███████║ █████╔╝██╔╝ ██╗ ██║╚█████╔╝
╚══════╝╚═════╝ ╚══════╝ ╚════╝ ╚═╝  ╚═╝ ╚═╝ ╚════╝

*/

import "./sd59x18/Casting.sol";
import "./sd59x18/Constants.sol";
import "./sd59x18/Conversions.sol";
import "./sd59x18/Errors.sol";
import "./sd59x18/Helpers.sol";
import "./sd59x18/Math.sol";
import "./sd59x18/ValueType.sol";

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Errors.sol" as CastingErrors;
import { MAX_UINT128, MAX_UINT40 } from "../Common.sol";
import { uMAX_SD1x18, uMIN_SD1x18 } from "../sd1x18/Constants.sol";
import { SD1x18 } from "../sd1x18/ValueType.sol";
import { uMAX_UD2x18 } from "../ud2x18/Constants.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "../ud60x18/ValueType.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Casts an SD59x18 number into int256.
/// @dev This is basically a functional alias for {unwrap}.
function intoInt256(SD59x18 x) pure returns (int256 result) {
    result = SD59x18.unwrap(x);
}

/// @notice Casts an SD59x18 number into SD1x18.
/// @dev Requirements:
/// - x must be greater than or equal to `uMIN_SD1x18`.
/// - x must be less than or equal to `uMAX_SD1x18`.
function intoSD1x18(SD59x18 x) pure returns (SD1x18 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < uMIN_SD1x18) {
        revert CastingErrors.PRBMath_SD59x18_IntoSD1x18_Underflow(x);
    }
    if (xInt > uMAX_SD1x18) {
        revert CastingErrors.PRBMath_SD59x18_IntoSD1x18_Overflow(x);
    }
    result = SD1x18.wrap(int64(xInt));
}

/// @notice Casts an SD59x18 number into UD2x18.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `uMAX_UD2x18`.
function intoUD2x18(SD59x18 x) pure returns (UD2x18 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUD2x18_Underflow(x);
    }
    if (xInt > int256(uint256(uMAX_UD2x18))) {
        revert CastingErrors.PRBMath_SD59x18_IntoUD2x18_Overflow(x);
    }
    result = UD2x18.wrap(uint64(uint256(xInt)));
}

/// @notice Casts an SD59x18 number into UD60x18.
/// @dev Requirements:
/// - x must be positive.
function intoUD60x18(SD59x18 x) pure returns (UD60x18 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUD60x18_Underflow(x);
    }
    result = UD60x18.wrap(uint256(xInt));
}

/// @notice Casts an SD59x18 number into uint256.
/// @dev Requirements:
/// - x must be positive.
function intoUint256(SD59x18 x) pure returns (uint256 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint256_Underflow(x);
    }
    result = uint256(xInt);
}

/// @notice Casts an SD59x18 number into uint128.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `uMAX_UINT128`.
function intoUint128(SD59x18 x) pure returns (uint128 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint128_Underflow(x);
    }
    if (xInt > int256(uint256(MAX_UINT128))) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint128_Overflow(x);
    }
    result = uint128(uint256(xInt));
}

/// @notice Casts an SD59x18 number into uint40.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(SD59x18 x) pure returns (uint40 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint40_Underflow(x);
    }
    if (xInt > int256(uint256(MAX_UINT40))) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint40_Overflow(x);
    }
    result = uint40(uint256(xInt));
}

/// @notice Alias for {wrap}.
function sd(int256 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(x);
}

/// @notice Alias for {wrap}.
function sd59x18(int256 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(x);
}

/// @notice Unwraps an SD59x18 number into int256.
function unwrap(SD59x18 x) pure returns (int256 result) {
    result = SD59x18.unwrap(x);
}

/// @notice Wraps an int256 number into SD59x18.
function wrap(int256 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { SD59x18 } from "./ValueType.sol";

// NOTICE: the "u" prefix stands for "unwrapped".

/// @dev Euler's number as an SD59x18 number.
SD59x18 constant E = SD59x18.wrap(2_718281828459045235);

/// @dev The maximum input permitted in {exp}.
int256 constant uEXP_MAX_INPUT = 133_084258667509499440;
SD59x18 constant EXP_MAX_INPUT = SD59x18.wrap(uEXP_MAX_INPUT);

/// @dev The maximum input permitted in {exp2}.
int256 constant uEXP2_MAX_INPUT = 192e18 - 1;
SD59x18 constant EXP2_MAX_INPUT = SD59x18.wrap(uEXP2_MAX_INPUT);

/// @dev Half the UNIT number.
int256 constant uHALF_UNIT = 0.5e18;
SD59x18 constant HALF_UNIT = SD59x18.wrap(uHALF_UNIT);

/// @dev $log_2(10)$ as an SD59x18 number.
int256 constant uLOG2_10 = 3_321928094887362347;
SD59x18 constant LOG2_10 = SD59x18.wrap(uLOG2_10);

/// @dev $log_2(e)$ as an SD59x18 number.
int256 constant uLOG2_E = 1_442695040888963407;
SD59x18 constant LOG2_E = SD59x18.wrap(uLOG2_E);

/// @dev The maximum value an SD59x18 number can have.
int256 constant uMAX_SD59x18 = 57896044618658097711785492504343953926634992332820282019728_792003956564819967;
SD59x18 constant MAX_SD59x18 = SD59x18.wrap(uMAX_SD59x18);

/// @dev The maximum whole value an SD59x18 number can have.
int256 constant uMAX_WHOLE_SD59x18 = 57896044618658097711785492504343953926634992332820282019728_000000000000000000;
SD59x18 constant MAX_WHOLE_SD59x18 = SD59x18.wrap(uMAX_WHOLE_SD59x18);

/// @dev The minimum value an SD59x18 number can have.
int256 constant uMIN_SD59x18 = -57896044618658097711785492504343953926634992332820282019728_792003956564819968;
SD59x18 constant MIN_SD59x18 = SD59x18.wrap(uMIN_SD59x18);

/// @dev The minimum whole value an SD59x18 number can have.
int256 constant uMIN_WHOLE_SD59x18 = -57896044618658097711785492504343953926634992332820282019728_000000000000000000;
SD59x18 constant MIN_WHOLE_SD59x18 = SD59x18.wrap(uMIN_WHOLE_SD59x18);

/// @dev PI as an SD59x18 number.
SD59x18 constant PI = SD59x18.wrap(3_141592653589793238);

/// @dev The unit number, which gives the decimal precision of SD59x18.
int256 constant uUNIT = 1e18;
SD59x18 constant UNIT = SD59x18.wrap(1e18);

/// @dev The unit number squared.
int256 constant uUNIT_SQUARED = 1e36;
SD59x18 constant UNIT_SQUARED = SD59x18.wrap(uUNIT_SQUARED);

/// @dev Zero as an SD59x18 number.
SD59x18 constant ZERO = SD59x18.wrap(0);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { uMAX_SD59x18, uMIN_SD59x18, uUNIT } from "./Constants.sol";
import { PRBMath_SD59x18_Convert_Overflow, PRBMath_SD59x18_Convert_Underflow } from "./Errors.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Converts a simple integer to SD59x18 by multiplying it by `UNIT`.
///
/// @dev Requirements:
/// - x must be greater than or equal to `MIN_SD59x18 / UNIT`.
/// - x must be less than or equal to `MAX_SD59x18 / UNIT`.
///
/// @param x The basic integer to convert.
/// @param result The same number converted to SD59x18.
function convert(int256 x) pure returns (SD59x18 result) {
    if (x < uMIN_SD59x18 / uUNIT) {
        revert PRBMath_SD59x18_Convert_Underflow(x);
    }
    if (x > uMAX_SD59x18 / uUNIT) {
        revert PRBMath_SD59x18_Convert_Overflow(x);
    }
    unchecked {
        result = SD59x18.wrap(x * uUNIT);
    }
}

/// @notice Converts an SD59x18 number to a simple integer by dividing it by `UNIT`.
/// @dev The result is rounded toward zero.
/// @param x The SD59x18 number to convert.
/// @return result The same number as a simple integer.
function convert(SD59x18 x) pure returns (int256 result) {
    result = SD59x18.unwrap(x) / uUNIT;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { SD59x18 } from "./ValueType.sol";

/// @notice Thrown when taking the absolute value of `MIN_SD59x18`.
error PRBMath_SD59x18_Abs_MinSD59x18();

/// @notice Thrown when ceiling a number overflows SD59x18.
error PRBMath_SD59x18_Ceil_Overflow(SD59x18 x);

/// @notice Thrown when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMath_SD59x18_Convert_Overflow(int256 x);

/// @notice Thrown when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMath_SD59x18_Convert_Underflow(int256 x);

/// @notice Thrown when dividing two numbers and one of them is `MIN_SD59x18`.
error PRBMath_SD59x18_Div_InputTooSmall();

/// @notice Thrown when dividing two numbers and one of the intermediary unsigned results overflows SD59x18.
error PRBMath_SD59x18_Div_Overflow(SD59x18 x, SD59x18 y);

/// @notice Thrown when taking the natural exponent of a base greater than 133_084258667509499441.
error PRBMath_SD59x18_Exp_InputTooBig(SD59x18 x);

/// @notice Thrown when taking the binary exponent of a base greater than 192e18.
error PRBMath_SD59x18_Exp2_InputTooBig(SD59x18 x);

/// @notice Thrown when flooring a number underflows SD59x18.
error PRBMath_SD59x18_Floor_Underflow(SD59x18 x);

/// @notice Thrown when taking the geometric mean of two numbers and their product is negative.
error PRBMath_SD59x18_Gm_NegativeProduct(SD59x18 x, SD59x18 y);

/// @notice Thrown when taking the geometric mean of two numbers and multiplying them overflows SD59x18.
error PRBMath_SD59x18_Gm_Overflow(SD59x18 x, SD59x18 y);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in SD1x18.
error PRBMath_SD59x18_IntoSD1x18_Overflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in SD1x18.
error PRBMath_SD59x18_IntoSD1x18_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in UD2x18.
error PRBMath_SD59x18_IntoUD2x18_Overflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in UD2x18.
error PRBMath_SD59x18_IntoUD2x18_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in UD60x18.
error PRBMath_SD59x18_IntoUD60x18_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint128.
error PRBMath_SD59x18_IntoUint128_Overflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint128.
error PRBMath_SD59x18_IntoUint128_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint256.
error PRBMath_SD59x18_IntoUint256_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint40.
error PRBMath_SD59x18_IntoUint40_Overflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint40.
error PRBMath_SD59x18_IntoUint40_Underflow(SD59x18 x);

/// @notice Thrown when taking the logarithm of a number less than or equal to zero.
error PRBMath_SD59x18_Log_InputTooSmall(SD59x18 x);

/// @notice Thrown when multiplying two numbers and one of the inputs is `MIN_SD59x18`.
error PRBMath_SD59x18_Mul_InputTooSmall();

/// @notice Thrown when multiplying two numbers and the intermediary absolute result overflows SD59x18.
error PRBMath_SD59x18_Mul_Overflow(SD59x18 x, SD59x18 y);

/// @notice Thrown when raising a number to a power and hte intermediary absolute result overflows SD59x18.
error PRBMath_SD59x18_Powu_Overflow(SD59x18 x, uint256 y);

/// @notice Thrown when taking the square root of a negative number.
error PRBMath_SD59x18_Sqrt_NegativeInput(SD59x18 x);

/// @notice Thrown when the calculating the square root overflows SD59x18.
error PRBMath_SD59x18_Sqrt_Overflow(SD59x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { wrap } from "./Casting.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Implements the checked addition operation (+) in the SD59x18 type.
function add(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    return wrap(x.unwrap() + y.unwrap());
}

/// @notice Implements the AND (&) bitwise operation in the SD59x18 type.
function and(SD59x18 x, int256 bits) pure returns (SD59x18 result) {
    return wrap(x.unwrap() & bits);
}

/// @notice Implements the AND (&) bitwise operation in the SD59x18 type.
function and2(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    return wrap(x.unwrap() & y.unwrap());
}

/// @notice Implements the equal (=) operation in the SD59x18 type.
function eq(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() == y.unwrap();
}

/// @notice Implements the greater than operation (>) in the SD59x18 type.
function gt(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() > y.unwrap();
}

/// @notice Implements the greater than or equal to operation (>=) in the SD59x18 type.
function gte(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() >= y.unwrap();
}

/// @notice Implements a zero comparison check function in the SD59x18 type.
function isZero(SD59x18 x) pure returns (bool result) {
    result = x.unwrap() == 0;
}

/// @notice Implements the left shift operation (<<) in the SD59x18 type.
function lshift(SD59x18 x, uint256 bits) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() << bits);
}

/// @notice Implements the lower than operation (<) in the SD59x18 type.
function lt(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() < y.unwrap();
}

/// @notice Implements the lower than or equal to operation (<=) in the SD59x18 type.
function lte(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() <= y.unwrap();
}

/// @notice Implements the unchecked modulo operation (%) in the SD59x18 type.
function mod(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() % y.unwrap());
}

/// @notice Implements the not equal operation (!=) in the SD59x18 type.
function neq(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() != y.unwrap();
}

/// @notice Implements the NOT (~) bitwise operation in the SD59x18 type.
function not(SD59x18 x) pure returns (SD59x18 result) {
    result = wrap(~x.unwrap());
}

/// @notice Implements the OR (|) bitwise operation in the SD59x18 type.
function or(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() | y.unwrap());
}

/// @notice Implements the right shift operation (>>) in the SD59x18 type.
function rshift(SD59x18 x, uint256 bits) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() >> bits);
}

/// @notice Implements the checked subtraction operation (-) in the SD59x18 type.
function sub(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() - y.unwrap());
}

/// @notice Implements the checked unary minus operation (-) in the SD59x18 type.
function unary(SD59x18 x) pure returns (SD59x18 result) {
    result = wrap(-x.unwrap());
}

/// @notice Implements the unchecked addition operation (+) in the SD59x18 type.
function uncheckedAdd(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    unchecked {
        result = wrap(x.unwrap() + y.unwrap());
    }
}

/// @notice Implements the unchecked subtraction operation (-) in the SD59x18 type.
function uncheckedSub(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    unchecked {
        result = wrap(x.unwrap() - y.unwrap());
    }
}

/// @notice Implements the unchecked unary minus operation (-) in the SD59x18 type.
function uncheckedUnary(SD59x18 x) pure returns (SD59x18 result) {
    unchecked {
        result = wrap(-x.unwrap());
    }
}

/// @notice Implements the XOR (^) bitwise operation in the SD59x18 type.
function xor(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() ^ y.unwrap());
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "../Common.sol" as Common;
import "./Errors.sol" as Errors;
import {
    uEXP_MAX_INPUT,
    uEXP2_MAX_INPUT,
    uHALF_UNIT,
    uLOG2_10,
    uLOG2_E,
    uMAX_SD59x18,
    uMAX_WHOLE_SD59x18,
    uMIN_SD59x18,
    uMIN_WHOLE_SD59x18,
    UNIT,
    uUNIT,
    uUNIT_SQUARED,
    ZERO
} from "./Constants.sol";
import { wrap } from "./Helpers.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Calculates the absolute value of x.
///
/// @dev Requirements:
/// - x must be greater than `MIN_SD59x18`.
///
/// @param x The SD59x18 number for which to calculate the absolute value.
/// @param result The absolute value of x as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function abs(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt == uMIN_SD59x18) {
        revert Errors.PRBMath_SD59x18_Abs_MinSD59x18();
    }
    result = xInt < 0 ? wrap(-xInt) : x;
}

/// @notice Calculates the arithmetic average of x and y.
///
/// @dev Notes:
/// - The result is rounded toward zero.
///
/// @param x The first operand as an SD59x18 number.
/// @param y The second operand as an SD59x18 number.
/// @return result The arithmetic average as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function avg(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();

    unchecked {
        // This operation is equivalent to `x / 2 +  y / 2`, and it can never overflow.
        int256 sum = (xInt >> 1) + (yInt >> 1);

        if (sum < 0) {
            // If at least one of x and y is odd, add 1 to the result, because shifting negative numbers to the right
            // rounds down to infinity. The right part is equivalent to `sum + (x % 2 == 1 || y % 2 == 1)`.
            assembly ("memory-safe") {
                result := add(sum, and(or(xInt, yInt), 1))
            }
        } else {
            // Add 1 if both x and y are odd to account for the double 0.5 remainder truncated after shifting.
            result = wrap(sum + (xInt & yInt & 1));
        }
    }
}

/// @notice Yields the smallest whole number greater than or equal to x.
///
/// @dev Optimized for fractional value inputs, because every whole value has (1e18 - 1) fractional counterparts.
/// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be less than or equal to `MAX_WHOLE_SD59x18`.
///
/// @param x The SD59x18 number to ceil.
/// @param result The smallest whole number greater than or equal to x, as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function ceil(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt > uMAX_WHOLE_SD59x18) {
        revert Errors.PRBMath_SD59x18_Ceil_Overflow(x);
    }

    int256 remainder = xInt % uUNIT;
    if (remainder == 0) {
        result = x;
    } else {
        unchecked {
            // Solidity uses C fmod style, which returns a modulus with the same sign as x.
            int256 resultInt = xInt - remainder;
            if (xInt > 0) {
                resultInt += uUNIT;
            }
            result = wrap(resultInt);
        }
    }
}

/// @notice Divides two SD59x18 numbers, returning a new SD59x18 number.
///
/// @dev This is an extension of {Common.mulDiv} for signed numbers, which works by computing the signs and the absolute
/// values separately.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
/// - The result is rounded toward zero.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
/// - None of the inputs can be `MIN_SD59x18`.
/// - The denominator must not be zero.
/// - The result must fit in SD59x18.
///
/// @param x The numerator as an SD59x18 number.
/// @param y The denominator as an SD59x18 number.
/// @param result The quotient as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function div(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();
    if (xInt == uMIN_SD59x18 || yInt == uMIN_SD59x18) {
        revert Errors.PRBMath_SD59x18_Div_InputTooSmall();
    }

    // Get hold of the absolute values of x and y.
    uint256 xAbs;
    uint256 yAbs;
    unchecked {
        xAbs = xInt < 0 ? uint256(-xInt) : uint256(xInt);
        yAbs = yInt < 0 ? uint256(-yInt) : uint256(yInt);
    }

    // Compute the absolute value (x*UNIT÷y). The resulting value must fit in SD59x18.
    uint256 resultAbs = Common.mulDiv(xAbs, uint256(uUNIT), yAbs);
    if (resultAbs > uint256(uMAX_SD59x18)) {
        revert Errors.PRBMath_SD59x18_Div_Overflow(x, y);
    }

    // Check if x and y have the same sign using two's complement representation. The left-most bit represents the sign (1 for
    // negative, 0 for positive or zero).
    bool sameSign = (xInt ^ yInt) > -1;

    // If the inputs have the same sign, the result should be positive. Otherwise, it should be negative.
    unchecked {
        result = wrap(sameSign ? int256(resultAbs) : -int256(resultAbs));
    }
}

/// @notice Calculates the natural exponent of x using the following formula:
///
/// $$
/// e^x = 2^{x * log_2{e}}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {exp2}.
///
/// Requirements:
/// - Refer to the requirements in {exp2}.
/// - x must be less than 133_084258667509499441.
///
/// @param x The exponent as an SD59x18 number.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function exp(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();

    // This check prevents values greater than 192 from being passed to {exp2}.
    if (xInt > uEXP_MAX_INPUT) {
        revert Errors.PRBMath_SD59x18_Exp_InputTooBig(x);
    }

    unchecked {
        // Inline the fixed-point multiplication to save gas.
        int256 doubleUnitProduct = xInt * uLOG2_E;
        result = exp2(wrap(doubleUnitProduct / uUNIT));
    }
}

/// @notice Calculates the binary exponent of x using the binary fraction method using the following formula:
///
/// $$
/// 2^{-x} = \frac{1}{2^x}
/// $$
///
/// @dev See https://ethereum.stackexchange.com/q/79903/24693.
///
/// Notes:
/// - If x is less than -59_794705707972522261, the result is zero.
///
/// Requirements:
/// - x must be less than 192e18.
/// - The result must fit in SD59x18.
///
/// @param x The exponent as an SD59x18 number.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function exp2(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt < 0) {
        // The inverse of any number less than this is truncated to zero.
        if (xInt < -59_794705707972522261) {
            return ZERO;
        }

        unchecked {
            // Inline the fixed-point inversion to save gas.
            result = wrap(uUNIT_SQUARED / exp2(wrap(-xInt)).unwrap());
        }
    } else {
        // Numbers greater than or equal to 192e18 don't fit in the 192.64-bit format.
        if (xInt > uEXP2_MAX_INPUT) {
            revert Errors.PRBMath_SD59x18_Exp2_InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x_192x64 = uint256((xInt << 64) / uUNIT);

            // It is safe to cast the result to int256 due to the checks above.
            result = wrap(int256(Common.exp2(x_192x64)));
        }
    }
}

/// @notice Yields the greatest whole number less than or equal to x.
///
/// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional
/// counterparts. See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be greater than or equal to `MIN_WHOLE_SD59x18`.
///
/// @param x The SD59x18 number to floor.
/// @param result The greatest whole number less than or equal to x, as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function floor(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt < uMIN_WHOLE_SD59x18) {
        revert Errors.PRBMath_SD59x18_Floor_Underflow(x);
    }

    int256 remainder = xInt % uUNIT;
    if (remainder == 0) {
        result = x;
    } else {
        unchecked {
            // Solidity uses C fmod style, which returns a modulus with the same sign as x.
            int256 resultInt = xInt - remainder;
            if (xInt < 0) {
                resultInt -= uUNIT;
            }
            result = wrap(resultInt);
        }
    }
}

/// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right.
/// of the radix point for negative numbers.
/// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
/// @param x The SD59x18 number to get the fractional part of.
/// @param result The fractional part of x as an SD59x18 number.
function frac(SD59x18 x) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() % uUNIT);
}

/// @notice Calculates the geometric mean of x and y, i.e. $\sqrt{x * y}$.
///
/// @dev Notes:
/// - The result is rounded toward zero.
///
/// Requirements:
/// - x * y must fit in SD59x18.
/// - x * y must not be negative, since complex numbers are not supported.
///
/// @param x The first operand as an SD59x18 number.
/// @param y The second operand as an SD59x18 number.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function gm(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();
    if (xInt == 0 || yInt == 0) {
        return ZERO;
    }

    unchecked {
        // Equivalent to `xy / x != y`. Checking for overflow this way is faster than letting Solidity do it.
        int256 xyInt = xInt * yInt;
        if (xyInt / xInt != yInt) {
            revert Errors.PRBMath_SD59x18_Gm_Overflow(x, y);
        }

        // The product must not be negative, since complex numbers are not supported.
        if (xyInt < 0) {
            revert Errors.PRBMath_SD59x18_Gm_NegativeProduct(x, y);
        }

        // We don't need to multiply the result by `UNIT` here because the x*y product picked up a factor of `UNIT`
        // during multiplication. See the comments in {Common.sqrt}.
        uint256 resultUint = Common.sqrt(uint256(xyInt));
        result = wrap(int256(resultUint));
    }
}

/// @notice Calculates the inverse of x.
///
/// @dev Notes:
/// - The result is rounded toward zero.
///
/// Requirements:
/// - x must not be zero.
///
/// @param x The SD59x18 number for which to calculate the inverse.
/// @return result The inverse as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function inv(SD59x18 x) pure returns (SD59x18 result) {
    result = wrap(uUNIT_SQUARED / x.unwrap());
}

/// @notice Calculates the natural logarithm of x using the following formula:
///
/// $$
/// ln{x} = log_2{x} / log_2{e}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {log2}.
/// - The precision isn't sufficiently fine-grained to return exactly `UNIT` when the input is `E`.
///
/// Requirements:
/// - Refer to the requirements in {log2}.
///
/// @param x The SD59x18 number for which to calculate the natural logarithm.
/// @return result The natural logarithm as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function ln(SD59x18 x) pure returns (SD59x18 result) {
    // Inline the fixed-point multiplication to save gas. This is overflow-safe because the maximum value that
    // {log2} can return is ~195_205294292027477728.
    result = wrap(log2(x).unwrap() * uUNIT / uLOG2_E);
}

/// @notice Calculates the common logarithm of x using the following formula:
///
/// $$
/// log_{10}{x} = log_2{x} / log_2{10}
/// $$
///
/// However, if x is an exact power of ten, a hard coded value is returned.
///
/// @dev Notes:
/// - Refer to the notes in {log2}.
///
/// Requirements:
/// - Refer to the requirements in {log2}.
///
/// @param x The SD59x18 number for which to calculate the common logarithm.
/// @return result The common logarithm as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function log10(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt < 0) {
        revert Errors.PRBMath_SD59x18_Log_InputTooSmall(x);
    }

    // Note that the `mul` in this block is the standard multiplication operation, not {SD59x18.mul}.
    // prettier-ignore
    assembly ("memory-safe") {
        switch x
        case 1 { result := mul(uUNIT, sub(0, 18)) }
        case 10 { result := mul(uUNIT, sub(1, 18)) }
        case 100 { result := mul(uUNIT, sub(2, 18)) }
        case 1000 { result := mul(uUNIT, sub(3, 18)) }
        case 10000 { result := mul(uUNIT, sub(4, 18)) }
        case 100000 { result := mul(uUNIT, sub(5, 18)) }
        case 1000000 { result := mul(uUNIT, sub(6, 18)) }
        case 10000000 { result := mul(uUNIT, sub(7, 18)) }
        case 100000000 { result := mul(uUNIT, sub(8, 18)) }
        case 1000000000 { result := mul(uUNIT, sub(9, 18)) }
        case 10000000000 { result := mul(uUNIT, sub(10, 18)) }
        case 100000000000 { result := mul(uUNIT, sub(11, 18)) }
        case 1000000000000 { result := mul(uUNIT, sub(12, 18)) }
        case 10000000000000 { result := mul(uUNIT, sub(13, 18)) }
        case 100000000000000 { result := mul(uUNIT, sub(14, 18)) }
        case 1000000000000000 { result := mul(uUNIT, sub(15, 18)) }
        case 10000000000000000 { result := mul(uUNIT, sub(16, 18)) }
        case 100000000000000000 { result := mul(uUNIT, sub(17, 18)) }
        case 1000000000000000000 { result := 0 }
        case 10000000000000000000 { result := uUNIT }
        case 100000000000000000000 { result := mul(uUNIT, 2) }
        case 1000000000000000000000 { result := mul(uUNIT, 3) }
        case 10000000000000000000000 { result := mul(uUNIT, 4) }
        case 100000000000000000000000 { result := mul(uUNIT, 5) }
        case 1000000000000000000000000 { result := mul(uUNIT, 6) }
        case 10000000000000000000000000 { result := mul(uUNIT, 7) }
        case 100000000000000000000000000 { result := mul(uUNIT, 8) }
        case 1000000000000000000000000000 { result := mul(uUNIT, 9) }
        case 10000000000000000000000000000 { result := mul(uUNIT, 10) }
        case 100000000000000000000000000000 { result := mul(uUNIT, 11) }
        case 1000000000000000000000000000000 { result := mul(uUNIT, 12) }
        case 10000000000000000000000000000000 { result := mul(uUNIT, 13) }
        case 100000000000000000000000000000000 { result := mul(uUNIT, 14) }
        case 1000000000000000000000000000000000 { result := mul(uUNIT, 15) }
        case 10000000000000000000000000000000000 { result := mul(uUNIT, 16) }
        case 100000000000000000000000000000000000 { result := mul(uUNIT, 17) }
        case 1000000000000000000000000000000000000 { result := mul(uUNIT, 18) }
        case 10000000000000000000000000000000000000 { result := mul(uUNIT, 19) }
        case 100000000000000000000000000000000000000 { result := mul(uUNIT, 20) }
        case 1000000000000000000000000000000000000000 { result := mul(uUNIT, 21) }
        case 10000000000000000000000000000000000000000 { result := mul(uUNIT, 22) }
        case 100000000000000000000000000000000000000000 { result := mul(uUNIT, 23) }
        case 1000000000000000000000000000000000000000000 { result := mul(uUNIT, 24) }
        case 10000000000000000000000000000000000000000000 { result := mul(uUNIT, 25) }
        case 100000000000000000000000000000000000000000000 { result := mul(uUNIT, 26) }
        case 1000000000000000000000000000000000000000000000 { result := mul(uUNIT, 27) }
        case 10000000000000000000000000000000000000000000000 { result := mul(uUNIT, 28) }
        case 100000000000000000000000000000000000000000000000 { result := mul(uUNIT, 29) }
        case 1000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 30) }
        case 10000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 31) }
        case 100000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 32) }
        case 1000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 33) }
        case 10000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 34) }
        case 100000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 35) }
        case 1000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 36) }
        case 10000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 37) }
        case 100000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 38) }
        case 1000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 39) }
        case 10000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 40) }
        case 100000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 41) }
        case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 42) }
        case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 43) }
        case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 44) }
        case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 45) }
        case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 46) }
        case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 47) }
        case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 48) }
        case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 49) }
        case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 50) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 51) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 52) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 53) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 54) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 55) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 56) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 57) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 58) }
        default { result := uMAX_SD59x18 }
    }

    if (result.unwrap() == uMAX_SD59x18) {
        unchecked {
            // Inline the fixed-point division to save gas.
            result = wrap(log2(x).unwrap() * uUNIT / uLOG2_10);
        }
    }
}

/// @notice Calculates the binary logarithm of x using the iterative approximation algorithm.
///
/// For $0 \leq x \lt 1$, the logarithm is calculated as:
///
/// $$
/// log_2{x} = -log_2{\frac{1}{x}}
/// $$
///
/// @dev See https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation.
///
/// Notes:
/// - Due to the lossy precision of the iterative approximation, the results are not perfectly accurate to the last decimal.
///
/// Requirements:
/// - x must be greater than zero.
///
/// @param x The SD59x18 number for which to calculate the binary logarithm.
/// @return result The binary logarithm as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function log2(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt <= 0) {
        revert Errors.PRBMath_SD59x18_Log_InputTooSmall(x);
    }

    unchecked {
        int256 sign;
        if (xInt >= uUNIT) {
            sign = 1;
        } else {
            sign = -1;
            // Inline the fixed-point inversion to save gas.
            xInt = uUNIT_SQUARED / xInt;
        }

        // Calculate the integer part of the logarithm and add it to the result and finally calculate $y = x * 2^{-n}$.
        uint256 n = Common.msb(uint256(xInt / uUNIT));

        // This is the integer part of the logarithm as an SD59x18 number. The operation can't overflow
        // because n is at most 255, `UNIT` is 1e18, and the sign is either 1 or -1.
        int256 resultInt = int256(n) * uUNIT;

        // This is $y = x * 2^{-n}$.
        int256 y = xInt >> n;

        // If y is the unit number, the fractional part is zero.
        if (y == uUNIT) {
            return wrap(resultInt * sign);
        }

        // Calculate the fractional part via the iterative approximation.
        // The `delta >>= 1` part is equivalent to `delta /= 2`, but shifting bits is more gas efficient.
        int256 DOUBLE_UNIT = 2e18;
        for (int256 delta = uHALF_UNIT; delta > 0; delta >>= 1) {
            y = (y * y) / uUNIT;

            // Is y^2 >= 2e18 and so in the range [2e18, 4e18)?
            if (y >= DOUBLE_UNIT) {
                // Add the 2^{-m} factor to the logarithm.
                resultInt = resultInt + delta;

                // Corresponds to z/2 in the Wikipedia article.
                y >>= 1;
            }
        }
        resultInt *= sign;
        result = wrap(resultInt);
    }
}

/// @notice Multiplies two SD59x18 numbers together, returning a new SD59x18 number.
///
/// @dev Notes:
/// - Refer to the notes in {Common.mulDiv18}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv18}.
/// - None of the inputs can be `MIN_SD59x18`.
/// - The result must fit in SD59x18.
///
/// @param x The multiplicand as an SD59x18 number.
/// @param y The multiplier as an SD59x18 number.
/// @return result The product as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function mul(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();
    if (xInt == uMIN_SD59x18 || yInt == uMIN_SD59x18) {
        revert Errors.PRBMath_SD59x18_Mul_InputTooSmall();
    }

    // Get hold of the absolute values of x and y.
    uint256 xAbs;
    uint256 yAbs;
    unchecked {
        xAbs = xInt < 0 ? uint256(-xInt) : uint256(xInt);
        yAbs = yInt < 0 ? uint256(-yInt) : uint256(yInt);
    }

    // Compute the absolute value (x*y÷UNIT). The resulting value must fit in SD59x18.
    uint256 resultAbs = Common.mulDiv18(xAbs, yAbs);
    if (resultAbs > uint256(uMAX_SD59x18)) {
        revert Errors.PRBMath_SD59x18_Mul_Overflow(x, y);
    }

    // Check if x and y have the same sign using two's complement representation. The left-most bit represents the sign (1 for
    // negative, 0 for positive or zero).
    bool sameSign = (xInt ^ yInt) > -1;

    // If the inputs have the same sign, the result should be positive. Otherwise, it should be negative.
    unchecked {
        result = wrap(sameSign ? int256(resultAbs) : -int256(resultAbs));
    }
}

/// @notice Raises x to the power of y using the following formula:
///
/// $$
/// x^y = 2^{log_2{x} * y}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {exp2}, {log2}, and {mul}.
/// - Returns `UNIT` for 0^0.
///
/// Requirements:
/// - Refer to the requirements in {exp2}, {log2}, and {mul}.
///
/// @param x The base as an SD59x18 number.
/// @param y Exponent to raise x to, as an SD59x18 number
/// @return result x raised to power y, as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function pow(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();

    // If both x and y are zero, the result is `UNIT`. If just x is zero, the result is always zero.
    if (xInt == 0) {
        return yInt == 0 ? UNIT : ZERO;
    }
    // If x is `UNIT`, the result is always `UNIT`.
    else if (xInt == uUNIT) {
        return UNIT;
    }

    // If y is zero, the result is always `UNIT`.
    if (yInt == 0) {
        return UNIT;
    }
    // If y is `UNIT`, the result is always x.
    else if (yInt == uUNIT) {
        return x;
    }

    // Calculate the result using the formula.
    result = exp2(mul(log2(x), y));
}

/// @notice Raises x (an SD59x18 number) to the power y (an unsigned basic integer) using the well-known
/// algorithm "exponentiation by squaring".
///
/// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv18}.
/// - Returns `UNIT` for 0^0.
///
/// Requirements:
/// - Refer to the requirements in {abs} and {Common.mulDiv18}.
/// - The result must fit in SD59x18.
///
/// @param x The base as an SD59x18 number.
/// @param y The exponent as a uint256.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function powu(SD59x18 x, uint256 y) pure returns (SD59x18 result) {
    uint256 xAbs = uint256(abs(x).unwrap());

    // Calculate the first iteration of the loop in advance.
    uint256 resultAbs = y & 1 > 0 ? xAbs : uint256(uUNIT);

    // Equivalent to `for(y /= 2; y > 0; y /= 2)`.
    uint256 yAux = y;
    for (yAux >>= 1; yAux > 0; yAux >>= 1) {
        xAbs = Common.mulDiv18(xAbs, xAbs);

        // Equivalent to `y % 2 == 1`.
        if (yAux & 1 > 0) {
            resultAbs = Common.mulDiv18(resultAbs, xAbs);
        }
    }

    // The result must fit in SD59x18.
    if (resultAbs > uint256(uMAX_SD59x18)) {
        revert Errors.PRBMath_SD59x18_Powu_Overflow(x, y);
    }

    unchecked {
        // Is the base negative and the exponent odd? If yes, the result should be negative.
        int256 resultInt = int256(resultAbs);
        bool isNegative = x.unwrap() < 0 && y & 1 == 1;
        if (isNegative) {
            resultInt = -resultInt;
        }
        result = wrap(resultInt);
    }
}

/// @notice Calculates the square root of x using the Babylonian method.
///
/// @dev See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
///
/// Notes:
/// - Only the positive root is returned.
/// - The result is rounded toward zero.
///
/// Requirements:
/// - x cannot be negative, since complex numbers are not supported.
/// - x must be less than `MAX_SD59x18 / UNIT`.
///
/// @param x The SD59x18 number for which to calculate the square root.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function sqrt(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt < 0) {
        revert Errors.PRBMath_SD59x18_Sqrt_NegativeInput(x);
    }
    if (xInt > uMAX_SD59x18 / uUNIT) {
        revert Errors.PRBMath_SD59x18_Sqrt_Overflow(x);
    }

    unchecked {
        // Multiply x by `UNIT` to account for the factor of `UNIT` picked up when multiplying two SD59x18 numbers.
        // In this case, the two numbers are both the square root.
        uint256 resultUint = Common.sqrt(uint256(xInt * uUNIT));
        result = wrap(int256(resultUint));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Casting.sol" as Casting;
import "./Helpers.sol" as Helpers;
import "./Math.sol" as Math;

/// @notice The signed 59.18-decimal fixed-point number representation, which can have up to 59 digits and up to 18
/// decimals. The values of this are bound by the minimum and the maximum values permitted by the underlying Solidity
/// type int256.
type SD59x18 is int256;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using {
    Casting.intoInt256,
    Casting.intoSD1x18,
    Casting.intoUD2x18,
    Casting.intoUD60x18,
    Casting.intoUint256,
    Casting.intoUint128,
    Casting.intoUint40,
    Casting.unwrap
} for SD59x18 global;

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    Math.abs,
    Math.avg,
    Math.ceil,
    Math.div,
    Math.exp,
    Math.exp2,
    Math.floor,
    Math.frac,
    Math.gm,
    Math.inv,
    Math.log10,
    Math.log2,
    Math.ln,
    Math.mul,
    Math.pow,
    Math.powu,
    Math.sqrt
} for SD59x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    Helpers.add,
    Helpers.and,
    Helpers.eq,
    Helpers.gt,
    Helpers.gte,
    Helpers.isZero,
    Helpers.lshift,
    Helpers.lt,
    Helpers.lte,
    Helpers.mod,
    Helpers.neq,
    Helpers.not,
    Helpers.or,
    Helpers.rshift,
    Helpers.sub,
    Helpers.uncheckedAdd,
    Helpers.uncheckedSub,
    Helpers.uncheckedUnary,
    Helpers.xor
} for SD59x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                    OPERATORS
//////////////////////////////////////////////////////////////////////////*/

// The global "using for" directive makes it possible to use these operators on the SD59x18 type.
using {
    Helpers.add as +,
    Helpers.and2 as &,
    Math.div as /,
    Helpers.eq as ==,
    Helpers.gt as >,
    Helpers.gte as >=,
    Helpers.lt as <,
    Helpers.lte as <=,
    Helpers.mod as %,
    Math.mul as *,
    Helpers.neq as !=,
    Helpers.not as ~,
    Helpers.or as |,
    Helpers.sub as -,
    Helpers.unary as -,
    Helpers.xor as ^
} for SD59x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "../Common.sol" as Common;
import "./Errors.sol" as Errors;
import { uMAX_SD1x18 } from "../sd1x18/Constants.sol";
import { SD1x18 } from "../sd1x18/ValueType.sol";
import { SD59x18 } from "../sd59x18/ValueType.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "../ud60x18/ValueType.sol";
import { UD2x18 } from "./ValueType.sol";

/// @notice Casts a UD2x18 number into SD1x18.
/// - x must be less than or equal to `uMAX_SD1x18`.
function intoSD1x18(UD2x18 x) pure returns (SD1x18 result) {
    uint64 xUint = UD2x18.unwrap(x);
    if (xUint > uint64(uMAX_SD1x18)) {
        revert Errors.PRBMath_UD2x18_IntoSD1x18_Overflow(x);
    }
    result = SD1x18.wrap(int64(xUint));
}

/// @notice Casts a UD2x18 number into SD59x18.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of SD59x18.
function intoSD59x18(UD2x18 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(int256(uint256(UD2x18.unwrap(x))));
}

/// @notice Casts a UD2x18 number into UD60x18.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of UD60x18.
function intoUD60x18(UD2x18 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(UD2x18.unwrap(x));
}

/// @notice Casts a UD2x18 number into uint128.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of uint128.
function intoUint128(UD2x18 x) pure returns (uint128 result) {
    result = uint128(UD2x18.unwrap(x));
}

/// @notice Casts a UD2x18 number into uint256.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of uint256.
function intoUint256(UD2x18 x) pure returns (uint256 result) {
    result = uint256(UD2x18.unwrap(x));
}

/// @notice Casts a UD2x18 number into uint40.
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(UD2x18 x) pure returns (uint40 result) {
    uint64 xUint = UD2x18.unwrap(x);
    if (xUint > uint64(Common.MAX_UINT40)) {
        revert Errors.PRBMath_UD2x18_IntoUint40_Overflow(x);
    }
    result = uint40(xUint);
}

/// @notice Alias for {wrap}.
function ud2x18(uint64 x) pure returns (UD2x18 result) {
    result = UD2x18.wrap(x);
}

/// @notice Unwrap a UD2x18 number into uint64.
function unwrap(UD2x18 x) pure returns (uint64 result) {
    result = UD2x18.unwrap(x);
}

/// @notice Wraps a uint64 number into UD2x18.
function wrap(uint64 x) pure returns (UD2x18 result) {
    result = UD2x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { UD2x18 } from "./ValueType.sol";

/// @dev Euler's number as a UD2x18 number.
UD2x18 constant E = UD2x18.wrap(2_718281828459045235);

/// @dev The maximum value a UD2x18 number can have.
uint64 constant uMAX_UD2x18 = 18_446744073709551615;
UD2x18 constant MAX_UD2x18 = UD2x18.wrap(uMAX_UD2x18);

/// @dev PI as a UD2x18 number.
UD2x18 constant PI = UD2x18.wrap(3_141592653589793238);

/// @dev The unit number, which gives the decimal precision of UD2x18.
uint256 constant uUNIT = 1e18;
UD2x18 constant UNIT = UD2x18.wrap(1e18);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { UD2x18 } from "./ValueType.sol";

/// @notice Thrown when trying to cast a UD2x18 number that doesn't fit in SD1x18.
error PRBMath_UD2x18_IntoSD1x18_Overflow(UD2x18 x);

/// @notice Thrown when trying to cast a UD2x18 number that doesn't fit in uint40.
error PRBMath_UD2x18_IntoUint40_Overflow(UD2x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Casting.sol" as Casting;

/// @notice The unsigned 2.18-decimal fixed-point number representation, which can have up to 2 digits and up to 18
/// decimals. The values of this are bound by the minimum and the maximum values permitted by the underlying Solidity
/// type uint64. This is useful when end users want to use uint64 to save gas, e.g. with tight variable packing in contract
/// storage.
type UD2x18 is uint64;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using {
    Casting.intoSD1x18,
    Casting.intoSD59x18,
    Casting.intoUD60x18,
    Casting.intoUint256,
    Casting.intoUint128,
    Casting.intoUint40,
    Casting.unwrap
} for UD2x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

/*

██████╗ ██████╗ ██████╗ ███╗   ███╗ █████╗ ████████╗██╗  ██╗
██╔══██╗██╔══██╗██╔══██╗████╗ ████║██╔══██╗╚══██╔══╝██║  ██║
██████╔╝██████╔╝██████╔╝██╔████╔██║███████║   ██║   ███████║
██╔═══╝ ██╔══██╗██╔══██╗██║╚██╔╝██║██╔══██║   ██║   ██╔══██║
██║     ██║  ██║██████╔╝██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║
╚═╝     ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝

██╗   ██╗██████╗  ██████╗  ██████╗ ██╗  ██╗ ██╗ █████╗
██║   ██║██╔══██╗██╔════╝ ██╔═████╗╚██╗██╔╝███║██╔══██╗
██║   ██║██║  ██║███████╗ ██║██╔██║ ╚███╔╝ ╚██║╚█████╔╝
██║   ██║██║  ██║██╔═══██╗████╔╝██║ ██╔██╗  ██║██╔══██╗
╚██████╔╝██████╔╝╚██████╔╝╚██████╔╝██╔╝ ██╗ ██║╚█████╔╝
 ╚═════╝ ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═╝ ╚════╝

*/

import "./ud60x18/Casting.sol";
import "./ud60x18/Constants.sol";
import "./ud60x18/Conversions.sol";
import "./ud60x18/Errors.sol";
import "./ud60x18/Helpers.sol";
import "./ud60x18/Math.sol";
import "./ud60x18/ValueType.sol";

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Errors.sol" as CastingErrors;
import { MAX_UINT128, MAX_UINT40 } from "../Common.sol";
import { uMAX_SD1x18 } from "../sd1x18/Constants.sol";
import { SD1x18 } from "../sd1x18/ValueType.sol";
import { uMAX_SD59x18 } from "../sd59x18/Constants.sol";
import { SD59x18 } from "../sd59x18/ValueType.sol";
import { uMAX_UD2x18 } from "../ud2x18/Constants.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "./ValueType.sol";

/// @notice Casts a UD60x18 number into SD1x18.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_SD1x18`.
function intoSD1x18(UD60x18 x) pure returns (SD1x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > uint256(int256(uMAX_SD1x18))) {
        revert CastingErrors.PRBMath_UD60x18_IntoSD1x18_Overflow(x);
    }
    result = SD1x18.wrap(int64(uint64(xUint)));
}

/// @notice Casts a UD60x18 number into UD2x18.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_UD2x18`.
function intoUD2x18(UD60x18 x) pure returns (UD2x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > uMAX_UD2x18) {
        revert CastingErrors.PRBMath_UD60x18_IntoUD2x18_Overflow(x);
    }
    result = UD2x18.wrap(uint64(xUint));
}

/// @notice Casts a UD60x18 number into SD59x18.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_SD59x18`.
function intoSD59x18(UD60x18 x) pure returns (SD59x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > uint256(uMAX_SD59x18)) {
        revert CastingErrors.PRBMath_UD60x18_IntoSD59x18_Overflow(x);
    }
    result = SD59x18.wrap(int256(xUint));
}

/// @notice Casts a UD60x18 number into uint128.
/// @dev This is basically an alias for {unwrap}.
function intoUint256(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x);
}

/// @notice Casts a UD60x18 number into uint128.
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UINT128`.
function intoUint128(UD60x18 x) pure returns (uint128 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > MAX_UINT128) {
        revert CastingErrors.PRBMath_UD60x18_IntoUint128_Overflow(x);
    }
    result = uint128(xUint);
}

/// @notice Casts a UD60x18 number into uint40.
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(UD60x18 x) pure returns (uint40 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > MAX_UINT40) {
        revert CastingErrors.PRBMath_UD60x18_IntoUint40_Overflow(x);
    }
    result = uint40(xUint);
}

/// @notice Alias for {wrap}.
function ud(uint256 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(x);
}

/// @notice Alias for {wrap}.
function ud60x18(uint256 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(x);
}

/// @notice Unwraps a UD60x18 number into uint256.
function unwrap(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x);
}

/// @notice Wraps a uint256 number into the UD60x18 value type.
function wrap(uint256 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { UD60x18 } from "./ValueType.sol";

// NOTICE: the "u" prefix stands for "unwrapped".

/// @dev Euler's number as a UD60x18 number.
UD60x18 constant E = UD60x18.wrap(2_718281828459045235);

/// @dev The maximum input permitted in {exp}.
uint256 constant uEXP_MAX_INPUT = 133_084258667509499440;
UD60x18 constant EXP_MAX_INPUT = UD60x18.wrap(uEXP_MAX_INPUT);

/// @dev The maximum input permitted in {exp2}.
uint256 constant uEXP2_MAX_INPUT = 192e18 - 1;
UD60x18 constant EXP2_MAX_INPUT = UD60x18.wrap(uEXP2_MAX_INPUT);

/// @dev Half the UNIT number.
uint256 constant uHALF_UNIT = 0.5e18;
UD60x18 constant HALF_UNIT = UD60x18.wrap(uHALF_UNIT);

/// @dev $log_2(10)$ as a UD60x18 number.
uint256 constant uLOG2_10 = 3_321928094887362347;
UD60x18 constant LOG2_10 = UD60x18.wrap(uLOG2_10);

/// @dev $log_2(e)$ as a UD60x18 number.
uint256 constant uLOG2_E = 1_442695040888963407;
UD60x18 constant LOG2_E = UD60x18.wrap(uLOG2_E);

/// @dev The maximum value a UD60x18 number can have.
uint256 constant uMAX_UD60x18 = 115792089237316195423570985008687907853269984665640564039457_584007913129639935;
UD60x18 constant MAX_UD60x18 = UD60x18.wrap(uMAX_UD60x18);

/// @dev The maximum whole value a UD60x18 number can have.
uint256 constant uMAX_WHOLE_UD60x18 = 115792089237316195423570985008687907853269984665640564039457_000000000000000000;
UD60x18 constant MAX_WHOLE_UD60x18 = UD60x18.wrap(uMAX_WHOLE_UD60x18);

/// @dev PI as a UD60x18 number.
UD60x18 constant PI = UD60x18.wrap(3_141592653589793238);

/// @dev The unit number, which gives the decimal precision of UD60x18.
uint256 constant uUNIT = 1e18;
UD60x18 constant UNIT = UD60x18.wrap(uUNIT);

/// @dev The unit number squared.
uint256 constant uUNIT_SQUARED = 1e36;
UD60x18 constant UNIT_SQUARED = UD60x18.wrap(uUNIT_SQUARED);

/// @dev Zero as a UD60x18 number.
UD60x18 constant ZERO = UD60x18.wrap(0);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { uMAX_UD60x18, uUNIT } from "./Constants.sol";
import { PRBMath_UD60x18_Convert_Overflow } from "./Errors.sol";
import { UD60x18 } from "./ValueType.sol";

/// @notice Converts a UD60x18 number to a simple integer by dividing it by `UNIT`.
/// @dev The result is rounded down.
/// @param x The UD60x18 number to convert.
/// @return result The same number in basic integer form.
function convert(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x) / uUNIT;
}

/// @notice Converts a simple integer to UD60x18 by multiplying it by `UNIT`.
///
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UD60x18 / UNIT`.
///
/// @param x The basic integer to convert.
/// @param result The same number converted to UD60x18.
function convert(uint256 x) pure returns (UD60x18 result) {
    if (x > uMAX_UD60x18 / uUNIT) {
        revert PRBMath_UD60x18_Convert_Overflow(x);
    }
    unchecked {
        result = UD60x18.wrap(x * uUNIT);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { UD60x18 } from "./ValueType.sol";

/// @notice Thrown when ceiling a number overflows UD60x18.
error PRBMath_UD60x18_Ceil_Overflow(UD60x18 x);

/// @notice Thrown when converting a basic integer to the fixed-point format overflows UD60x18.
error PRBMath_UD60x18_Convert_Overflow(uint256 x);

/// @notice Thrown when taking the natural exponent of a base greater than 133_084258667509499441.
error PRBMath_UD60x18_Exp_InputTooBig(UD60x18 x);

/// @notice Thrown when taking the binary exponent of a base greater than 192e18.
error PRBMath_UD60x18_Exp2_InputTooBig(UD60x18 x);

/// @notice Thrown when taking the geometric mean of two numbers and multiplying them overflows UD60x18.
error PRBMath_UD60x18_Gm_Overflow(UD60x18 x, UD60x18 y);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in SD1x18.
error PRBMath_UD60x18_IntoSD1x18_Overflow(UD60x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in SD59x18.
error PRBMath_UD60x18_IntoSD59x18_Overflow(UD60x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in UD2x18.
error PRBMath_UD60x18_IntoUD2x18_Overflow(UD60x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint128.
error PRBMath_UD60x18_IntoUint128_Overflow(UD60x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint40.
error PRBMath_UD60x18_IntoUint40_Overflow(UD60x18 x);

/// @notice Thrown when taking the logarithm of a number less than 1.
error PRBMath_UD60x18_Log_InputTooSmall(UD60x18 x);

/// @notice Thrown when calculating the square root overflows UD60x18.
error PRBMath_UD60x18_Sqrt_Overflow(UD60x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { wrap } from "./Casting.sol";
import { UD60x18 } from "./ValueType.sol";

/// @notice Implements the checked addition operation (+) in the UD60x18 type.
function add(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() + y.unwrap());
}

/// @notice Implements the AND (&) bitwise operation in the UD60x18 type.
function and(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() & bits);
}

/// @notice Implements the AND (&) bitwise operation in the UD60x18 type.
function and2(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() & y.unwrap());
}

/// @notice Implements the equal operation (==) in the UD60x18 type.
function eq(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() == y.unwrap();
}

/// @notice Implements the greater than operation (>) in the UD60x18 type.
function gt(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() > y.unwrap();
}

/// @notice Implements the greater than or equal to operation (>=) in the UD60x18 type.
function gte(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() >= y.unwrap();
}

/// @notice Implements a zero comparison check function in the UD60x18 type.
function isZero(UD60x18 x) pure returns (bool result) {
    // This wouldn't work if x could be negative.
    result = x.unwrap() == 0;
}

/// @notice Implements the left shift operation (<<) in the UD60x18 type.
function lshift(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() << bits);
}

/// @notice Implements the lower than operation (<) in the UD60x18 type.
function lt(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() < y.unwrap();
}

/// @notice Implements the lower than or equal to operation (<=) in the UD60x18 type.
function lte(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() <= y.unwrap();
}

/// @notice Implements the checked modulo operation (%) in the UD60x18 type.
function mod(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() % y.unwrap());
}

/// @notice Implements the not equal operation (!=) in the UD60x18 type.
function neq(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() != y.unwrap();
}

/// @notice Implements the NOT (~) bitwise operation in the UD60x18 type.
function not(UD60x18 x) pure returns (UD60x18 result) {
    result = wrap(~x.unwrap());
}

/// @notice Implements the OR (|) bitwise operation in the UD60x18 type.
function or(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() | y.unwrap());
}

/// @notice Implements the right shift operation (>>) in the UD60x18 type.
function rshift(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() >> bits);
}

/// @notice Implements the checked subtraction operation (-) in the UD60x18 type.
function sub(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() - y.unwrap());
}

/// @notice Implements the unchecked addition operation (+) in the UD60x18 type.
function uncheckedAdd(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(x.unwrap() + y.unwrap());
    }
}

/// @notice Implements the unchecked subtraction operation (-) in the UD60x18 type.
function uncheckedSub(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(x.unwrap() - y.unwrap());
    }
}

/// @notice Implements the XOR (^) bitwise operation in the UD60x18 type.
function xor(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() ^ y.unwrap());
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "../Common.sol" as Common;
import "./Errors.sol" as Errors;
import { wrap } from "./Casting.sol";
import {
    uEXP_MAX_INPUT,
    uEXP2_MAX_INPUT,
    uHALF_UNIT,
    uLOG2_10,
    uLOG2_E,
    uMAX_UD60x18,
    uMAX_WHOLE_UD60x18,
    UNIT,
    uUNIT,
    uUNIT_SQUARED,
    ZERO
} from "./Constants.sol";
import { UD60x18 } from "./ValueType.sol";

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Calculates the arithmetic average of x and y using the following formula:
///
/// $$
/// avg(x, y) = (x & y) + ((xUint ^ yUint) / 2)
/// $$
//
/// In English, this is what this formula does:
///
/// 1. AND x and y.
/// 2. Calculate half of XOR x and y.
/// 3. Add the two results together.
///
/// This technique is known as SWAR, which stands for "SIMD within a register". You can read more about it here:
/// https://devblogs.microsoft.com/oldnewthing/20220207-00/?p=106223
///
/// @dev Notes:
/// - The result is rounded down.
///
/// @param x The first operand as a UD60x18 number.
/// @param y The second operand as a UD60x18 number.
/// @return result The arithmetic average as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function avg(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    uint256 yUint = y.unwrap();
    unchecked {
        result = wrap((xUint & yUint) + ((xUint ^ yUint) >> 1));
    }
}

/// @notice Yields the smallest whole number greater than or equal to x.
///
/// @dev This is optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional
/// counterparts. See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be less than or equal to `MAX_WHOLE_UD60x18`.
///
/// @param x The UD60x18 number to ceil.
/// @param result The smallest whole number greater than or equal to x, as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function ceil(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    if (xUint > uMAX_WHOLE_UD60x18) {
        revert Errors.PRBMath_UD60x18_Ceil_Overflow(x);
    }

    assembly ("memory-safe") {
        // Equivalent to `x % UNIT`.
        let remainder := mod(x, uUNIT)

        // Equivalent to `UNIT - remainder`.
        let delta := sub(uUNIT, remainder)

        // Equivalent to `x + delta * (remainder > 0 ? 1 : 0)`.
        result := add(x, mul(delta, gt(remainder, 0)))
    }
}

/// @notice Divides two UD60x18 numbers, returning a new UD60x18 number.
///
/// @dev Uses {Common.mulDiv} to enable overflow-safe multiplication and division.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
///
/// @param x The numerator as a UD60x18 number.
/// @param y The denominator as a UD60x18 number.
/// @param result The quotient as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function div(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(Common.mulDiv(x.unwrap(), uUNIT, y.unwrap()));
}

/// @notice Calculates the natural exponent of x using the following formula:
///
/// $$
/// e^x = 2^{x * log_2{e}}
/// $$
///
/// @dev Requirements:
/// - x must be less than 133_084258667509499441.
///
/// @param x The exponent as a UD60x18 number.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function exp(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();

    // This check prevents values greater than 192 from being passed to {exp2}.
    if (xUint > uEXP_MAX_INPUT) {
        revert Errors.PRBMath_UD60x18_Exp_InputTooBig(x);
    }

    unchecked {
        // Inline the fixed-point multiplication to save gas.
        uint256 doubleUnitProduct = xUint * uLOG2_E;
        result = exp2(wrap(doubleUnitProduct / uUNIT));
    }
}

/// @notice Calculates the binary exponent of x using the binary fraction method.
///
/// @dev See https://ethereum.stackexchange.com/q/79903/24693
///
/// Requirements:
/// - x must be less than 192e18.
/// - The result must fit in UD60x18.
///
/// @param x The exponent as a UD60x18 number.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function exp2(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();

    // Numbers greater than or equal to 192e18 don't fit in the 192.64-bit format.
    if (xUint > uEXP2_MAX_INPUT) {
        revert Errors.PRBMath_UD60x18_Exp2_InputTooBig(x);
    }

    // Convert x to the 192.64-bit fixed-point format.
    uint256 x_192x64 = (xUint << 64) / uUNIT;

    // Pass x to the {Common.exp2} function, which uses the 192.64-bit fixed-point number representation.
    result = wrap(Common.exp2(x_192x64));
}

/// @notice Yields the greatest whole number less than or equal to x.
/// @dev Optimized for fractional value inputs, because every whole value has (1e18 - 1) fractional counterparts.
/// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
/// @param x The UD60x18 number to floor.
/// @param result The greatest whole number less than or equal to x, as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function floor(UD60x18 x) pure returns (UD60x18 result) {
    assembly ("memory-safe") {
        // Equivalent to `x % UNIT`.
        let remainder := mod(x, uUNIT)

        // Equivalent to `x - remainder * (remainder > 0 ? 1 : 0)`.
        result := sub(x, mul(remainder, gt(remainder, 0)))
    }
}

/// @notice Yields the excess beyond the floor of x using the odd function definition.
/// @dev See https://en.wikipedia.org/wiki/Fractional_part.
/// @param x The UD60x18 number to get the fractional part of.
/// @param result The fractional part of x as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function frac(UD60x18 x) pure returns (UD60x18 result) {
    assembly ("memory-safe") {
        result := mod(x, uUNIT)
    }
}

/// @notice Calculates the geometric mean of x and y, i.e. $\sqrt{x * y}$, rounding down.
///
/// @dev Requirements:
/// - x * y must fit in UD60x18.
///
/// @param x The first operand as a UD60x18 number.
/// @param y The second operand as a UD60x18 number.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function gm(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    uint256 yUint = y.unwrap();
    if (xUint == 0 || yUint == 0) {
        return ZERO;
    }

    unchecked {
        // Checking for overflow this way is faster than letting Solidity do it.
        uint256 xyUint = xUint * yUint;
        if (xyUint / xUint != yUint) {
            revert Errors.PRBMath_UD60x18_Gm_Overflow(x, y);
        }

        // We don't need to multiply the result by `UNIT` here because the x*y product picked up a factor of `UNIT`
        // during multiplication. See the comments in {Common.sqrt}.
        result = wrap(Common.sqrt(xyUint));
    }
}

/// @notice Calculates the inverse of x.
///
/// @dev Notes:
/// - The result is rounded down.
///
/// Requirements:
/// - x must not be zero.
///
/// @param x The UD60x18 number for which to calculate the inverse.
/// @return result The inverse as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function inv(UD60x18 x) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(uUNIT_SQUARED / x.unwrap());
    }
}

/// @notice Calculates the natural logarithm of x using the following formula:
///
/// $$
/// ln{x} = log_2{x} / log_2{e}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {log2}.
/// - The precision isn't sufficiently fine-grained to return exactly `UNIT` when the input is `E`.
///
/// Requirements:
/// - Refer to the requirements in {log2}.
///
/// @param x The UD60x18 number for which to calculate the natural logarithm.
/// @return result The natural logarithm as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function ln(UD60x18 x) pure returns (UD60x18 result) {
    unchecked {
        // Inline the fixed-point multiplication to save gas. This is overflow-safe because the maximum value that
        // {log2} can return is ~196_205294292027477728.
        result = wrap(log2(x).unwrap() * uUNIT / uLOG2_E);
    }
}

/// @notice Calculates the common logarithm of x using the following formula:
///
/// $$
/// log_{10}{x} = log_2{x} / log_2{10}
/// $$
///
/// However, if x is an exact power of ten, a hard coded value is returned.
///
/// @dev Notes:
/// - Refer to the notes in {log2}.
///
/// Requirements:
/// - Refer to the requirements in {log2}.
///
/// @param x The UD60x18 number for which to calculate the common logarithm.
/// @return result The common logarithm as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function log10(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    if (xUint < uUNIT) {
        revert Errors.PRBMath_UD60x18_Log_InputTooSmall(x);
    }

    // Note that the `mul` in this assembly block is the standard multiplication operation, not {UD60x18.mul}.
    // prettier-ignore
    assembly ("memory-safe") {
        switch x
        case 1 { result := mul(uUNIT, sub(0, 18)) }
        case 10 { result := mul(uUNIT, sub(1, 18)) }
        case 100 { result := mul(uUNIT, sub(2, 18)) }
        case 1000 { result := mul(uUNIT, sub(3, 18)) }
        case 10000 { result := mul(uUNIT, sub(4, 18)) }
        case 100000 { result := mul(uUNIT, sub(5, 18)) }
        case 1000000 { result := mul(uUNIT, sub(6, 18)) }
        case 10000000 { result := mul(uUNIT, sub(7, 18)) }
        case 100000000 { result := mul(uUNIT, sub(8, 18)) }
        case 1000000000 { result := mul(uUNIT, sub(9, 18)) }
        case 10000000000 { result := mul(uUNIT, sub(10, 18)) }
        case 100000000000 { result := mul(uUNIT, sub(11, 18)) }
        case 1000000000000 { result := mul(uUNIT, sub(12, 18)) }
        case 10000000000000 { result := mul(uUNIT, sub(13, 18)) }
        case 100000000000000 { result := mul(uUNIT, sub(14, 18)) }
        case 1000000000000000 { result := mul(uUNIT, sub(15, 18)) }
        case 10000000000000000 { result := mul(uUNIT, sub(16, 18)) }
        case 100000000000000000 { result := mul(uUNIT, sub(17, 18)) }
        case 1000000000000000000 { result := 0 }
        case 10000000000000000000 { result := uUNIT }
        case 100000000000000000000 { result := mul(uUNIT, 2) }
        case 1000000000000000000000 { result := mul(uUNIT, 3) }
        case 10000000000000000000000 { result := mul(uUNIT, 4) }
        case 100000000000000000000000 { result := mul(uUNIT, 5) }
        case 1000000000000000000000000 { result := mul(uUNIT, 6) }
        case 10000000000000000000000000 { result := mul(uUNIT, 7) }
        case 100000000000000000000000000 { result := mul(uUNIT, 8) }
        case 1000000000000000000000000000 { result := mul(uUNIT, 9) }
        case 10000000000000000000000000000 { result := mul(uUNIT, 10) }
        case 100000000000000000000000000000 { result := mul(uUNIT, 11) }
        case 1000000000000000000000000000000 { result := mul(uUNIT, 12) }
        case 10000000000000000000000000000000 { result := mul(uUNIT, 13) }
        case 100000000000000000000000000000000 { result := mul(uUNIT, 14) }
        case 1000000000000000000000000000000000 { result := mul(uUNIT, 15) }
        case 10000000000000000000000000000000000 { result := mul(uUNIT, 16) }
        case 100000000000000000000000000000000000 { result := mul(uUNIT, 17) }
        case 1000000000000000000000000000000000000 { result := mul(uUNIT, 18) }
        case 10000000000000000000000000000000000000 { result := mul(uUNIT, 19) }
        case 100000000000000000000000000000000000000 { result := mul(uUNIT, 20) }
        case 1000000000000000000000000000000000000000 { result := mul(uUNIT, 21) }
        case 10000000000000000000000000000000000000000 { result := mul(uUNIT, 22) }
        case 100000000000000000000000000000000000000000 { result := mul(uUNIT, 23) }
        case 1000000000000000000000000000000000000000000 { result := mul(uUNIT, 24) }
        case 10000000000000000000000000000000000000000000 { result := mul(uUNIT, 25) }
        case 100000000000000000000000000000000000000000000 { result := mul(uUNIT, 26) }
        case 1000000000000000000000000000000000000000000000 { result := mul(uUNIT, 27) }
        case 10000000000000000000000000000000000000000000000 { result := mul(uUNIT, 28) }
        case 100000000000000000000000000000000000000000000000 { result := mul(uUNIT, 29) }
        case 1000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 30) }
        case 10000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 31) }
        case 100000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 32) }
        case 1000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 33) }
        case 10000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 34) }
        case 100000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 35) }
        case 1000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 36) }
        case 10000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 37) }
        case 100000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 38) }
        case 1000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 39) }
        case 10000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 40) }
        case 100000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 41) }
        case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 42) }
        case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 43) }
        case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 44) }
        case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 45) }
        case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 46) }
        case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 47) }
        case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 48) }
        case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 49) }
        case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 50) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 51) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 52) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 53) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 54) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 55) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 56) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 57) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 58) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 59) }
        default { result := uMAX_UD60x18 }
    }

    if (result.unwrap() == uMAX_UD60x18) {
        unchecked {
            // Inline the fixed-point division to save gas.
            result = wrap(log2(x).unwrap() * uUNIT / uLOG2_10);
        }
    }
}

/// @notice Calculates the binary logarithm of x using the iterative approximation algorithm.
///
/// For $0 \leq x < 1$, the logarithm is calculated as:
///
/// $$
/// log_2{x} = -log_2{\frac{1}{x}}
/// $$
///
/// @dev See https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
///
/// Notes:
/// - Due to the lossy precision of the iterative approximation, the results are not perfectly accurate to the last decimal.
///
/// Requirements:
/// - x must be greater than zero.
///
/// @param x The UD60x18 number for which to calculate the binary logarithm.
/// @return result The binary logarithm as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function log2(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();

    if (xUint < uUNIT) {
        revert Errors.PRBMath_UD60x18_Log_InputTooSmall(x);
    }

    unchecked {
        // Calculate the integer part of the logarithm, add it to the result and finally calculate $y = x * 2^{-n}$.
        uint256 n = Common.msb(xUint / uUNIT);

        // This is the integer part of the logarithm as a UD60x18 number. The operation can't overflow because n
        // n is at most 255 and UNIT is 1e18.
        uint256 resultUint = n * uUNIT;

        // This is $y = x * 2^{-n}$.
        uint256 y = xUint >> n;

        // If y is the unit number, the fractional part is zero.
        if (y == uUNIT) {
            return wrap(resultUint);
        }

        // Calculate the fractional part via the iterative approximation.
        // The `delta >>= 1` part is equivalent to `delta /= 2`, but shifting bits is more gas efficient.
        uint256 DOUBLE_UNIT = 2e18;
        for (uint256 delta = uHALF_UNIT; delta > 0; delta >>= 1) {
            y = (y * y) / uUNIT;

            // Is y^2 >= 2e18 and so in the range [2e18, 4e18)?
            if (y >= DOUBLE_UNIT) {
                // Add the 2^{-m} factor to the logarithm.
                resultUint += delta;

                // Corresponds to z/2 in the Wikipedia article.
                y >>= 1;
            }
        }
        result = wrap(resultUint);
    }
}

/// @notice Multiplies two UD60x18 numbers together, returning a new UD60x18 number.
///
/// @dev Uses {Common.mulDiv} to enable overflow-safe multiplication and division.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
///
/// @dev See the documentation in {Common.mulDiv18}.
/// @param x The multiplicand as a UD60x18 number.
/// @param y The multiplier as a UD60x18 number.
/// @return result The product as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function mul(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(Common.mulDiv18(x.unwrap(), y.unwrap()));
}

/// @notice Raises x to the power of y.
///
/// For $1 \leq x \leq \infty$, the following standard formula is used:
///
/// $$
/// x^y = 2^{log_2{x} * y}
/// $$
///
/// For $0 \leq x \lt 1$, since the unsigned {log2} is undefined, an equivalent formula is used:
///
/// $$
/// i = \frac{1}{x}
/// w = 2^{log_2{i} * y}
/// x^y = \frac{1}{w}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {log2} and {mul}.
/// - Returns `UNIT` for 0^0.
/// - It may not perform well with very small values of x. Consider using SD59x18 as an alternative.
///
/// Requirements:
/// - Refer to the requirements in {exp2}, {log2}, and {mul}.
///
/// @param x The base as a UD60x18 number.
/// @param y The exponent as a UD60x18 number.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function pow(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    uint256 yUint = y.unwrap();

    // If both x and y are zero, the result is `UNIT`. If just x is zero, the result is always zero.
    if (xUint == 0) {
        return yUint == 0 ? UNIT : ZERO;
    }
    // If x is `UNIT`, the result is always `UNIT`.
    else if (xUint == uUNIT) {
        return UNIT;
    }

    // If y is zero, the result is always `UNIT`.
    if (yUint == 0) {
        return UNIT;
    }
    // If y is `UNIT`, the result is always x.
    else if (yUint == uUNIT) {
        return x;
    }

    // If x is greater than `UNIT`, use the standard formula.
    if (xUint > uUNIT) {
        result = exp2(mul(log2(x), y));
    }
    // Conversely, if x is less than `UNIT`, use the equivalent formula.
    else {
        UD60x18 i = wrap(uUNIT_SQUARED / xUint);
        UD60x18 w = exp2(mul(log2(i), y));
        result = wrap(uUNIT_SQUARED / w.unwrap());
    }
}

/// @notice Raises x (a UD60x18 number) to the power y (an unsigned basic integer) using the well-known
/// algorithm "exponentiation by squaring".
///
/// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv18}.
/// - Returns `UNIT` for 0^0.
///
/// Requirements:
/// - The result must fit in UD60x18.
///
/// @param x The base as a UD60x18 number.
/// @param y The exponent as a uint256.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function powu(UD60x18 x, uint256 y) pure returns (UD60x18 result) {
    // Calculate the first iteration of the loop in advance.
    uint256 xUint = x.unwrap();
    uint256 resultUint = y & 1 > 0 ? xUint : uUNIT;

    // Equivalent to `for(y /= 2; y > 0; y /= 2)`.
    for (y >>= 1; y > 0; y >>= 1) {
        xUint = Common.mulDiv18(xUint, xUint);

        // Equivalent to `y % 2 == 1`.
        if (y & 1 > 0) {
            resultUint = Common.mulDiv18(resultUint, xUint);
        }
    }
    result = wrap(resultUint);
}

/// @notice Calculates the square root of x using the Babylonian method.
///
/// @dev See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
///
/// Notes:
/// - The result is rounded down.
///
/// Requirements:
/// - x must be less than `MAX_UD60x18 / UNIT`.
///
/// @param x The UD60x18 number for which to calculate the square root.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function sqrt(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();

    unchecked {
        if (xUint > uMAX_UD60x18 / uUNIT) {
            revert Errors.PRBMath_UD60x18_Sqrt_Overflow(x);
        }
        // Multiply x by `UNIT` to account for the factor of `UNIT` picked up when multiplying two UD60x18 numbers.
        // In this case, the two numbers are both the square root.
        result = wrap(Common.sqrt(xUint * uUNIT));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Casting.sol" as Casting;
import "./Helpers.sol" as Helpers;
import "./Math.sol" as Math;

/// @notice The unsigned 60.18-decimal fixed-point number representation, which can have up to 60 digits and up to 18
/// decimals. The values of this are bound by the minimum and the maximum values permitted by the Solidity type uint256.
/// @dev The value type is defined here so it can be imported in all other files.
type UD60x18 is uint256;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using {
    Casting.intoSD1x18,
    Casting.intoUD2x18,
    Casting.intoSD59x18,
    Casting.intoUint128,
    Casting.intoUint256,
    Casting.intoUint40,
    Casting.unwrap
} for UD60x18 global;

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

// The global "using for" directive makes the functions in this library callable on the UD60x18 type.
using {
    Math.avg,
    Math.ceil,
    Math.div,
    Math.exp,
    Math.exp2,
    Math.floor,
    Math.frac,
    Math.gm,
    Math.inv,
    Math.ln,
    Math.log10,
    Math.log2,
    Math.mul,
    Math.pow,
    Math.powu,
    Math.sqrt
} for UD60x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

// The global "using for" directive makes the functions in this library callable on the UD60x18 type.
using {
    Helpers.add,
    Helpers.and,
    Helpers.eq,
    Helpers.gt,
    Helpers.gte,
    Helpers.isZero,
    Helpers.lshift,
    Helpers.lt,
    Helpers.lte,
    Helpers.mod,
    Helpers.neq,
    Helpers.not,
    Helpers.or,
    Helpers.rshift,
    Helpers.sub,
    Helpers.uncheckedAdd,
    Helpers.uncheckedSub,
    Helpers.xor
} for UD60x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                    OPERATORS
//////////////////////////////////////////////////////////////////////////*/

// The global "using for" directive makes it possible to use these operators on the UD60x18 type.
using {
    Helpers.add as +,
    Helpers.and2 as &,
    Math.div as /,
    Helpers.eq as ==,
    Helpers.gt as >,
    Helpers.gte as >=,
    Helpers.lt as <,
    Helpers.lte as <=,
    Helpers.or as |,
    Helpers.mod as %,
    Math.mul as *,
    Helpers.neq as !=,
    Helpers.not as ~,
    Helpers.sub as -,
    Helpers.xor as ^
} for UD60x18 global;