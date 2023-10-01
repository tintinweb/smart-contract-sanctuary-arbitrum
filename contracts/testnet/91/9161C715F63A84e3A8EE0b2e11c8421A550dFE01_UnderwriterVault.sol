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

import {IPoolFactoryEvents} from "./IPoolFactoryEvents.sol";

interface IPoolFactory is IPoolFactoryEvents {
    error PoolFactory__IdenticalAddresses();
    error PoolFactory__InitializationFeeIsZero();
    error PoolFactory__InitializationFeeRequired(uint256 msgValue, uint256 fee);
    error PoolFactory__InvalidInput();
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

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";

interface IVaultMining {
    error VaultMining__NotVault(address caller);
    error VaultMining__InsufficientRewards(address user, UD60x18 rewardsAvailable, UD60x18 rewardsRequested);

    event AllocateRewards(address indexed user, address indexed vault, UD60x18 rewardAmount);
    event Claim(address indexed user, UD60x18 rewardAmount);

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
        UD60x18 __deprecated_reward;
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

    /// @notice Return amount of pending rewards (not yet claimed) for a user.
    ///         This accounts for `l.userRewards[user]` and pending rewards of all given vaults
    function getPendingUserRewards(address user, address[] calldata vaults) external view returns (UD60x18);

    /// @notice Return the total amount of votes across all vaults (Used to calculate share of rewards allocation for each vault)
    function getTotalVotes() external view returns (UD60x18);

    /// @notice Return internal variables for a vault
    function getVaultInfo(address vault) external view returns (VaultInfo memory);

    /// @notice Return internal variables for a user, on a specific vault
    function getUserInfo(address user, address vault) external view returns (UserInfo memory);

    /// @notice Get the amount of rewards emitted per year
    function getRewardsPerYear() external view returns (UD60x18);

    /// @notice Allocate pending rewards for a list of vaults, and claim given amount of rewards.
    /// @param vaults The vaults for which to trigger allocation of pending rewards
    /// @param amount The amount of rewards to claim.
    function claim(address[] calldata vaults, UD60x18 amount) external;

    /// @notice Allocate pending rewards for a list of vaults, and claim max amount of rewards possible.
    function claimAll(address[] calldata vaults) external;

    /// @notice Trigger an update for a user on a specific vault
    /// This needs to be called by the vault, anytime the user's shares change
    /// Can only be called by a vault registered on the VaultRegistry
    /// @param user The user to update
    /// @param newUserShares The new amount of shares for the user
    /// @param newTotalShares The new amount of total shares for the vault
    /// @param utilisationRate The new utilisation rate for the vault
    function updateUser(address user, UD60x18 newUserShares, UD60x18 newTotalShares, UD60x18 utilisationRate) external;

    /// @notice Trigger an update for a vault
    function updateVault(address vault) external;

    /// @notice Trigger an update for all vaults
    function updateVaults() external;

    /// @notice Trigger an update for a user on a specific vault
    function updateUser(address user, address vault) external;
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
    /// @return lower Lower bound of the stranded market price area (Default : PoolStorage.MAX_TICK_PRICE + ONE = 2e18) (18 decimals)
    /// @return upper Upper bound of the stranded market price area (Default : PoolStorage.MAX_TICK_PRICE + ONE = 2e18) (18 decimals)
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
        UD60x18 contractSize,
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
        UD60x18 contractSize,
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

    event TransferPosition(
        address indexed owner,
        address indexed receiver,
        uint256 srcTokenId,
        uint256 destTokenId,
        UD60x18 contractSize
    );

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
    error Pool__CostNotAuthorized(UD60x18 costInWrappedNative, UD60x18 authorizedCostInWrappedNative);
    error Pool__DifferenceOfSizeAndContractDeltaTooLarge(UD60x18 diff, UD60x18 size);
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
        UD60x18 totalMintBurn;
        UD60x18 offset;
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
    /// @param user The address of the user that will call the `fillQuoteOB` function to fill the OB quote
    /// @param quoteOB The OB quote to check
    /// @param size Size to fill from the OB quote (18 decimals)
    /// @param sig secp256k1 Signature
    function isQuoteOBValid(
        address user,
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
pragma solidity ^0.8.19;

import {UD60x18, ud} from "lib/prb-math/src/UD60x18.sol";
import {SD59x18, sd} from "lib/prb-math/src/SD59x18.sol";

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {DoublyLinkedList} from "@solidstate/contracts/data/DoublyLinkedList.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

import {Position} from "../libraries/Position.sol";
import {OptionMath} from "../libraries/OptionMath.sol";
import {UD50x28} from "../libraries/UD50x28.sol";

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
    error Vault__InvalidSettingsUpdate();
    error Vault__InvariantViolated();
    error Vault__MaximumAmountExceeded(UD60x18 maximum, UD60x18 amount);
    error Vault__NotAuthorized();
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

    event PricePerShare(UD60x18 pricePerShare);

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

    event Settle(address indexed pool, UD60x18 contractSize, UD60x18 fee);

    event ManagementFeePaid(address indexed recipient, uint256 managementFee);

    event PerformanceFeePaid(address indexed recipient, uint256 performanceFee);

    event ClaimProtocolFees(address indexed feeReceiver, uint256 feesClaimed);

    event UpdateSettings(bytes settings);

    /// @notice Updates the vault settings
    /// @param settings Encoding of the new settings
    function updateSettings(bytes memory settings) external;

    /// @notice Return vault abi encoded vault settings
    function getSettings() external view returns (bytes memory);

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
import {IOwnable} from "@solidstate/contracts/access/ownable/IOwnable.sol";

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

    /// @inheritdoc IVault
    function getUtilisation() public view override(IVault, Vault) returns (UD60x18) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        UD60x18 totalAssets = l.totalAssets + l.convertAssetToUD60x18(l.pendingAssetsDeposit);
        if (totalAssets == ZERO) return ZERO;

        return l.totalLockedAssets / totalAssets;
    }

    /// @inheritdoc IVault
    function updateSettings(bytes memory settings) external {
        _revertIfNotRegistryOwner(msg.sender);

        // Decode data and update storage variable
        UnderwriterVaultStorage.layout().updateSettings(settings);

        emit UpdateSettings(settings);
    }

    /// @inheritdoc IVault
    function getSettings() external view returns (bytes memory) {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        UD60x18[] memory settings = new UD60x18[](10);

        settings[0] = l.alphaCLevel;
        settings[1] = l.hourlyDecayDiscount;
        settings[2] = l.minCLevel;
        settings[3] = l.maxCLevel;
        settings[4] = l.minDTE;
        settings[5] = l.maxDTE;
        settings[6] = l.minDelta;
        settings[7] = l.maxDelta;
        settings[8] = l.performanceFeeRate;
        settings[9] = l.managementFeeRate;

        return abi.encode(settings);
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
        address caller,
        address receiver,
        uint256 assetAmount,
        uint256 shareAmount,
        uint256 assetAmountOffset,
        uint256 shareAmountOffset
    ) internal virtual override {
        UnderwriterVaultStorage.Layout storage l = UnderwriterVaultStorage.layout();

        l.pendingAssetsDeposit = assetAmount;
        super._deposit(caller, receiver, assetAmount, shareAmount, assetAmountOffset, shareAmountOffset);
        if (l.pendingAssetsDeposit != assetAmount) revert Vault__InvariantViolated(); // Safety check, should never happen
        delete l.pendingAssetsDeposit;

        emit PricePerShare(l.convertAssetToUD60x18(assetAmount) / ud(shareAmount));
    }

    /// @inheritdoc ERC4626BaseInternal
    function _deposit(
        uint256 assetAmount,
        address receiver
    ) internal virtual override nonReentrant returns (uint256 shareAmount) {
        // charge management fees such that the timestamp is up to date
        _chargeManagementFees();
        shareAmount = super._deposit(assetAmount, receiver);
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

        emit PricePerShare(pps);
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

        emit PricePerShare(pps);
    }

    /// @inheritdoc ERC4626BaseInternal
    function _afterDeposit(address receiver, uint256 assetAmount, uint256 shareAmount) internal virtual override {
        _revertIfAddressZero(receiver);
        _revertIfZeroAsset(assetAmount);
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

    function _revertIfNotRegistryOwner(address addr) internal view {
        if (addr != IOwnable(VAULT_REGISTRY).owner()) revert Vault__NotAuthorized();
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
        quote.premium = l.convertAssetToUD60x18(l.convertAssetFromUD60x18(quote.premium)); // Round down to align with token
        quote.spread = (vars.cLevel - ONE) * quote.premium;
        quote.spread = l.convertAssetToUD60x18(l.convertAssetFromUD60x18(quote.spread)); // Round down to align with token
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

            emit Settle(pool, positionSize, ZERO);
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
pragma solidity ^0.8.19;

import {UD60x18} from "lib/prb-math/src/UD60x18.sol";
import {DoublyLinkedList} from "@solidstate/contracts/data/DoublyLinkedList.sol";

import {IVault} from "../../IVault.sol";
import {EnumerableSetUD60x18, EnumerableSet} from "../../../libraries/EnumerableSetUD60x18.sol";
import {OptionMath} from "../../../libraries/OptionMath.sol";
import {ONE} from "contracts/libraries/Constants.sol";

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
        // minCLevel cannot be less than one
        if (arr[2] < ONE) revert IVault.Vault__InvalidSettingsUpdate();

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

    /// @notice Updates VaultMining user state
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
            IVaultMining(VAULT_MINING).updateUser(from, ud(newFromShares), ud(newTotalShares), newUtilisation);
        }

        if (to != address(0)) {
            newToShares += amount;
            IVaultMining(VAULT_MINING).updateUser(to, ud(newToShares), ud(newTotalShares), newUtilisation);
        }
    }

    /// @inheritdoc IVault
    function getUtilisation() public view virtual returns (UD60x18) {
        return ZERO;
    }
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