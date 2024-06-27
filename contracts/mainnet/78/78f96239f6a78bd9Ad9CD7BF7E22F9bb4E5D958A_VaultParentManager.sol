// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStargateReceiver {
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
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

pragma solidity ^0.8.8;

/**
 * @title Map implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableMap {
    error EnumerableMap__IndexOutOfBounds();
    error EnumerableMap__NonExistentKey();

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct AddressToAddressMap {
        Map _inner;
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function at(
        AddressToAddressMap storage map,
        uint256 index
    ) internal view returns (address, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);

        return (
            address(uint160(uint256(key))),
            address(uint160(uint256(value)))
        );
    }

    function at(
        UintToAddressMap storage map,
        uint256 index
    ) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    function contains(
        AddressToAddressMap storage map,
        address key
    ) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    function contains(
        UintToAddressMap storage map,
        uint256 key
    ) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    function length(
        AddressToAddressMap storage map
    ) internal view returns (uint256) {
        return _length(map._inner);
    }

    function length(
        UintToAddressMap storage map
    ) internal view returns (uint256) {
        return _length(map._inner);
    }

    function get(
        AddressToAddressMap storage map,
        address key
    ) internal view returns (address) {
        return
            address(
                uint160(
                    uint256(_get(map._inner, bytes32(uint256(uint160(key)))))
                )
            );
    }

    function get(
        UintToAddressMap storage map,
        uint256 key
    ) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    function set(
        AddressToAddressMap storage map,
        address key,
        address value
    ) internal returns (bool) {
        return
            _set(
                map._inner,
                bytes32(uint256(uint160(key))),
                bytes32(uint256(uint160(value)))
            );
    }

    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    function remove(
        AddressToAddressMap storage map,
        address key
    ) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    function remove(
        UintToAddressMap storage map,
        uint256 key
    ) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    function toArray(
        AddressToAddressMap storage map
    )
        internal
        view
        returns (address[] memory keysOut, address[] memory valuesOut)
    {
        uint256 len = map._inner._entries.length;

        keysOut = new address[](len);
        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._key))
                );
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function toArray(
        UintToAddressMap storage map
    )
        internal
        view
        returns (uint256[] memory keysOut, address[] memory valuesOut)
    {
        uint256 len = map._inner._entries.length;

        keysOut = new uint256[](len);
        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = uint256(map._inner._entries[i]._key);
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function keys(
        AddressToAddressMap storage map
    ) internal view returns (address[] memory keysOut) {
        uint256 len = map._inner._entries.length;

        keysOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._key))
                );
            }
        }
    }

    function keys(
        UintToAddressMap storage map
    ) internal view returns (uint256[] memory keysOut) {
        uint256 len = map._inner._entries.length;

        keysOut = new uint256[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = uint256(map._inner._entries[i]._key);
            }
        }
    }

    function values(
        AddressToAddressMap storage map
    ) internal view returns (address[] memory valuesOut) {
        uint256 len = map._inner._entries.length;

        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function values(
        UintToAddressMap storage map
    ) internal view returns (address[] memory valuesOut) {
        uint256 len = map._inner._entries.length;

        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function _at(
        Map storage map,
        uint256 index
    ) private view returns (bytes32, bytes32) {
        if (index >= map._entries.length)
            revert EnumerableMap__IndexOutOfBounds();

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _contains(
        Map storage map,
        bytes32 key
    ) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) revert EnumerableMap__NonExistentKey();
        unchecked {
            return map._entries[keyIndex - 1]._value;
        }
    }

    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            unchecked {
                map._entries[keyIndex - 1]._value = value;
            }
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            unchecked {
                MapEntry storage last = map._entries[map._entries.length - 1];

                // move last entry to now-vacant index
                map._entries[keyIndex - 1] = last;
                map._indexes[last._key] = keyIndex;
            }

            // clear last index
            map._entries.pop();
            delete map._indexes[key];

            return true;
        } else {
            return false;
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

    modifier nonReentrant() virtual {
        if (_isReentrancyGuardLocked()) revert ReentrancyGuard__ReentrantCall();
        _lockReentrancyGuard();
        _;
        _unlockReentrancyGuard();
    }

    /**
     * @notice returns true if the reentrancy guard is locked, false otherwise
     */
    function _isReentrancyGuardLocked() internal view virtual returns (bool) {
        return
            ReentrancyGuardStorage.layout().status == REENTRANCY_STATUS_LOCKED;
    }

    /**
     * @notice lock functions that use the nonReentrant modifier
     */
    function _lockReentrancyGuard() internal virtual {
        ReentrancyGuardStorage.layout().status = REENTRANCY_STATUS_LOCKED;
    }

    /**
     * @notice unlock functions that use the nonReentrant modifier
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

import { IERC721 } from '../../../interfaces/IERC721.sol';
import { IERC721Base } from './IERC721Base.sol';
import { ERC721BaseInternal } from './ERC721BaseInternal.sol';

/**
 * @title Base ERC721 implementation, excluding optional extensions
 * @dev inheritor must either implement ERC165 supportsInterface or inherit ERC165Base
 */
abstract contract ERC721Base is IERC721Base, ERC721BaseInternal {
    /**
     * @inheritdoc IERC721
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * @inheritdoc IERC721
     */
    function ownerOf(uint256 tokenId) external view returns (address) {
        return _ownerOf(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function getApproved(uint256 tokenId) external view returns (address) {
        return _getApproved(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool) {
        return _isApprovedForAll(account, operator);
    }

    /**
     * @inheritdoc IERC721
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable {
        _transferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable {
        _safeTransferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external payable {
        _safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @inheritdoc IERC721
     */
    function approve(address operator, uint256 tokenId) external payable {
        _approve(operator, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address operator, bool status) external {
        _setApprovalForAll(operator, status);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Receiver } from '../../../interfaces/IERC721Receiver.sol';
import { EnumerableMap } from '../../../data/EnumerableMap.sol';
import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { IERC721BaseInternal } from './IERC721BaseInternal.sol';
import { ERC721BaseStorage } from './ERC721BaseStorage.sol';

/**
 * @title Base ERC721 internal functions
 */
abstract contract ERC721BaseInternal is IERC721BaseInternal {
    using AddressUtils for address;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    function _balanceOf(
        address account
    ) internal view virtual returns (uint256) {
        if (account == address(0)) revert ERC721Base__BalanceQueryZeroAddress();
        return ERC721BaseStorage.layout().holderTokens[account].length();
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        address owner = ERC721BaseStorage.layout().tokenOwners.get(tokenId);
        if (owner == address(0)) revert ERC721Base__InvalidOwner();
        return owner;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return ERC721BaseStorage.layout().tokenOwners.contains(tokenId);
    }

    function _getApproved(
        uint256 tokenId
    ) internal view virtual returns (address) {
        if (!_exists(tokenId)) revert ERC721Base__NonExistentToken();

        return ERC721BaseStorage.layout().tokenApprovals[tokenId];
    }

    function _isApprovedForAll(
        address account,
        address operator
    ) internal view virtual returns (bool) {
        return ERC721BaseStorage.layout().operatorApprovals[account][operator];
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        if (!_exists(tokenId)) revert ERC721Base__NonExistentToken();

        address owner = _ownerOf(tokenId);

        return (spender == owner ||
            _getApproved(tokenId) == spender ||
            _isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert ERC721Base__MintToZeroAddress();
        if (_exists(tokenId)) revert ERC721Base__TokenAlreadyMinted();

        _beforeTokenTransfer(address(0), to, tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, '');
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, data))
            revert ERC721Base__ERC721ReceiverNotImplemented();
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        l.holderTokens[owner].remove(tokenId);
        l.tokenOwners.remove(tokenId);

        l.tokenApprovals[tokenId] = address(0);

        emit Approval(owner, address(0), tokenId);
        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        address owner = _ownerOf(tokenId);

        if (owner != from) revert ERC721Base__NotTokenOwner();
        if (to == address(0)) revert ERC721Base__TransferToZeroAddress();

        _beforeTokenTransfer(from, to, tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        l.holderTokens[from].remove(tokenId);
        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);
        l.tokenApprovals[tokenId] = address(0);

        emit Approval(owner, address(0), tokenId);
        emit Transfer(from, to, tokenId);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        _handleTransferMessageValue(from, to, tokenId, msg.value);
        if (!_isApprovedOrOwner(msg.sender, tokenId))
            revert ERC721Base__NotOwnerOrApproved();
        _transfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data))
            revert ERC721Base__ERC721ReceiverNotImplemented();
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        _safeTransferFrom(from, to, tokenId, '');
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _handleTransferMessageValue(from, to, tokenId, msg.value);
        if (!_isApprovedOrOwner(msg.sender, tokenId))
            revert ERC721Base__NotOwnerOrApproved();
        _safeTransfer(from, to, tokenId, data);
    }

    function _approve(address operator, uint256 tokenId) internal virtual {
        _handleApproveMessageValue(operator, tokenId, msg.value);

        address owner = _ownerOf(tokenId);

        if (operator == owner) revert ERC721Base__SelfApproval();
        if (msg.sender != owner && !_isApprovedForAll(owner, msg.sender))
            revert ERC721Base__NotOwnerOrApproved();

        ERC721BaseStorage.layout().tokenApprovals[tokenId] = operator;
        emit Approval(owner, operator, tokenId);
    }

    function _setApprovalForAll(
        address operator,
        bool status
    ) internal virtual {
        if (operator == msg.sender) revert ERC721Base__SelfApproval();
        ERC721BaseStorage.layout().operatorApprovals[msg.sender][
            operator
        ] = status;
        emit ApprovalForAll(msg.sender, operator, status);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes memory returnData = to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                msg.sender,
                from,
                tokenId,
                data
            ),
            'ERC721: transfer to non ERC721Receiver implementer'
        );

        bytes4 returnValue = abi.decode(returnData, (bytes4));
        return returnValue == type(IERC721Receiver).interfaceId;
    }

    /**
     * @notice ERC721 hook, called before externally called approvals for processing of included message value
     * @param operator beneficiary of approval
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before externally called transfers for processing of included message value
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableMap } from '../../../data/EnumerableMap.sol';
import { EnumerableSet } from '../../../data/EnumerableSet.sol';

library ERC721BaseStorage {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Base');

    struct Layout {
        EnumerableMap.UintToAddressMap tokenOwners;
        mapping(address => EnumerableSet.UintSet) holderTokens;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721 } from '../../../interfaces/IERC721.sol';
import { IERC721BaseInternal } from './IERC721BaseInternal.sol';

/**
 * @title ERC721 base interface
 */
interface IERC721Base is IERC721BaseInternal, IERC721 {

}

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

import { EnumerableMap } from '../../../data/EnumerableMap.sol';
import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';
import { IERC721Enumerable } from './IERC721Enumerable.sol';
import { ERC721EnumerableInternal } from './ERC721EnumerableInternal.sol';

abstract contract ERC721Enumerable is
    IERC721Enumerable,
    ERC721EnumerableInternal
{
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC721Enumerable
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply();
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view returns (uint256) {
        return _tokenOfOwnerByIndex(owner, index);
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        return _tokenByIndex(index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableMap } from '../../../data/EnumerableMap.sol';
import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';

abstract contract ERC721EnumerableInternal {
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @notice TODO
     */
    function _totalSupply() internal view returns (uint256) {
        return ERC721BaseStorage.layout().tokenOwners.length();
    }

    /**
     * @notice TODO
     */
    function _tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) internal view returns (uint256) {
        return ERC721BaseStorage.layout().holderTokens[owner].at(index);
    }

    /**
     * @notice TODO
     */
    function _tokenByIndex(
        uint256 index
    ) internal view returns (uint256 tokenId) {
        (tokenId, ) = ERC721BaseStorage.layout().tokenOwners.at(index);
    }
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

import { IERC721Base } from './base/IERC721Base.sol';
import { IERC721Enumerable } from './enumerable/IERC721Enumerable.sol';
import { IERC721Metadata } from './metadata/IERC721Metadata.sol';

interface ISolidStateERC721 is IERC721Base, IERC721Enumerable, IERC721Metadata {
    error SolidStateERC721__PayableApproveNotSupported();
    error SolidStateERC721__PayableTransferNotSupported();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ERC721MetadataInternal } from './ERC721MetadataInternal.sol';
import { IERC721Metadata } from './IERC721Metadata.sol';

/**
 * @title ERC721 metadata extensions
 */
abstract contract ERC721Metadata is IERC721Metadata, ERC721MetadataInternal {
    /**
     * @notice inheritdoc IERC721Metadata
     */
    function name() external view virtual returns (string memory) {
        return _name();
    }

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function symbol() external view virtual returns (string memory) {
        return _symbol();
    }

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function tokenURI(
        uint256 tokenId
    ) external view virtual returns (string memory) {
        return _tokenURI(tokenId);
    }

    /**
     * @inheritdoc ERC721MetadataInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from '../../../utils/UintUtils.sol';
import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';
import { ERC721BaseInternal } from '../base/ERC721Base.sol';
import { IERC721MetadataInternal } from './IERC721MetadataInternal.sol';
import { ERC721MetadataStorage } from './ERC721MetadataStorage.sol';

/**
 * @title ERC721Metadata internal functions
 */
abstract contract ERC721MetadataInternal is
    IERC721MetadataInternal,
    ERC721BaseInternal
{
    using UintUtils for uint256;

    /**
     * @notice get token name
     * @return token name
     */
    function _name() internal view virtual returns (string memory) {
        return ERC721MetadataStorage.layout().name;
    }

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function _symbol() internal view virtual returns (string memory) {
        return ERC721MetadataStorage.layout().symbol;
    }

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function _tokenURI(
        uint256 tokenId
    ) internal view virtual returns (string memory) {
        if (!_exists(tokenId)) revert ERC721Metadata__NonExistentToken();

        ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();

        string memory tokenIdURI = l.tokenURIs[tokenId];
        string memory baseURI = l.baseURI;

        if (bytes(baseURI).length == 0) {
            return tokenIdURI;
        } else if (bytes(tokenIdURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenIdURI));
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
    }

    /**
     * @notice ERC721 hook: clear per-token URI data on burn
     * @inheritdoc ERC721BaseInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (to == address(0)) {
            delete ERC721MetadataStorage.layout().tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC721MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Metadata');

    struct Layout {
        string name;
        string symbol;
        string baseURI;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
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

import { ERC165Base } from '../../introspection/ERC165/base/ERC165Base.sol';
import { ERC721Base, ERC721BaseInternal } from './base/ERC721Base.sol';
import { ERC721Enumerable } from './enumerable/ERC721Enumerable.sol';
import { ERC721Metadata } from './metadata/ERC721Metadata.sol';
import { ISolidStateERC721 } from './ISolidStateERC721.sol';

/**
 * @title SolidState ERC721 implementation, including recommended extensions
 */
abstract contract SolidStateERC721 is
    ISolidStateERC721,
    ERC721Base,
    ERC721Enumerable,
    ERC721Metadata,
    ERC165Base
{
    /**
     * @notice ERC721 hook: revert if value is included in external approve function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual override {
        if (value > 0) revert SolidStateERC721__PayableApproveNotSupported();
        super._handleApproveMessageValue(operator, tokenId, value);
    }

    /**
     * @notice ERC721 hook: revert if value is included in external transfer function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual override {
        if (value > 0) revert SolidStateERC721__PayableTransferNotSupported();
        super._handleTransferMessageValue(from, to, tokenId, value);
    }

    /**
     * @inheritdoc ERC721BaseInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721BaseInternal, ERC721Metadata) {
        super._beforeTokenTransfer(from, to, tokenId);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';
import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';

import { Registry } from './registry/Registry.sol';
import { RegistryStorage } from './registry/RegistryStorage.sol';
import { VaultBaseExternal } from './vault-base/VaultBaseExternal.sol';
import { IAggregatorV3Interface } from './interfaces/IAggregatorV3Interface.sol';
import { IValioCustomAggregator } from './aggregators/IValioCustomAggregator.sol';
import { IValuer } from './valuers/IValuer.sol';

import { Constants } from './lib/Constants.sol';

/**
 * @title   Accountant
 * @notice  Logic for aggregating the value of assets in a vault
 * @dev     It uses the valuers to get the value of the assets in the vault in USD
 * @dev     Has some external helper functions to check if an asset is supported, deprecated, hard deprecated, etc
 * @dev     For erc20 assets, minValue and maxValue are the same.
 * @dev     For other assets like perps, maxValue is the gross value, minValue is gross - fees (net value)
 */

contract Accountant {
    using AddressUtils for address;

    // The valio registry
    Registry public immutable registry;

    constructor(address _registry) {
        require(_registry != address(0), 'Invalid registry');
        registry = Registry(_registry);
    }

    /**
     * @notice  Get the value of a vault in USD
     * @param   vault  The vault address
     * @return  minValue  The min value of the vault in USD (net)
     * @return  maxValue  The max value of the vault in USD (gross)
     * @return  hasHardDeprecatedAsset  True if the vault has a hard deprecated asset
     */
    function getVaultValue(
        address vault
    )
        external
        view
        returns (uint minValue, uint maxValue, bool hasHardDeprecatedAsset)
    {
        address[] memory activeAssets = VaultBaseExternal(payable(vault))
            .assetsWithBalances();
        for (uint i = 0; i < activeAssets.length; i++) {
            if (_isHardDeprecated(activeAssets[i])) {
                hasHardDeprecatedAsset = true;
            }
            (uint minAssetValue, uint maxAssetValue) = _assetValueOfVault(
                activeAssets[i],
                vault
            );
            minValue += minAssetValue;
            maxValue += maxAssetValue;
        }
    }

    /**
     * @notice  Returns the value of an asset in a vault
     * @param   asset  The asset
     * @param   vault  The valio vault
     * @return  minValue  The net value of the asset in the vault in USD
     * @return  maxValue  The gross value of the asset in the vault in USD
     */
    function assetValueOfVault(
        address asset,
        address vault
    ) external view returns (uint minValue, uint maxValue) {
        return _assetValueOfVault(asset, vault);
    }

    /**
     * @notice  Returns the value of a given amount of an asseet
     * @dev     Only usable for erc20/fungible assets
     * @param   asset  The asset
     * @param   amount  The amount of the asset
     * @return  minValue  The min value of the asset in USD
     * @return  maxValue  The max value of the asset in USD
     */
    function assetValue(
        address asset,
        uint amount
    ) external view returns (uint minValue, uint maxValue) {
        int256 unitPrice = _getUSDPrice(asset);
        address valuer = registry.valuers(asset);
        require(valuer != address(0), 'No valuer');
        return IValuer(valuer).getAssetValue(amount, asset, unitPrice);
    }

    /**
     * @notice  Returns the balance and value of each asset in a vault
     * @dev     The balance is 0 for non fungible assets
     * @param   vault  The valio vault
     * @return  IValuer.AssetValue[]  The breakdown of the assets + value in the vault
     */
    function assetBreakDownOfVault(
        address vault
    ) external view returns (IValuer.AssetValue[] memory) {
        address[] memory activeAssets = VaultBaseExternal(payable(vault))
            .assetsWithBalances();
        IValuer.AssetValue[] memory ava = new IValuer.AssetValue[](
            activeAssets.length
        );
        for (uint i = 0; i < activeAssets.length; i++) {
            // Hard deprecated assets have 0 value, but they can be traded out of
            bool hardDeprecated = registry.hardDeprecatedAssets(
                activeAssets[i]
            );

            int256 unitPrice = hardDeprecated
                ? int256(0)
                : _getUSDPrice(activeAssets[i]);
            address valuer = registry.valuers(activeAssets[i]);
            require(valuer != address(0), 'No valuer');
            ava[i] = IValuer(valuer).getAssetBreakdown(
                vault,
                activeAssets[i],
                unitPrice
            );
        }
        return ava;
    }

    /**
     * @notice  Returns if an asset is active in a vault
     * @param   asset  The asset
     * @param   vault  The valio vault
     * @return  bool  True if the asset is active in the vault (tracked)
     */
    function assetIsActive(
        address asset,
        address vault
    ) external view returns (bool) {
        return _assetIsActive(asset, vault);
    }

    /**
     * @notice  Returns if valio supports the asset
     * @dev     An asset is supported if it has a valuer
     * @dev     The asset could still be hard deprecated
     * @param   asset  The asset
     * @return  bool  True if the asset is supported
     */
    function isSupportedAsset(address asset) external view returns (bool) {
        return registry.valuers(asset) != address(0);
    }

    /**
     * @notice  Returns if an asset is deprecated
     * @dev     An asset is deprecated if we are going to stop supporting it
     * @dev     A deprecated asset can be traded out of, but not into
     * @param   asset  The asset
     * @return  bool  True if the asset is deprecated
     */
    function isDeprecated(address asset) external view returns (bool) {
        return registry.deprecatedAssets(asset);
    }

    /**
     * @notice  Returns if an asset is hard deprecated
     * @dev     A hard asset can no longer be valued, and has 0 value
     * @dev     Vaults with a hard deprecated asset cannot be deposited
     * @param   asset  The asset
     * @return  bool  True if the asset is hard deprecated
     */
    function isHardDeprecated(address asset) external view returns (bool) {
        return _isHardDeprecated(asset);
    }

    /**
     * @notice  Returns the value of an asset in a vault
     * @param   asset  The asset
     * @param   vault  The valio vault
     * @return  minValue  The net value of the asset in the vault in USD
     * @return  maxValue  The gross value of the asset in the vault in USD
     */
    function _assetValueOfVault(
        address asset,
        address vault
    ) internal view returns (uint minValue, uint maxValue) {
        // Hard deprecated assets have 0 value, but they can be traded out of
        if (registry.hardDeprecatedAssets(asset)) {
            return (0, 0);
        }
        int256 unitPrice = _getUSDPrice(asset);
        address valuer = registry.valuers(asset);
        require(valuer != address(0), 'No valuer');
        return IValuer(valuer).getVaultValue(vault, asset, unitPrice);
    }

    /**
     * @notice  Returns if an asset is active in a vault
     * @param   asset  The asset
     * @param   vault  The valio vault
     * @return  bool  True if the asset is active in the vault (tracked)
     */
    function _assetIsActive(
        address asset,
        address vault
    ) internal view returns (bool) {
        address valuer = registry.valuers(asset);
        require(valuer != address(0), 'No valuer');
        return IValuer(valuer).getAssetActive(vault, asset);
    }

    /**
     * @notice  Returns if an asset is hard deprecated
     * @dev     A hard asset can no longer be valued, and has 0 value
     * @dev     Vaults with a hard deprecated asset cannot be deposited
     * @param   asset  The asset
     * @return  bool  True if the asset is hard deprecated
     */
    function _isHardDeprecated(address asset) internal view returns (bool) {
        return registry.hardDeprecatedAssets(asset);
    }

    /**
     * @notice  Returns the price of a single unit of the given asset in USD
     * @dev     The price is @ VAULT_PRECISION
     * @param   asset  The asset
     * @return  price  The price of a single unit of the asset in USD
     */
    function _getUSDPrice(address asset) internal view returns (int256 price) {
        uint256 updatedAt;

        RegistryStorage.AggregatorType aggregatorType = registry
            .assetAggregatorType(asset);
        if (aggregatorType == RegistryStorage.AggregatorType.None) {
            return 0;
        } else if (
            aggregatorType == RegistryStorage.AggregatorType.ChainlinkV3USD
        ) {
            IAggregatorV3Interface chainlinkAggregator = registry
                .chainlinkV3USDAggregators(asset);
            require(
                address(chainlinkAggregator) != address(0),
                'No cl aggregator'
            );
            (, price, , updatedAt, ) = chainlinkAggregator.latestRoundData();
        } else {
            IValioCustomAggregator valioAggregator = registry
                .valioCustomUSDAggregators(aggregatorType);

            require(address(valioAggregator) != address(0), 'No vl aggregator');
            (price, updatedAt) = valioAggregator.latestRoundData(asset);
        }

        require(
            updatedAt + registry.chainlinkTimeout() >= block.timestamp,
            'Price expired'
        );

        require(price > 0, 'Price not available');

        price = (price * int(Constants.VAULT_PRECISION)) / 10 ** 8;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title   IValioCustomAggregator
 * @notice  Interface for custom price aggregators
 * @dev     It takes the asset we are trying to value and returns the price of that asset
 * @dev     A custom aggregator can be shared between multiple assets, unline a chainlink aggregator
 */

interface IValioCustomAggregator {
    function description() external view returns (string memory);

    function decimals() external view returns (uint8);

    function latestRoundData(
        address asset
    ) external view returns (int256 answer, uint256 updatedAt);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import { CPITStorage } from './CPITStorage.sol';
import { Constants } from '../lib/Constants.sol';

/**
 * @title   CPIT (Cumulative Price Impact Threshold) contract
 * @notice  The CPIT contract is used to calculate, store and check the cumulative price impact of trades.
 * @notice  The impact is calculated against the total AUM of a vault.
 * @notice  The priceImpact is the change in the value of the AUM
 * @dev     The allowed max24HourCPITBips is based on the RiskProfile of the vault
 * @dev     We store the priceImpact for each 6 hour window and
 * @dev     calculate the cumulative price impact for the last 24 hours
 */
contract CPIT {
    uint256 private constant WINDOW_SIZE = 6 hours; // window size for rolling 24 hours

    /**
     * @notice  Update the cumulative price impact threshold (CPIT) for a trade
     * @dev     Will revert if the 24 hour cumulative price impact threshold is exceeded
     * @dev     This will rollback the trade tx
     * @param   preTransactionValue  The AUM of the vault pre trade
     * @param   postTransactionValue  The AUM of the vault post trade
     * @param   max24HourCPITBips  The max 24 hour cumulative price impact threshold in BIPs
     * @return  priceImpactBips  The price impact of the trade in BIPs (not currently used)
     */
    function _updatePriceImpact(
        uint preTransactionValue,
        uint postTransactionValue,
        uint max24HourCPITBips
    ) internal returns (uint priceImpactBips) {
        CPITStorage.Layout storage l = CPITStorage.layout();
        // calculate price impact in BIPs
        priceImpactBips = _calculatePriceImpact(
            preTransactionValue,
            postTransactionValue
        );

        if (priceImpactBips == 0) {
            return priceImpactBips;
        }

        uint currentWindow = _getCurrentWindow();

        // update priceImpact for current window
        l.deviation[currentWindow] += priceImpactBips;

        uint cumulativePriceImpact = _calculateCumulativePriceImpact(
            currentWindow
        );

        // check if 24 hour cumulative price impact threshold is exceeded
        if (cumulativePriceImpact > max24HourCPITBips) {
            revert('CPIT: price impact exceeded');
        }
    }

    /**
     * @notice  Returns the accumulated price impact for the last 24 hours
     * @dev     The price impact is fetched for each 6 hour window and summed to get the cumulative price impact
     * @return  uint256  .
     */
    function _getCurrentCpit() internal view returns (uint256) {
        return _calculateCumulativePriceImpact(_getCurrentWindow());
    }

    /**
     * @notice  Returns the current 24 hour window
     * @return  currentWindow  The current 24 hour window
     */
    function _getCurrentWindow() internal view returns (uint256 currentWindow) {
        currentWindow = block.timestamp / WINDOW_SIZE;
    }

    // calculate the 24 hour cumulative price impact
    /**
     * @notice  Calculate the cumulative price impact for the last 24 hours
     * @dev     The price impact is fetched for each 6 hour window and summed to get the cumulative price impact
     * @param   currentWindow  The current 24 hour window
     * @return  cumulativePriceImpact  The cumulative price impact for the last 24 hours
     */
    function _calculateCumulativePriceImpact(
        uint currentWindow
    ) internal view returns (uint cumulativePriceImpact) {
        CPITStorage.Layout storage l = CPITStorage.layout();
        uint windowsInDay = 24 hours / WINDOW_SIZE;
        uint startWindow = currentWindow - (windowsInDay - 1);
        for (uint256 i = startWindow; i <= currentWindow; i++) {
            cumulativePriceImpact += l.deviation[i];
        }
    }

    /**
     * @notice  Calculate the price impact of a trade in BIPS
     * @param   oldValue  The previous AUM
     * @param   newValue  The new AUM
     * @return  priceImpactBips  The price impact of the trade in BIPs
     */
    function _calculatePriceImpact(
        uint oldValue,
        uint newValue
    ) internal pure returns (uint priceImpactBips) {
        if (newValue >= oldValue) {
            return 0;
        }
        // Calculate the deviation between the old and new values
        uint deviation = oldValue - newValue;
        // Calculate the impact on price in basis points (BIPs)
        priceImpactBips = ((deviation * Constants.BASIS_POINTS_DIVISOR) /
            oldValue);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library CPITStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256('valio.storage.CPIT');

    // solhint-disable-next-line ordering
    struct Layout {
        uint256 DEPRECATED_lockedUntil; // timestamp of when vault is locked until
        mapping(uint256 => uint) deviation; // deviation for each window
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IExecutorEvents, ExecutorIntegration } from './IExecutorEvents.sol';

interface IExecutor is IExecutorEvents {
    error NotImplemented();

    /**
     * @notice  Some integrations may need some logic executed to tidy up valio storage
     *          if/when a an action happens on an external protocol
     * @dev     For instance GMX positions are Liquidated with out a callback, we need
     *          to clear these positions from valio storage
     * @dev     This function must be payable because it is delegate called in a payable context
     */
    function clean() external payable;

    function requiresCPIT() external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

enum ExecutorIntegration {
    ZeroX,
    GMX,
    SnxPerpsV2,
    GMXOrderBook
}

// These are all in the one interface to make it easier to track all the events
interface IExecutorEvents {
    // 0x
    event ZeroXSwap(
        address indexed sellTokenAddress,
        uint sellAmount,
        address indexed buyTokenAddress,
        uint buyAmount,
        uint amountReceived,
        uint unitPrice
    );

    // Gmx V1
    event GmxV1CreateIncreasePosition(
        bool isLong,
        address indexToken,
        address collateralToken,
        uint sizeDelta,
        uint collateralAmount,
        uint acceptablePrice
    );

    event GmxV1CreateDecreasePosition(
        bool isLong,
        address indexToken,
        address collateralToken,
        uint sizeDelta,
        uint collateralDelta,
        uint acceptablePrice
    );

    event GmxV1Callback(
        bool isIncrease,
        bool isLong,
        address indexToken,
        address collateralToken,
        bool wasExecuted,
        uint executionPrice
    );

    event GmxV1CreateDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    );

    event GmxV1UpdateDecreaseOrder(
        uint256 _orderIndex,
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    );

    event GmxV1CancelDecreaseOrder(
        uint256 _orderIndex,
        address _indexToken,
        address _collateralToken,
        bool _isLong
    );

    // Perps V2
    event PerpsV2ExecutedManagerActionDeposit(
        address wrapper,
        address perpMarket,
        address inputToken,
        uint inputTokenAmount
    );

    event PerpsV2ExecutedManagerActionWithdraw(
        address wrapper,
        address perpMarket,
        address outputToken,
        uint outputTokenAmount
    );

    event PerpsV2ExecutedManagerActionSubmitOrder(
        address wrapper,
        address perpMarket,
        int sizeDelta,
        uint desiredFillPrice
    );

    event PerpsV2ExecutedManagerActionSubmitCloseOrder(
        address wrapper,
        address perpMarket,
        uint desiredFillPrice
    );

    event PerpsV2ExecutedManagerActionSubmitCancelOrder(
        address wrapper,
        address perpMarket
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IGmxRouter } from './interfaces/IGmxRouter.sol';
import { IGmxVault } from './interfaces/IGmxVault.sol';
import { IGmxOrderBook } from './interfaces/IGmxOrderBook.sol';
import { IGmxPositionRouter } from './interfaces/IGmxPositionRouter.sol';

/**
 * @title   GmxConfig
 * @dev     Used to store addresses and configuration values for the GMX system.
 * @notice  Ref stored in the regsitry, Only deployed on chains that support gmx
 */

contract GmxConfig {
    IGmxRouter public immutable router;
    IGmxPositionRouter public immutable positionRouter;
    IGmxVault public immutable vault;
    IGmxOrderBook public immutable orderBook;
    bytes32 public immutable referralCode;
    uint public immutable maxPositions = 2;
    // The number of unexecuted requests a vault can have open at a time.
    uint public immutable maxOpenRequests = 2;
    // The number of unexecuted decrease orders a vault can have open at a time.
    uint public immutable maxOpenDecreaseOrders = 2;
    uint public immutable acceptablePriceDeviationBasisPoints = 200; // 2%

    constructor(
        address _gmxRouter,
        address _gmxPositionRouter,
        address _gmxVault,
        address _gmxOrderBook,
        bytes32 _gmxReferralCode
    ) {
        router = IGmxRouter(_gmxRouter);
        positionRouter = IGmxPositionRouter(_gmxPositionRouter);
        vault = IGmxVault(_gmxVault);
        orderBook = IGmxOrderBook(_gmxOrderBook);
        referralCode = _gmxReferralCode;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IntegrationDataTrackerStorage, Integration } from './IntegrationDataTrackerStorage.sol';

// This contract is a general store for when we need to store data that is relevant to an integration
// For example with GMX we must track what positions are open for each vault

contract IntegrationDataTracker {
    /**
     * @notice record new raw data
     * @param _integration used as the namespace for the data
     * @param _data the data track data to be recorded in storage
     */
    function pushData(Integration _integration, bytes memory _data) external {
        _pushData(_integration, msg.sender, _data);
    }

    /**
     * @notice record new raw data
     * @param _integration used as the namespace for the data
     * @param _data the data track data to be recorded in storage
     */
    function pushData(bytes32 _integration, bytes memory _data) external {
        _pushData(_integration, msg.sender, _data);
    }

    /**
     * @notice delete data
     * @param _integration used as the namespace for the data
     * @param _index data index to be removed from storage
     */
    function removeData(Integration _integration, uint256 _index) external {
        _removeData(_integration, msg.sender, _index);
    }

    /**
     * @notice delete data
     * @param _integration used as the namespace for the data
     * @param _index data index to be removed from storage
     */
    function removeData(bytes32 _integration, uint256 _index) external {
        _removeData(_integration, msg.sender, _index);
    }

    /**
     * @notice returns tracked data by index
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @param _index the index of data track data
     * @return data the data track data of given NFT_TYPE & poolLogic & index
     */
    function getData(
        Integration _integration,
        address _vault,
        uint256 _index
    ) external view returns (bytes memory) {
        return
            IntegrationDataTrackerStorage.layout().trackedData[
                bytes32(uint(_integration))
            ][_vault][_index];
    }

    /**
     * @notice returns tracked data by index
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @param _index the index of data track data
     * @return data the data track data of given NFT_TYPE & poolLogic & index
     */
    function getData(
        bytes32 _integration,
        address _vault,
        uint256 _index
    ) external view returns (bytes memory) {
        return
            IntegrationDataTrackerStorage.layout().trackedData[_integration][
                _vault
            ][_index];
    }

    /**
     * @notice returns all tracked datas by NFT_TYPE & poolLogic
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @return data all tracked datas of given NFT_TYPE & poolLogic
     */
    function getAllData(
        Integration _integration,
        address _vault
    ) external view returns (bytes[] memory) {
        return
            IntegrationDataTrackerStorage.layout().trackedData[
                bytes32(uint(_integration))
            ][_vault];
    }

    /**
     * @notice returns all tracked datas by NFT_TYPE & poolLogic
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @return data all tracked datas of given NFT_TYPE & poolLogic
     */
    function getAllData(
        bytes32 _integration,
        address _vault
    ) external view returns (bytes[] memory) {
        return
            IntegrationDataTrackerStorage.layout().trackedData[_integration][
                _vault
            ];
    }

    /**
     * @notice returns all tracked datas by NFT_TYPE & poolLogic
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @return count all tracked datas count of given NFT_TYPE & poolLogic
     */
    function getDataCount(
        Integration _integration,
        address _vault
    ) external view returns (uint256) {
        return
            IntegrationDataTrackerStorage
            .layout()
            .trackedData[bytes32(uint(_integration))][_vault].length;
    }

    /**
     * @notice returns all tracked datas by NFT_TYPE & poolLogic
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @return count all tracked datas count of given NFT_TYPE & poolLogic
     */
    function getDataCount(
        bytes32 _integration,
        address _vault
    ) external view returns (uint256) {
        return
            IntegrationDataTrackerStorage
            .layout()
            .trackedData[_integration][_vault].length;
    }

    /**
     * @notice record new raw data
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @param _data the data track data to be recorded in storage
     */
    function _pushData(
        bytes32 _integration,
        address _vault,
        bytes memory _data
    ) private {
        IntegrationDataTrackerStorage
        .layout()
        .trackedData[_integration][_vault].push(_data);
    }

    /**
     * @notice record new raw data
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @param _data the data track data to be recorded in storage
     */
    function _pushData(
        Integration _integration,
        address _vault,
        bytes memory _data
    ) private {
        IntegrationDataTrackerStorage
        .layout()
        .trackedData[bytes32(uint(_integration))][_vault].push(_data);
    }

    /**
     * @notice delete data
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @param _index data index to be removed from storage
     */
    function _removeData(
        bytes32 _integration,
        address _vault,
        uint256 _index
    ) private {
        IntegrationDataTrackerStorage.Layout
            storage l = IntegrationDataTrackerStorage.layout();
        uint256 length = l.trackedData[_integration][_vault].length;
        require(_index < length, 'invalid index');

        l.trackedData[_integration][_vault][_index] = l.trackedData[
            _integration
        ][_vault][length - 1];
        l.trackedData[_integration][_vault].pop();
    }

    /**
     * @notice delete data
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @param _index data index to be removed from storage
     */
    function _removeData(
        Integration _integration,
        address _vault,
        uint256 _index
    ) private {
        IntegrationDataTrackerStorage.Layout
            storage l = IntegrationDataTrackerStorage.layout();
        bytes32 key = bytes32(uint(_integration));
        uint256 length = l.trackedData[key][_vault].length;
        require(_index < length, 'invalid index');

        l.trackedData[key][_vault][_index] = l.trackedData[key][_vault][
            length - 1
        ];
        l.trackedData[key][_vault].pop();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// Not sure if we should use an enum here because the integrations are not fixed
// We could use a keccak("IntegrationName") instead, this contract will have to be upgraded if we add a new integration
// Because solidity validates enum params at runtime
enum Integration {
    GMXRequests,
    GMXPositions,
    GMXDecreaseOrders
}

library IntegrationDataTrackerStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.IntegationDataTracker');

    // solhint-disable-next-line ordering
    struct Layout {
        // Integration -> vault -> data[]
        mapping(bytes32 => mapping(address => bytes[])) trackedData;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IAggregatorV3Interface {
    function description() external view returns (string memory);

    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// solhint-disable ordering
interface IGmxOrderBook {
    function minExecutionFee() external view returns (uint256);

    function decreaseOrdersIndex(address) external view returns (uint256);

    function getSwapOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address path0,
            address path1,
            address path2,
            uint256 amountIn,
            uint256 minOut,
            uint256 triggerRatio,
            bool triggerAboveThreshold,
            bool shouldUnwrap,
            uint256 executionFee
        );

    function getIncreaseOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address purchaseToken,
            uint256 purchaseTokenAmount,
            address collateralToken,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function getDecreaseOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address collateralToken,
            uint256 collateralDelta,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function executeSwapOrder(address, uint256, address payable) external;

    function executeDecreaseOrder(address, uint256, address payable) external;

    function executeIncreaseOrder(address, uint256, address payable) external;

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable;

    function updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function cancelDecreaseOrder(uint256 _orderIndex) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// solhint-disable ordering
interface IGmxPositionRouter {
    struct IncreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool hasCollateralInETH;
        address callbackTarget;
    }

    struct DecreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        address receiver;
        uint256 acceptablePrice;
        uint256 minOut;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool withdrawETH;
        address callbackTarget;
    }

    function setPositionKeeper(address _account, bool _isActive) external;

    function executeIncreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function executeDecreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable returns (bytes32);

    function minExecutionFee() external view returns (uint256);

    function getRequestKey(
        address _account,
        uint256 _index
    ) external pure returns (bytes32);

    function cancelIncreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function cancelDecreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function executeIncreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function executeDecreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function increasePositionRequestKeysStart() external view returns (uint256);

    function decreasePositionRequestKeysStart() external view returns (uint256);

    function increasePositionsIndex(
        address account
    ) external view returns (uint256);

    function increasePositionRequests(
        bytes32 key
    )
        external
        view
        returns (
            address account,
            // address[] memory path,
            address indexToken,
            uint256 amountIn,
            uint256 minOut,
            uint256 sizeDelta,
            bool isLong,
            uint256 acceptablePrice,
            uint256 executionFee,
            uint256 blockNumber,
            uint256 blockTime,
            bool hasCollateralInETH,
            address callbackTarget
        );

    function getIncreasePositionRequestPath(
        bytes32 _key
    ) external view returns (address[] memory);

    function getDecreasePositionRequestPath(
        bytes32 _key
    ) external view returns (address[] memory);

    function decreasePositionsIndex(
        address account
    ) external view returns (uint256);

    function vault() external view returns (address);

    function admin() external view returns (address);

    function getRequestQueueLengths()
        external
        view
        returns (uint256, uint256, uint256, uint256);

    function decreasePositionRequests(
        bytes32
    )
        external
        view
        returns (
            address account,
            address indexToken,
            uint256 collateralDelta,
            uint256 sizeDelta,
            bool isLong,
            address receiver,
            uint256 acceptablePrice,
            uint256 minOut,
            uint256 executionFee,
            uint256 blockNumber,
            uint256 blockTime,
            bool withdrawETH,
            address callbackTarget
        );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IGmxPositionRouterCallbackReceiver {
    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool isIncrease
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IGmxRouter {
    function addPlugin(address _plugin) external;

    function pluginTransfer(
        address _token,
        address _account,
        address _receiver,
        uint256 _amount
    ) external;

    function pluginIncreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function pluginDecreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function swap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address _receiver
    ) external;

    function directPoolDeposit(address _token, uint256 _amount) external;

    function approvePlugin(address) external;

    function decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) external;

    function swapETHToTokens(
        address[] memory _path,
        uint256 _minOut,
        address _receiver
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable ordering
interface IGmxVault {
    function maxGasPrice() external view returns (uint256);

    function approvedRouters(
        address _account,
        address _router
    ) external view returns (bool);

    function isLiquidator(address _account) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(
        address _token
    ) external view returns (uint256);

    function tokenBalances(address _token) external view returns (uint256);

    function lastFundingTimes(address _token) external view returns (uint256);

    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(
        uint256 _fundingInterval,
        uint256 _fundingRateFactor,
        uint256 _stableFundingRateFactor
    ) external;

    function updateCumulativeFundingRate(address _token) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _aggregatorAddress) external;

    function withdrawFees(
        address _token,
        address _receiver
    ) external returns (uint256);

    function directPoolDeposit(address _token) external;

    function buyUSDG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function sellUSDG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function validateLiquidation(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) external view returns (uint256, uint256);

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function usdToTokenMax(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);

    function priceFeed() external view returns (address);

    function fundingRateFactor() external view returns (uint256);

    function stableFundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(
        address _token
    ) external view returns (uint256);

    function getNextFundingRate(address _token) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function whitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function globalShortAveragePrices(
        address _token
    ) external view returns (uint256);

    function maxGlobalShortSizes(
        address _token
    ) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function poolAmounts(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function getRedemptionAmount(
        address _token,
        uint256 _usdgAmount
    ) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256);

    function getPositionKey(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external pure returns (bytes32);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256 size,
            uint256 collateral,
            uint256 averagePrice,
            uint256 entryFundingRate,
            uint256 reserveAmount,
            uint256 realisedPnl,
            bool hasRealisedProfit,
            uint256 lastIncreasedTime
        );

    function getFundingFee(
        address _token,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getPositionFee(uint256 _sizeDelta) external view returns (uint256);

    function PRICE_PRECISION() external view returns (uint256);

    function BASIS_POINTS_DIVISOR() external view returns (uint256);

    function setError(uint256 _errorCode, string calldata _error) external;

    function isInitialized() external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function router() external view returns (address);

    function usdg() external view returns (address);

    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);

    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);

    function hasDynamicFees() external view returns (bool);

    function fundingInterval() external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function getTargetUsdgAmount(
        address _token
    ) external view returns (uint256);

    function inManagerMode() external view returns (bool);

    function inPrivateLiquidationMode() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IPoolPair {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISnxAddressResolver {
    function importAddresses(
        bytes32[] calldata names,
        address[] calldata destinations
    ) external;

    function rebuildCaches(address[] calldata destinations) external;

    function owner() external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function getAddress(bytes32 name) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function balanceOf(address user) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title   Call
 * @dev     Utils for making calls to other contracts that bubble up the revert reason
 */

library Call {
    function _delegate(address to, bytes memory data) internal {
        (bool success, bytes memory result) = to.delegatecall(data);

        if (!success) {
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }

    function _call(address to, bytes memory data) internal {
        (bool success, bytes memory result) = to.call(data);

        if (!success) {
            if (result.length < 68) revert('call failed');
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library Constants {
    // Aka decimals, the precision of the numbers the vault returns`
    uint internal constant VAULT_PRECISION = 10 ** 8;
    // Used for dealing with percentages
    uint internal constant BASIS_POINTS_DIVISOR = 10_000;
    // Used for dealing with portions of a whole where we must have high accuracy
    uint internal constant PORTION_DIVISOR = 10 ** 18;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';
import { IERC2612 } from '@solidstate/contracts/token/ERC20/permit/IERC2612.sol';

/**
 * @title   TrustlessPermit
 * @dev     Signed Permits can be extracted and front run. Meaning that they will revert if already used
 * @dev     Can be a very unlikely griefing vector. This library mitigates this by trying permit() first
 * @notice  Credit to https://www.trust-security.xyz/
 */

library TrustlessPermit {
    function trustlessPermit(
        address token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        // Try permit() before allowance check to advance nonce if possible
        try IERC2612(token).permit(owner, spender, value, deadline, v, r, s) {
            return;
        } catch {
            // Permit potentially got frontran. Continue anyways if allowance is sufficient.
            if (IERC20(token).allowance(owner, spender) >= value) {
                return;
            }
        }
        revert('Permit failure');
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IRedeemerEvents } from './IRedeemerEvents.sol';

/**
 * @title   IRedeemer
 * @dev     Interface for redeeming assets from a vault
 * @notice  The redeemers are responsible for transferring assets to the withdrawer
 */

interface IRedeemer is IRedeemerEvents {
    // For some assets, closing a portion directly to the user is not possible
    // Or some assets only allow the claiming all rewards to the owner (you can't claim a portion of the rewards)
    // In this case these operations have to happen first, returning those assets to the vault
    // And then being distributed to the withdrawer during normal erc20 withdraw processing
    // A good example of this is with GMX, where sometimes we will have to close the entire position to the vault
    // And then distribute a portion of the proceeds downstream to the withdrawer.
    // The function of having preWithdraw saves us the drama of having to try and ORDER asset withdraws.
    function preWithdraw(
        uint tokenId,
        address asset,
        address withdrawer,
        uint portion
    ) external payable;

    function withdraw(
        uint tokenId,
        address asset,
        address withdrawer,
        uint portion
    ) external payable;

    function hasPreWithdraw() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IRedeemerEvents {
    event Redeemed(
        uint tokenId,
        address indexed asset,
        address to,
        address redeemedAs,
        uint amount
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import { Accountant } from '../Accountant.sol';
import { ExecutorIntegration } from '../executors/IExecutor.sol';
import { IntegrationDataTracker } from '../integration-data-tracker/IntegrationDataTracker.sol';
import { RegistryStorage } from './RegistryStorage.sol';
import { GmxConfig } from '../GmxConfig.sol';
import { SnxConfig } from '../SnxConfig.sol';
import { Transport } from '../transport/Transport.sol';
import { Constants } from '../lib/Constants.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';
import { SafeOwnable } from '@solidstate/contracts/access/ownable/SafeOwnable.sol';
import { IWETH } from '../interfaces/IWeth.sol';
import { IPoolPair } from '../interfaces/IPoolPair.sol';
import { IAggregatorV3Interface } from '../interfaces/IAggregatorV3Interface.sol';
import { IValioCustomAggregator } from '../aggregators/IValioCustomAggregator.sol';

import { Pausable } from '@solidstate/contracts/security/pausable/Pausable.sol';

/**
 * @title   Registry
 * @dev     This contract is cut into the RegistryDiamond.
 * @notice  The registry is a central place to store all the addresses and settings in the system.
 */

contract Registry is SafeOwnable, Pausable {
    // Emit event that informs that the another event was emitted on the target address
    // This means we can listen to this event and know that the target address has emitted an event
    event EventEmitted(address target);

    event AssetTypeChanged(address asset, RegistryStorage.AssetType assetType);
    event AssetDeprecationChanged(address asset, bool deprecated);
    event AssetHardDeprecationChanged(address asset, bool deprecated);
    event SetPoolConfig(address asset, RegistryStorage.PoolConfig poolConfig);

    modifier onlyTransport() {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        require(address(l.transport) == msg.sender, 'not transport');
        _;
    }

    modifier onlyVault() {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        require(
            l.parentVaults[msg.sender] || l.childVaults[msg.sender],
            'not vault'
        );
        _;
    }

    /**
     * @notice  Initializes the registry with the initial settings
     * @dev     DEPRECATED: use individual setters
     * @param   _chainId  The LayerZero chainId of the chain the registry is deployed to
     * @param   _protocolTreasury The address of the protocol treasury
     * @param   _transport  The address of the transport contract
     * @param   _parentVaultDiamond  The address of the parent vault diamond
     * @param   _childVaultDiamond  The address of the child vault diamond
     * @param   _accountant  The address of the accountant
     * @param   _integrationDataTracker  The address of the integration data tracker
     */
    function initialize(
        uint16 _chainId,
        address _protocolTreasury,
        address payable _transport,
        address _parentVaultDiamond,
        address _childVaultDiamond,
        address _accountant,
        address _integrationDataTracker
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        require(l.chainId == 0, 'Already initialized');
        l.chainId = _chainId;
        l.protocolTreasury = _protocolTreasury;
        l.transport = Transport(_transport);
        l.parentVaultDiamond = _parentVaultDiamond;
        l.childVaultDiamond = _childVaultDiamond;
        l.accountant = Accountant(_accountant);
        l.integrationDataTracker = IntegrationDataTracker(
            _integrationDataTracker
        );
        l.chainlinkTimeout = 24 hours;
    }

    /// MODIFIERS

    /**
     * @notice  Emit event that informs that the another event was emitted on the caller address
     * @dev     This means we can listen to this event and know that the target address has emitted an event
     */
    function emitEvent() external {
        _emitEvent(msg.sender);
    }

    /**
     * @notice  Pauses the Protocol
     * @dev     Can only be called by the owner
     * @dev     Will block deposits and withdraws amoung other things
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice  Unpauses the Protocol
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice  Allows the transport to add a vault to the registry
     * @dev     The creation of Vaults should be moved to the Registry
     * @param   vault The address of the vault to add
     */
    function addVaultParent(address vault) external onlyTransport {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.parentVaults[vault] = true;
        l.parentVaultList.push(vault);
    }

    /**
     * @notice  Allows the transport to add a child vault to the registry
     * @dev     The creation of Vaults should be moved to the Registry
     * @param   vault  The address of the vault to add
     */
    function addVaultChild(address vault) external onlyTransport {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.childVaults[vault] = true;
        l.childVaultList.push(vault);
    }

    /**
     * @notice  Sets the given asset to deprecated/undeprecated
     * @dev     Deprecated assets are not allowed to be traded into
     * @param   asset  The address of the asset to deprecate
     * @param   deprecated  True if the asset is deprecated
     */
    function setDeprecatedAsset(
        address asset,
        bool deprecated
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.deprecatedAssets[asset] = deprecated;
        emit AssetDeprecationChanged(asset, deprecated);
        _emitEvent(address(this));
    }

    /**
     * @notice  Sets the given asset to hard deprecated/undeprecated
     * @dev     Hard deprecated assets cannot be valued, vaults holding them cannot be deposited into
     * @param   asset  The address of the asset to deprecate
     * @param   deprecated  True if the asset is deprecated
     */
    function setHardDeprecatedAsset(
        address asset,
        bool deprecated
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.hardDeprecatedAssets[asset] = deprecated;
        emit AssetHardDeprecationChanged(asset, deprecated);
        _emitEvent(address(this));
    }

    /**
     * @notice  Sets the asset type for the given asset
     * @dev     Erc20, GMX, SnxPerpsV2, etc
     * @param   asset  The address of the asset
     * @param   _assetType  The type of the asset
     */
    function setAssetType(
        address asset,
        RegistryStorage.AssetType _assetType
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.assetTypes[asset] = _assetType;
        l.assetList.push(asset);
        emit AssetTypeChanged(asset, _assetType);
        _emitEvent(address(this));
    }

    /**
     * @notice  Sets the Valuer Contract for the given AssetType
     * @dev     The valuer is responsible for getting the value of the asset
     * @param   _assetType  The type of the asset
     * @param   valuer  The address of the valuer contract
     */
    function setValuer(
        RegistryStorage.AssetType _assetType,
        address valuer
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.valuers[_assetType] = valuer;
    }

    /**
     * @notice  Sets the Redeemer Contract for the given AssetType
     * @dev     The redeemer is responsible for redeeming the asset from the vault
     * @param   _assetType  The type of the asset
     * @param   redeemer  The address of the redeemer contract
     */
    function setRedeemer(
        RegistryStorage.AssetType _assetType,
        address redeemer
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.redeemers[_assetType] = redeemer;
    }

    /**
     * @notice  Sets the Chainlink Aggregator for the given asset
     * @dev     The aggregator is responsible for getting the price of the asset
     * @dev     Not all assets have a chainlink aggregator, gmx for instance returns a value in usd.
     * @param   asset  The address of the asset
     * @param   aggregator  The address of the chainlink aggregator
     */
    function setChainlinkV3USDAggregator(
        address asset,
        IAggregatorV3Interface aggregator
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.chainlinkV3USDAggregators[asset] = aggregator;
    }

    /**
     * @notice  Sets the Aggregator Contract for the given AggregatorType
     * @dev     AggregatorType eg: UniswapV3Twap,VelodromeV2Twap
     * @dev     It will be called to get/calculate the unit price for any assets configured with this AggregatorType
     * @param   _aggregatorType  The type of the aggregator
     * @param   _customAggregator The address of the aggregator contract
     */
    function setValioCustomUSDAggregator(
        RegistryStorage.AggregatorType _aggregatorType,
        IValioCustomAggregator _customAggregator
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.valioCustomUSDAggregators[_aggregatorType] = _customAggregator;
    }

    /**
     * @notice  Sets Aggregator Type for the given asset
     * @dev     The AggregatorType will get the Aggregator that gets the price for the asset
     * @dev     Havng `Aggregator` type allows us to share the same Aggregator for multiple assets
     * @param   asset  The address of the asset
     * @param   aggregatorType  The type of the aggregator
     */
    function setAssetAggregatorType(
        address asset,
        RegistryStorage.AggregatorType aggregatorType
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.assetAggregatorType[asset] = aggregatorType;
    }

    /**
     * @notice  Sets the Accountant Contract
     * @param   _accountant  The address of the accountant contract
     */
    function setAccountant(address _accountant) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.accountant = Accountant(_accountant);
    }

    /**
     * @notice  Sets the Transport Contract
     * @dev     The transport is proxy for all cross chain messaging
     * @dev     Its a Diamond so should never change.
     * @param   _transport The address of the transport contract
     */
    function setTransport(address payable _transport) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.transport = Transport(_transport);
    }

    /**
     * @notice  Sets the protocol treasury address
     * @dev     The protocol treasury is the address that receives the protocol fees
     * @param   _treasury  The address of the protocol treasury
     */
    function setProtocolTreasury(address payable _treasury) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.protocolTreasury = (_treasury);
    }

    /**
     * @notice  The protocols share of manager fees
     * @param   _protocolFeeBips  The protocol fee in bips
     */
    function setProtocolFeeBips(uint256 _protocolFeeBips) external onlyOwner {
        // 20% max fee
        require(_protocolFeeBips <= 2000, 'invalid fee');
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.protocolFeeBips = _protocolFeeBips;
    }

    /**
     * @notice  Sets the integration data tracker
     * @dev     The integration data tracker is responsible for tracking the data from the integrations
     * @dev     It should never change as the IntegrationDataTracker is a diamond. Changing it will loose stored state.
     * @param   _integrationDataTracker  .
     */
    function setIntegrationDataTracker(
        address _integrationDataTracker
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.integrationDataTracker = IntegrationDataTracker(
            _integrationDataTracker
        );
    }

    /**
     * @notice  Sets the ZeroX Exchange Router
     * @dev     Should be changed to use ancillaryContractAddresses
     * @param   _zeroXExchangeRouter  The address of the ZeroX Exchange Router
     */
    function setZeroXExchangeRouter(
        address _zeroXExchangeRouter
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.zeroXExchangeRouter = _zeroXExchangeRouter;
    }

    /**
     * @notice  Sets the Executor for the given integration
     * @dev     The executor is responsible for checking/executing manager transactions
     * @param   integration The integration to set the executor for
     * @param   executor  The address of the executor contract
     */
    function setExecutor(
        ExecutorIntegration integration,
        address executor
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.executors[integration] = executor;
    }

    /**
     * @notice  Sets the deposit lockup time
     * @dev     The deposit lockup time is the time that a deposit is locked up for.
     * @dev     This protects lps from nefarious behaviour
     * @param   _depositLockupTime  .
     */
    function setDepositLockupTime(uint _depositLockupTime) external onlyOwner {
        require(
            _depositLockupTime <= 24 hours && _depositLockupTime > 0,
            'invalid lockup'
        );
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.depositLockupTime = _depositLockupTime;
    }

    /**
     * @notice  Sets the max active assets
     * @dev     The max active assets is the maximum number of assets that can be active in a vault at any one time
     * @dev     If the vault has to many assets it can exceed the block gas limit or make redemptions expensive (eth)
     * @dev     This can vary from chain to chain
     * @param   _maxActiveAssets The maximum number of active assets
     */
    function setMaxActiveAssets(uint _maxActiveAssets) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.maxActiveAssets = _maxActiveAssets;
    }

    /**
     * @notice  Sets whether the manager can change the manager
     * @dev     The manager can change the manager if this is true
     * @param   _canChangeManager  True if the manager can change the manager
     */
    function setCanChangeManager(bool _canChangeManager) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.canChangeManager = _canChangeManager;
    }

    /**
     * @notice  Sets the gmxConfig address
     * @dev     Only for chains the support GMX
     * @param   _gmxConfig  The address of the gmxConfig contract
     */
    function setGmxConfig(address _gmxConfig) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.gmxConfig = GmxConfig(_gmxConfig);
    }

    /**
     * @notice  Sets the liveliness threshold
     * @dev     The liveliness threshold is the time a vault value update from a child is valid for
     * @param   _livelinessThreshold  The time in seconds
     */
    function setLivelinessThreshold(
        uint256 _livelinessThreshold
    ) external onlyOwner {
        require(_livelinessThreshold <= 24 hours, 'invalid threshold');
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.livelinessThreshold = _livelinessThreshold;
    }

    /**
     * @notice  Sets the max cpit bips
     * @dev     The the maximum amount of cpit that is allowed in a 24 hour period for a given risk profile
     * @param   riskProfile  The risk profile to set the max cpit bips for
     * @param   _maxCpitBips  The maximum amount of cpit in bips
     */
    function setMaxCpitBips(
        VaultRiskProfile riskProfile,
        uint256 _maxCpitBips
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.maxCpitBips[riskProfile] = _maxCpitBips;
    }

    /**
     * @notice  Sets the initial min deposit amount
     * @dev     This is the minimum amount that has to be first deposited into a holding
     * @param   _minDepositAmount The minimum deposit amount in USD (Constants.VAULT_PRECISION decimals)
     */
    function setMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.minDepositAmount = _minDepositAmount;
    }

    /**
     * @notice  Sets the default max deposit amount per holding
     * @dev     This is the maximum amount that can be deposited into a holding
     * @dev     If the vault has a custom value cap, this value is ignored
     * @param   _maxDepositAmount The maximum deposit amount in USD (Constants.VAULT_PRECISION decimals)
     */
    function setMaxDepositAmount(uint256 _maxDepositAmount) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.maxDepositAmount = _maxDepositAmount;
    }

    /**
     * @notice  Sets whether the manager can change the manager fees
     * @param   _canChangeManagerFees  True if the manager can change the manager fees
     */
    function setCanChangeManagerFees(
        bool _canChangeManagerFees
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.canChangeManagerFees = _canChangeManagerFees;
    }

    /**
     * @notice  Sets whether the asset can be deposited into the vault
     * @dev     Currently only USDC/USDC.e
     * @dev     Only strong stablecoins should be added
     * @param   _depositAsset The address of the asset
     * @param   canDeposit    True if the asset can be deposited
     */
    function setDepositAsset(
        address _depositAsset,
        bool canDeposit
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.depositAssets[_depositAsset] = canDeposit;
    }

    /**
     * @notice  Sets the vault value cap
     * @dev     The default value cap for a vault
     * @dev     Ignored if the vault has a custom value cap
     * @param   _vaultValueCap The value cap in USD (Constants.VAULT_PRECISION decimals)
     */
    function setVaultValueCap(uint256 _vaultValueCap) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.vaultValueCap = _vaultValueCap;
    }

    /**
     * @notice  Sets the withdraw automator
     * @dev     DEPRECATED: Use Relay
     * @param   _withdrawAutomator The address of the withdraw automator
     */
    function setWithdrawAutomator(
        address _withdrawAutomator
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.withdrawAutomator = _withdrawAutomator;
    }

    /**
     * @notice  Sets the deposit automator
     * @dev     DEPRECATED: Use Relay
     * @param   _depositAutomator  The address of the deposit automator
     */
    function setDepositAutomator(address _depositAutomator) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.depositAutomator = _depositAutomator;
    }

    /**
     * @notice  Sets the snxConfig address
     * @dev     Only for chains the support SNX
     * @param   _snxConfig  The address of the snxConfig contract
     */
    function setSnxConfig(address _snxConfig) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.snxConfig = SnxConfig(_snxConfig);
    }

    /**
     * @notice  Sets the snxPerpsV2Erc20WrapperDiamond
     * @dev     A snxPerpsV2Erc20Wrapper is deployed for each snx perp position in a vault
     * @param   _snxPerpsV2Erc20WrapperDiamond  The implementation for a SnxPerpsV2Erc20Wrapper
     */
    function setSnxPerpsV2Erc20WrapperDiamond(
        address _snxPerpsV2Erc20WrapperDiamond
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.snxPerpsV2Erc20WrapperDiamond = _snxPerpsV2Erc20WrapperDiamond;
    }

    /**
     * @notice  Sets a custom value cap for a vault
     * @dev     Once a vault exceeds this value, it will not accept any more deposits
     * @param   vault  The address of the vault
     * @param   _customVaultValueCap  The custom value cap in USD (Constants.VAULT_PRECISION decimals)
     */
    function setCustomVaultValueCap(
        address vault,
        uint256 _customVaultValueCap
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.customVaultValueCaps[vault] = _customVaultValueCap;
    }

    /**
     * @notice  Adds a snxPerpsV2Erc20Wrapper to the registry
     * @dev     Allows us to store All wrappers for offchain use/tracking
     * @param   wrapperAddress  The address of the snxPerpsV2Erc20Wrapper
     */
    function addSnxPerpsV2Erc20Wrapper(
        address wrapperAddress
    ) external onlyVault {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.snxPerpsV2Erc20WrapperList.push(wrapperAddress);
    }

    /**
     * @notice  Sets the uniswap v3Pool for the given asset
     * @dev     We store this information in the registry so if we need to upate the logic of the UniswapV3Twap we can
     * @param   asset  The address of the asset
     * @param   pool  The address of the uniswap v3 pool
     */
    function setPoolConfig(address asset, IPoolPair pool) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        address pairToken;

        if (asset == pool.token0()) {
            pairToken = pool.token1();
        } else if (asset == pool.token1()) {
            pairToken = pool.token0();
        } else {
            revert('invalid pool');
        }

        // Must have a chainlink aggregator for the pairedToken
        require(
            address(l.chainlinkV3USDAggregators[pairToken]) != address(0),
            'no pair aggregator'
        );

        l.assetToPoolConfig[asset] = RegistryStorage.PoolConfig(
            address(pool),
            pairToken
        );

        emit SetPoolConfig(asset, l.assetToPoolConfig[asset]);
    }

    /**
     * @notice  The address of the native token wrapper for the chain deployed on
     * @dev     ETH -> WETH, MATIC - WRAPPEDMATIC
     * @param   _wrappedNativeToken  The address of the wrapped native token
     */
    function setWrappedNativeToken(
        IWETH _wrappedNativeToken
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.wrappedNativeToken = _wrappedNativeToken;
    }

    /**
     * @notice  Sets an ancillary contract address in the registry
     * @dev     Added so we can store references to other contracts, without having to change the registry
     * @param   _contractName  The contract name, care needs to be taken not to cause collisions, bytes32 encoded
     * @param   _contractAddress  The address of the contract
     */
    function setAncillaryContractAddress(
        bytes32 _contractName,
        address _contractAddress
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.ancillaryContractAddresses[_contractName] = _contractAddress;
    }

    /// VIEWS

    /**
     * @notice  Returns the address of the given ancillary contract
     * @dev     Added so we can store references to other contracts, without having to change the registry
     * @dev     Potentially add a address(0) check here
     * @param   _contractName  The contract name bytes32 encoded
     * @return  address  The address of the contract
     */
    function ancillaryContractAddresses(
        bytes32 _contractName
    ) external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.ancillaryContractAddresses[_contractName];
    }

    /**
     * @notice  Returns the address of the given ancillary contract
     * @dev     Added so the frontend can just use string as param instead of bytes32
     * @param   _contractName  The contract name as a string
     * @return  address  The address of the contract
     */
    function ancillaryContractAddressByString(
        string memory _contractName
    ) external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        bytes32 strBytes;

        assembly {
            strBytes := mload(add(_contractName, 32))
        }
        return l.ancillaryContractAddresses[strBytes];
    }

    /**
     * @notice  Returns the wrappedNativeToken
     * @dev     The wrappedNativeToken is the native token wrapped for the chain the registry is deployed on
     * @return  IWETH The wrapped native token address
     */
    function wrappedNativeToken() external view returns (IWETH) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.wrappedNativeToken;
    }

    /**
     * @notice  Returns the poolConfig for the given asset
     * @param   asset  The address of the asset
     * @return  RegistryStorage.PoolConfig  The pool config(pool, pairToken)
     */
    function poolConfig(
        address asset
    ) external view returns (RegistryStorage.PoolConfig memory) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.assetToPoolConfig[asset];
    }

    /**
     * @notice  Returns all snxPerpsV2Erc20Wrapper addresses
     * @dev     The snxPerpsV2Erc20Wrapper is deployed for each snx perp position in a vault
     * @dev     This allows us to get all wrappers for offchain use/tracking
     * @return  address[]  The list of snxPerpsV2Erc20Wrapper addresses
     */
    function snxPerpsV2Erc20WrapperList()
        external
        view
        returns (address[] memory)
    {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.snxPerpsV2Erc20WrapperList;
    }

    /**
     * @notice  Returns the custom value cap for the given vault
     * @dev     Once a vault exceeds this value, it will not accept any more deposits
     * @param   vault  The address of the vault
     * @return  uint256  The custom value cap in USD (Constants.VAULT_PRECISION decimals)
     */
    function customVaultValueCap(
        address vault
    ) external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.customVaultValueCaps[vault];
    }

    /**
     * @notice  Returns the protocol fee in bips
     * @dev     The protocols share of manager fees
     * @return  uint256  The protocol fee in bips
     */
    function protocolFeeBips() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.protocolFeeBips;
    }

    /**
     * @notice  Returns the deposit automator
     * @dev     DEPRECATED: Use Relay
     * @return  address  The address of the deposit automator
     */
    function depositAutomator() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.depositAutomator;
    }

    /**
     * @notice  Returns the withdraw automator
     * @dev     DEPRECATED: Use Relay
     * @return  address  The address of the withdraw automator
     */
    function withdrawAutomator() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.withdrawAutomator;
    }

    /**
     * @notice  Returns the default vault value cap
     * @dev     Once a vault exceeds this value, it will not accept any more deposits unless it has a custom cap
     * @return  uint256  .
     */
    function vaultValueCap() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.vaultValueCap;
    }

    /**
     * @notice  Returns the max price impact that can be incurred in 24s for the given risk profile
     * @param   riskProfile  The risk profile to get the max cpit bips for
     * @return  uint256  The maximum amount of cpit in bips
     */
    function maxCpitBips(
        VaultRiskProfile riskProfile
    ) external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.maxCpitBips[riskProfile];
    }

    /**
     * @notice  Returns the ParentVaultDiamond, the implementation for all Deployed Parent Vaults
     * @dev     The ParentVaultDiamond is a diamond, so should never change
     * @dev     Changing this will not update existing vaults
     * @return  address  The address of the ParentVaultDiamond
     */
    function parentVaultDiamond() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.parentVaultDiamond;
    }

    /**
     * @notice  Returns the ChildVaultDiamond, the implementation for all Deployed Child Vaults
     * @dev     The ChildVaultDiamond is a diamond, so should never change
     * @dev     Changing this will not update existing vaults
     * @return  address The address of the ChildVaultDiamond
     */
    function childVaultDiamond() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.childVaultDiamond;
    }

    /**
     * @notice  Returns LayerZero chainId
     * @return  uint16  The LayerZero chainId
     */
    function chainId() external view returns (uint16) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.chainId;
    }

    /**
     * @notice  Returns the protocol treasury address
     * @return  address  The address of the protocol treasury
     */
    function protocolTreasury() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.protocolTreasury;
    }

    /**
     * @notice  Returns true if the given address is registed valio vault
     * @dev     A valio vault is a vault that has been created by the valio protocol
     * @param   vault  The address of the vault
     * @return  bool  True if the vault is a valio vault
     */
    function isVault(address vault) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.parentVaults[vault] || l.childVaults[vault];
    }

    /**
     * @notice  Returns true if the given address is registed valio parent vault
     * @dev     A valio vault is a vault that has been created by the valio protocol
     * @param   vault  The address of the vault
     * @return  bool  True if the vault is a valio parent vault
     */
    function isVaultParent(address vault) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.parentVaults[vault];
    }

    /**
     * @notice  Returns true if the given address is registed valio child vault
     * @dev     A valio vault is a vault that has been created by the valio protocol
     * @param   vault  The address of the vault
     * @return  bool  True if the vault is a valio child vault
     */
    function isVaultChild(address vault) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.childVaults[vault];
    }

    /**
     * @notice  Returns the exectutor address for the given integration
     * @dev     The executor is responsible for checking/executing manager transactions
     * @param   integration  The integration to get the executor for
     * @return  address  The address of the executor contract
     */
    function executors(
        ExecutorIntegration integration
    ) external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.executors[integration];
    }

    /**
     * @notice  Returns the redeemer for the given asset
     * @dev     The redeemer is responsible for redeeming the asset from the vault
     * @param   asset  The address of the asset
     * @return  address  The address of the redeemer contract
     */
    function redeemers(address asset) external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.redeemers[l.assetTypes[asset]];
    }

    /**
     * @notice  Returns the redeemer for the given asset type
     * @dev     The redeemer is responsible for redeeming the asset from the vault
     * @param   _assetType  The type of the asset
     * @return  address  The address of the redeemer contract
     */
    function redeemerByType(
        RegistryStorage.AssetType _assetType
    ) external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.redeemers[_assetType];
    }

    /**
     * @notice  Returns the valuer for the given asset
     * @dev     The valuer is responsible for getting the value of the asset
     * @param   asset  The address of the asset
     * @return  address  The address of the valuer contract
     */
    function valuers(address asset) external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.valuers[l.assetTypes[asset]];
    }

    /**
     * @notice  Returns the valuer for the given asset type
     * @dev     The valuer is responsible for getting the value of the asset
     * @param   _assetType  The type of the asset
     * @return  address  The address of the valuer contract
     */
    function valuerByType(
        RegistryStorage.AssetType _assetType
    ) external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.valuers[_assetType];
    }

    /**
     * @notice  Returns the deprecation status of the given asset
     * @dev     Deprecated assets are not allowed to be traded into
     * @param   asset  The address of the asset to deprecate
     */
    function deprecatedAssets(address asset) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.deprecatedAssets[asset];
    }

    /**
     * @notice  Returns the hard deprecation status of the given asset
     * @dev     Hard deprecated assets cannot be valued, vaults holding them cannot be deposited into
     * @param   asset  The address of the asset to deprecate
     * @return  bool  True if the asset is deprecated
     */
    function hardDeprecatedAssets(address asset) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.hardDeprecatedAssets[asset];
    }

    /**
     * @notice  Returns if the given asset can be deposited into the vault
     * @dev     Currently only USDC/USDC.e, should only be hard stables
     * @param   asset  The address of the asset
     * @return  bool  True if the asset can be deposited
     */
    function depositAssets(address asset) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.depositAssets[asset];
    }

    /**
     * @notice  Returns the chainlink aggregator for the given asset
     * @dev     The aggregator is responsible for getting the price of the asset
     * @param   asset  The address of the asset
     * @return  IAggregatorV3Interface  The address of the chainlink aggregator
     */
    function chainlinkV3USDAggregators(
        address asset
    ) external view returns (IAggregatorV3Interface) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.chainlinkV3USDAggregators[asset];
    }

    /**
     * @notice  Returns the valioCustomAggregator for the given AggregatorType
     * @dev     A valioCustomAggregator is responsible for getting the price of the asset
     * @param   aggregatorType  The type of the aggregator
     * @return  IValioCustomAggregator  The address of the valioCustomAggregator
     */
    function valioCustomUSDAggregators(
        RegistryStorage.AggregatorType aggregatorType
    ) external view returns (IValioCustomAggregator) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.valioCustomUSDAggregators[aggregatorType];
    }

    /**
     * @notice  The max active assets a vault can have
     * @return  uint256  The maximum number of active assets
     */
    function maxActiveAssets() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.maxActiveAssets;
    }

    /**
     * @notice  The chainlink timeout
     * @dev     If the chainlink price is older than this, it is considered stale, valuing will revert
     * @return  uint256  The chainlink timeout in seconds
     */
    function chainlinkTimeout() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.chainlinkTimeout;
    }

    /**
     * @notice  The deposit lockup time
     * @dev     The deposit lockup time is the time that a deposit is locked up for.
     * @dev     This protects lps from nefarious behaviour
     * @return  uint256  The deposit lockup time in seconds
     */
    function depositLockupTime() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.depositLockupTime;
    }

    /**
     * @notice  The minimum deposit amount
     * @dev     This is the minimum amount that has to be first deposited into a holding
     * @return  uint256  The minimum deposit amount in USD (Constants.VAULT_PRECISION decimals)
     */
    function minDepositAmount() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.minDepositAmount;
    }

    /**
     * @notice  The default max deposit amount per holding
     * @dev     This is the maximum amount that can be deposited into a holding
     * @return  uint256 The maximum deposit amount in USD (Constants.VAULT_PRECISION decimals)
     */
    function maxDepositAmount() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.maxDepositAmount;
    }

    /**
     * @notice  Returns true if a manager can change manager
     * @return  bool  True if the manager can change the manager
     */
    function canChangeManager() external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.canChangeManager;
    }

    /**
     * @notice  Returns true if a manager can change manager fees
     * @return  bool  True if the manager can change the manager fees
     */
    function canChangeManagerFees() external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.canChangeManagerFees;
    }

    /**
     * @notice  Sets the liveliness threshold
     * @dev     The liveliness threshold is the time a vault value update from a child is valid for
     * @return  uint256 the livelinessThreshold time in seconds
     */
    function livelinessThreshold() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.livelinessThreshold;
    }

    /**
     * @notice  Returns the address of the 0x Exchange Router
     * @return  address  The address of the 0x Exchange Router
     */
    function zeroXExchangeRouter() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.zeroXExchangeRouter;
    }

    /**
     * @notice  Returns the list of all parentVaults
     * @return  address[]  List of all parentVaults
     */
    function vaultParentList() external view returns (address[] memory) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.parentVaultList;
    }

    /**
     * @notice  Returns the list of all childVaults
     * @return  address[]  List of all childVaults
     */
    function vaultChildList() external view returns (address[] memory) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.childVaultList;
    }

    /**
     * @notice  Returns the list of all assets
     * @return  address[]  Returns the list of all assets
     */
    function assetList() external view returns (address[] memory) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.assetList;
    }

    /**
     * @notice  Returns the configured AggregatorType for the given asset
     * @param   asset  The address of the asset
     * @return  RegistryStorage.AggregatorType  The type of the aggregator
     */
    function assetAggregatorType(
        address asset
    ) external view returns (RegistryStorage.AggregatorType) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.assetAggregatorType[asset];
    }

    /**
     * @notice  Returns the asset type for the given asset
     * @param   asset  The address of the asset
     * @return  RegistryStorage.AssetType  The type of the asset
     */
    function assetType(
        address asset
    ) external view returns (RegistryStorage.AssetType) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.assetTypes[asset];
    }

    // Contracts

    /**
     * @notice  Returns the address of the IntegrationDataTracker contract
     * @return  IntegrationDataTracker  The address of the IntegrationDataTracker contract
     */
    function integrationDataTracker()
        external
        view
        returns (IntegrationDataTracker)
    {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.integrationDataTracker;
    }

    /**
     * @notice  Returns the address of the snxPerpsV2Erc20WrapperDiamond contract
     * @dev     This is the implementation for a SnxPerpsV2Erc20Wrapper
     * @return  address  The address of the snxPerpsV2Erc20WrapperDiamond
     */
    function snxPerpsV2Erc20WrapperDiamond() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.snxPerpsV2Erc20WrapperDiamond;
    }

    /**
     * @notice Returns the address of the valio gmxConfig contract
     * @dev     Only deployed on chains that support GMX
     * @return  GmxConfig  The address of the gmxConfig contract
     */
    function gmxConfig() external view returns (GmxConfig) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.gmxConfig;
    }

    /**
     * @notice  Returns the address of the valio snxConfig contract
     * @dev     Only deployed on chains that support SNX
     * @return  SnxConfig  The address of the snxConfig contract
     */
    function snxConfig() external view returns (SnxConfig) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.snxConfig;
    }

    /**
     * @notice  Returns the address of the accountant contract
     * @return  Accountant  The address of the accountant contract
     */
    function accountant() external view returns (Accountant) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.accountant;
    }

    /**
     * @notice  Returns the address of the transport contract
     * @return  Transport  The address of the transport contract
     */
    function transport() external view returns (Transport) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.transport;
    }

    /**
     * @notice  Returns the precision of the vault
     * @dev     Aka Decimals
     * @return  uint256  The precision of the vault (decimals)
     */
    function VAULT_PRECISION() external pure returns (uint256) {
        return Constants.VAULT_PRECISION;
    }

    /**
     * @notice  Emit event that informs that the another event was emitted on the target address
     * @param   caller  The address of the caller
     */
    function _emitEvent(address caller) internal {
        emit EventEmitted(caller);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Accountant } from '../Accountant.sol';
import { Transport } from '../transport/Transport.sol';
import { ExecutorIntegration } from '../executors/IExecutor.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';
import { IntegrationDataTracker } from '../integration-data-tracker/IntegrationDataTracker.sol';
import { GmxConfig } from '../GmxConfig.sol';
import { SnxConfig } from '../SnxConfig.sol';
import { ILayerZeroEndpoint } from '@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol';
import { IAggregatorV3Interface } from '../interfaces/IAggregatorV3Interface.sol';
import { IWETH } from '../interfaces/IWeth.sol';
import { IValioCustomAggregator } from '../aggregators/IValioCustomAggregator.sol';

import { IUniswapV3Pool } from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

library RegistryStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.Registry');

    // Cannot use struct with diamond storage,
    // as adding any extra storage slots will break the following already declared members
    // solhint-disable-next-line ordering
    struct VaultSettings {
        bool ___deprecated;
        uint ____deprecated;
        uint _____deprecated;
        uint ______deprecated;
    }

    // solhint-disable-next-line ordering
    enum AssetType {
        None,
        GMX,
        Erc20,
        SnxPerpsV2
    }

    // solhint-disable-next-line ordering
    enum AggregatorType {
        ChainlinkV3USD,
        UniswapV3Twap,
        VelodromeV2Twap,
        None, // Things like gmx return a value in usd so no aggregator is needed
        SynthetixConversion,
        AlgebraFinanceV19Twap
    }

    struct PoolConfig {
        address pool;
        address pairToken;
    }

    // solhint-disable-next-line ordering
    struct Layout {
        uint16 chainId;
        address protocolTreasury;
        address parentVaultDiamond;
        address childVaultDiamond;
        mapping(address => bool) parentVaults;
        mapping(address => bool) childVaults;
        VaultSettings _deprecated;
        Accountant accountant;
        Transport transport;
        IntegrationDataTracker integrationDataTracker;
        GmxConfig gmxConfig;
        mapping(ExecutorIntegration => address) executors;
        // Price get will revert if the price hasn't be updated in the below time
        uint256 chainlinkTimeout;
        mapping(AssetType => address) valuers;
        mapping(AssetType => address) redeemers;
        mapping(address => AssetType) assetTypes;
        // All must return USD price and be 8 decimals
        mapping(address => IAggregatorV3Interface) chainlinkV3USDAggregators;
        mapping(address => bool) deprecatedAssets; // Assets that cannot be traded into, only out of
        address zeroXExchangeRouter;
        uint DEPRECATED_zeroXMaximumSingleSwapPriceImpactBips;
        bool canChangeManager;
        // The number of assets that can be active at once for a vault
        // This is important so withdraw processing doesn't consume > max gas
        uint maxActiveAssets;
        uint depositLockupTime;
        uint livelinessThreshold;
        mapping(VaultRiskProfile => uint) maxCpitBips;
        uint DEPRECATED_maxSingleActionImpactBips;
        uint minDepositAmount;
        bool canChangeManagerFees;
        // Assets that can be deposited into the vault
        mapping(address => bool) depositAssets;
        uint vaultValueCap;
        bool DEPRECATED_managerWhitelistEnabled;
        mapping(address => bool) DEPRECATED_allowedManagers;
        bool DEPRECATED_investorWhitelistEnabled;
        mapping(address => bool) DEPRECATED_allowedInvestors;
        address withdrawAutomator;
        mapping(address => IValioCustomAggregator) DEPRECATED_valioCustomUSDAggregators;
        address[] parentVaultList;
        address[] childVaultList;
        address[] assetList;
        uint maxDepositAmount;
        uint protocolFeeBips;
        mapping(address => AggregatorType) assetAggregatorType;
        // All must return USD price and be 8 decimals
        mapping(AggregatorType => IValioCustomAggregator) valioCustomUSDAggregators;
        address depositAutomator;
        SnxConfig snxConfig;
        address snxPerpsV2Erc20WrapperDiamond;
        mapping(address => uint) customVaultValueCaps;
        address[] snxPerpsV2Erc20WrapperList;
        // hardDeprecatedAssets Assets will return a value of 0
        // hardDeprecatedAssets Assets that cannot be traded into, only out of
        // A vault holding hardDeprecatedAssets will not be able be deposited into
        mapping(address => bool) hardDeprecatedAssets;
        mapping(address => PoolConfig) assetToPoolConfig;
        IWETH wrappedNativeToken; // weth, wmatic etc
        mapping(address => bool) isWrappedNativeToken;
        mapping(bytes32 => address) ancillaryContractAddresses;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ISnxAddressResolver } from './interfaces/ISnxAddressResolver.sol';

/**
 * @title   SnxConfig
 * @dev     Used to store addresses and configuration values for the SNX system.
 * @notice  Ref stored in the regsitry, Only deployed on chains that support snx
 */

contract SnxConfig {
    bytes32 public immutable trackingCode;
    ISnxAddressResolver public immutable addressResolver;
    address public immutable perpsV2MarketData;
    uint8 public immutable maxPerpPositions;

    constructor(
        address _addressResolver,
        address _perpsV2MarketData,
        bytes32 _snxTrackingCode,
        uint8 _maxPerpPositions
    ) {
        addressResolver = ISnxAddressResolver(_addressResolver);
        // https://github.com/Synthetixio/synthetix/blob/master/contracts/PerpsV2MarketData.sol
        perpsV2MarketData = _perpsV2MarketData;
        trackingCode = _snxTrackingCode;
        maxPerpPositions = _maxPerpPositions;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';

enum GasFunctionType {
    standardNoReturnMessage,
    createChildRequiresReturnMessage,
    getVaultValueRequiresReturnMessage,
    withdrawRequiresReturnMessage,
    sgReceiveRequiresReturnMessage,
    sendBridgeApprovalNoReturnMessage,
    childCreatedNoReturnMessage
}

/**
 * @title   ITransport
 * @dev     Interface containing expected external functions of the Transport Contract
 */

interface ITransport {
    struct SGReceivePayload {
        address dstVault;
        address srcVault;
        uint16 parentChainId;
        address parentVault;
    }

    struct SGBridgedAssetReceivedAcknoledgementRequest {
        uint16 parentChainId;
        address parentVault;
        uint16 receivingChainId;
    }

    struct ChildVault {
        uint16 chainId;
        address vault;
    }

    struct VaultChildCreationRequest {
        address parentVault;
        uint16 parentChainId;
        uint16 newChainId;
        address manager;
        VaultRiskProfile riskProfile;
        ChildVault[] children;
    }

    struct ChildCreatedRequest {
        address parentVault;
        uint16 parentChainId;
        ChildVault newChild;
    }

    struct AddVaultSiblingRequest {
        ChildVault child;
        ChildVault newSibling;
    }

    struct BridgeApprovalRequest {
        uint16 approvedChainId;
        address approvedVault;
    }

    struct BridgeApprovalCancellationRequest {
        uint16 parentChainId;
        address parentVault;
        address requester;
    }

    struct ValueUpdateRequest {
        uint16 parentChainId;
        address parentVault;
        ChildVault child;
    }

    struct ValueUpdatedRequest {
        uint16 parentChainId;
        address parentVault;
        ChildVault child;
        uint time;
        uint minValue;
        uint maxValue;
        bool hasHardDepreactedAsset;
    }

    struct WithdrawRequest {
        uint16 parentChainId;
        address parentVault;
        ChildVault child;
        uint tokenId;
        address withdrawer;
        uint portion;
    }

    struct WithdrawComplete {
        uint16 parentChainId;
        address parentVault;
    }

    struct ChangeManagerRequest {
        ChildVault child;
        address newManager;
    }

    event VaultChildCreated(address target);
    event VaultParentCreated(address target);

    receive() external payable;

    function addSibling(AddVaultSiblingRequest memory request) external;

    function bridgeApproval(BridgeApprovalRequest memory request) external;

    function bridgeApprovalCancellation(
        BridgeApprovalCancellationRequest memory request
    ) external;

    function bridgeAsset(
        uint16 dstChainId,
        address dstVault,
        uint16 parentChainId,
        address parentVault,
        address bridgeToken,
        uint256 amount,
        uint256 minAmountOut
    ) external payable;

    function childCreated(ChildCreatedRequest memory request) external;

    function createVaultChild(
        VaultChildCreationRequest memory request
    ) external;

    function createParentVault(
        string memory name,
        string memory symbol,
        address manager,
        uint streamingFee,
        uint performanceFee,
        VaultRiskProfile riskProfile
    ) external payable returns (address deployment);

    function sendChangeManagerRequest(
        ChangeManagerRequest memory request
    ) external payable;

    function sendAddSiblingRequest(
        AddVaultSiblingRequest memory request
    ) external;

    function sendBridgeApproval(
        BridgeApprovalRequest memory request
    ) external payable;

    function sendBridgeApprovalCancellation(
        BridgeApprovalCancellationRequest memory request
    ) external payable;

    function sendVaultChildCreationRequest(
        VaultChildCreationRequest memory request
    ) external payable;

    function sendWithdrawRequest(
        WithdrawRequest memory request
    ) external payable;

    function sendValueUpdateRequest(
        ValueUpdateRequest memory request
    ) external payable;

    function updateVaultValue(ValueUpdatedRequest memory request) external;

    function getLzFee(
        GasFunctionType gasFunctionType,
        uint16 dstChainId
    ) external returns (uint256 sendFee, bytes memory adapterParams);

    // onlyThis
    function changeManager(ChangeManagerRequest memory request) external;

    function withdraw(WithdrawRequest memory request) external;

    function withdrawComplete(WithdrawComplete memory request) external;

    function getVaultValue(ValueUpdateRequest memory request) external;

    function sgBridgedAssetReceived(
        SGBridgedAssetReceivedAcknoledgementRequest memory request
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { TransportReceive } from './TransportReceive.sol';
import { TransportStargate } from './TransportStargate.sol';

/**
 * @title   Transport
 * @dev     The contract that proxies/routes all messages to and from vaults to the GMP protocol.
 * @dev     It looks after the serialisation and deserialisation of messages.
 * @dev     It also includes the logic for asset bridging. Currently Stargage.
 * @dev     Transport is a Diamond and is composed of:
 * @dev     TransportBase, TransportReceive, TransportSend, TransportStargate
 * @notice  Currently we use LayerZero as the message passing provider, but this can be changed.
 */
contract Transport is TransportReceive, TransportStargate {

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ITransport, GasFunctionType } from './ITransport.sol';
import { VaultParentProxy } from '../vault-parent/VaultParentProxy.sol';
import { VaultParent } from '../vault-parent/VaultParent.sol';

import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';
import { Registry } from '../registry/Registry.sol';
import { TransportStorage } from './TransportStorage.sol';

import { ILayerZeroEndpoint } from '@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol';

import { SafeOwnable } from '@solidstate/contracts/access/ownable/SafeOwnable.sol';

/**
 * @title   TransportBase
 * @notice  Acts as the base for the rest of the TransportLogic
 * @dev     Includes all setters/getters for storage, shared modifiers and createVault/CreateChildVault logic
 */
abstract contract TransportBase is SafeOwnable, ITransport {
    modifier onlyVault() {
        require(_registry().isVault(msg.sender), 'not vault');
        _;
    }

    modifier whenNotPaused() {
        require(!_registry().paused(), 'paused');
        _;
    }

    receive() external payable {}

    /**
     * @notice  Sets the required storage variables for the contract
     * @param   __registry  The valio registry
     * @param   __lzEndpoint  The LayerZero endpoint
     * @param   __stargateRouter  The stargate router
     */
    function initialize(
        address __registry,
        address __lzEndpoint,
        address __stargateRouter
    ) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.registry = Registry(__registry);
        l.lzEndpoint = ILayerZeroEndpoint(__lzEndpoint);
        l.stargateRouter = __stargateRouter;
    }

    /**
     * @notice  Creates a Parent vault and returns the address
     * @dev     This should be moved to the Registry
     * @param   name  The name of the vault
     * @param   symbol  The ticker symbol of the vault
     * @param   manager  The manager of the vault
     * @param   streamingFee  The management fee
     * @param   performanceFee  The performanceFee
     * @param   riskProfile  The risk profile of the vault
     * @return  deployment  The address of the created vault
     */
    function createParentVault(
        string memory name,
        string memory symbol,
        address manager,
        uint streamingFee,
        uint performanceFee,
        VaultRiskProfile riskProfile
    ) external payable whenNotPaused returns (address deployment) {
        require(msg.value >= _vaultCreationFee(), 'insufficient fee');
        (bool sent, ) = _registry().protocolTreasury().call{ value: msg.value }(
            ''
        );
        require(sent, 'Failed to process create vault fee');
        return
            _createParentVault(
                name,
                symbol,
                manager,
                streamingFee,
                performanceFee,
                riskProfile
            );
    }

    /**
     * @notice  Sets the TrustedRemoteAddress for a given chain id
     * @dev     This is the Transport on another Chain
     * @dev     This is concatenated with the address of this contract
     * @param   _remoteChainId  the destination chain id
     * @param   _remoteAddress  the address of the remote Transport
     */
    function setTrustedRemoteAddress(
        uint16 _remoteChainId,
        bytes calldata _remoteAddress
    ) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.trustedRemoteLookup[_remoteChainId] = abi.encodePacked(
            _remoteAddress,
            address(this)
        );
    }

    /**
     * @notice  Sets the Source Chain Pool Id for a given asset
     * @dev     https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
     * @param   asset  The address of the erc20 bridgable asset
     * @param   poolId  The source chain stargate poolId for the asset
     */
    function setSGAssetToSrcPoolId(
        address asset,
        uint poolId
    ) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.stargateAssetToSrcPoolId[asset] = poolId;
    }

    /**
     * @notice  Sets the Destination Chain Pool Id for a given asset
     * @dev     https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
     * @param   chainId  The destination chain id
     * @param   asset  The address of the erc20 bridgable asset (the address on the source chain)
     * @param   poolId  The destination chain stargate poolId for the asset
     */
    function setSGAssetToDstPoolId(
        uint16 chainId,
        address asset,
        uint poolId
    ) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.stargateAssetToDstPoolId[chainId][asset] = poolId;
    }

    /**
     * @notice  Sets the gas consumption for the given function type
     * @dev     This is how much destination gas will be sent for a given function
     * @param   chainId  The destination chain id
     * @param   gasUsageType  The function type
     * @param   gas  The amount of gas the function will use
     */
    function setGasUsage(
        uint16 chainId,
        GasFunctionType gasUsageType,
        uint gas
    ) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.gasUsage[chainId][gasUsageType] = gas;
    }

    /**
     * @notice  Sets the return message cost for the given chain id
     * @dev     This is how much the destination chain will be charged for a return message
     * @dev     This amount will be included with the src chain message to pay for the reply
     * @param   chainId  The destination chain id
     * @param   cost  The amount in destination chain native token (currently only eth)
     */
    function setReturnMessageCost(
        uint16 chainId,
        uint cost
    ) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.returnMessageCosts[chainId] = cost;
    }

    /**
     * @notice  Sets the amount of time that has to pass before a bridge can be cancelled by anyone
     * @dev     This stops managers from being able to block withdraws. It is a safety mechanism.
     * @param   time  the amount of time in seconds
     */
    function setBridgeApprovalCancellationTime(uint time) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.bridgeApprovalCancellationTime = time;
    }

    /**
     * @notice  The fee charged to create a ParentVault
     * @param   fee  The fee in the native token
     */
    function setVaultCreationFee(uint fee) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.vaultCreationFee = fee;
    }

    /**
     * @notice  Returns the valio registry
     * @return  Registry  the valio registry
     */
    function registry() external view returns (Registry) {
        return _registry();
    }

    /**
     * @notice  Returns the amount of time that has to pass before a bridge can be cancelled by anyone
     * @return  time  the amount of time in seconds
     */
    function bridgeApprovalCancellationTime() external view returns (uint256) {
        return _bridgeApprovalCancellationTime();
    }

    /**
     * @notice  Returns the LayerZero endpoint
     * @return  ILayerZeroEndpoint  the LayerZero endpoint
     */
    function lzEndpoint() external view returns (ILayerZeroEndpoint) {
        return _lzEndpoint();
    }

    /**
     * @notice  Returns the trusted remote address for a given chain id
     * @dev     This is the address that is allowed to send messages to this chain
     * @dev     LayerZeros srcAddress is concatenates the from address and the to address
     * @param   remoteChainId  The destination chain id
     * @return  bytes  the trusted remote address (remoteAddress + address(this))
     */
    function trustedRemoteLookup(
        uint16 remoteChainId
    ) external view returns (bytes memory) {
        return _trustedRemoteLookup(remoteChainId);
    }

    /**
     * @notice  Returns the stargate router
     * @return  address  the stargate router
     */
    function stargateRouter() external view returns (address) {
        return _stargateRouter();
    }

    /**
     * @notice  Returns the destination pool id for a given asset
     * @dev     https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
     * @param   dstChainId  The destination chainId
     * @param   srcBridgeToken  The address of the erc20 bridgable asset
     * @return  uint  the destination pool id
     */
    function stargateAssetToDstPoolId(
        uint16 dstChainId,
        address srcBridgeToken
    ) external view returns (uint256) {
        return _stargateAssetToDstPoolId(dstChainId, srcBridgeToken);
    }

    /**
     * @notice  Returns the source pool id for a given asset
     * @dev     https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
     * @dev     This is only used for checking configuration
     * @param   bridgeToken  The address of the erc20 bridgable asset
     * @return  uint  the source pool id
     */
    function stargateAssetToSrcPoolId(
        address bridgeToken
    ) external view returns (uint256) {
        return _stargateAssetToSrcPoolId(bridgeToken);
    }

    /**
     * @notice  Returns the gas usage for a given function type
     * @dev     Only used for checking configuration
     * @param   chainId  The destination chain id
     * @param   gasFunctionType  The function type
     * @return  uint  the amount of gas the function will use
     */
    function getGasUsage(
        uint16 chainId,
        GasFunctionType gasFunctionType
    ) external view returns (uint) {
        return _destinationGasUsage(chainId, gasFunctionType);
    }

    /**
     * @notice  Returns the return message cost for a given chain id
     * @dev     Only used for checking configuration
     * @param   chainId  The destination chain id
     * @return  uint  the amount of gas the function will use
     */
    function returnMessageCost(uint16 chainId) external view returns (uint) {
        return _returnMessageCost(chainId);
    }

    /**
     * @notice  Returns the fee charged to create a ParentVault
     * @dev     Only used for checking configuration
     * @return  uint  The fee in the native token
     */
    function vaultCreationFee() external view returns (uint) {
        return _vaultCreationFee();
    }

    /**
     * @notice  Returns the fee charged to create a ParentVault
     * @dev     Only kept for backwards compatiblity it use to be a constant
     * @return  uint  The fee in the native token
     */
    function CREATE_VAULT_FEE() external view returns (uint) {
        return _vaultCreationFee();
    }

    /**
     * @notice  Creates a Parent vault and returns the address
     * @dev     Registers the parent vault with the Registry
     * @dev     This should be moved to the Registry
     * @param   name  The name of the vault
     * @param   symbol  The ticker symbol of the vault
     * @param   manager  The manager of the vault
     * @param   streamingFee  The management fee
     * @param   performanceFee  The performanceFee
     * @param   riskProfile  The risk profile of the vault
     * @return  deployment  The address of the created vault
     */
    function _createParentVault(
        string memory name,
        string memory symbol,
        address manager,
        uint streamingFee,
        uint performanceFee,
        VaultRiskProfile riskProfile
    ) internal returns (address deployment) {
        require(
            _registry().parentVaultDiamond() != address(0),
            'not parent chain'
        );

        deployment = address(
            new VaultParentProxy(_registry().parentVaultDiamond())
        );

        VaultParent(payable(deployment)).initialize(
            name,
            symbol,
            manager,
            streamingFee,
            performanceFee,
            riskProfile,
            _registry()
        );

        _registry().addVaultParent(deployment);

        emit VaultParentCreated(deployment);
        _registry().emitEvent();
    }

    /**
     * @notice  Returns the source pool id for a given asset
     * @dev     https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
     * @dev     This is only used for checking configuration
     * @param   bridgeToken  The address of the erc20 bridgable asset
     * @return  uint  the source pool id
     */
    function _stargateAssetToSrcPoolId(
        address bridgeToken
    ) internal view returns (uint256) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.stargateAssetToSrcPoolId[bridgeToken];
    }

    /**
     * @notice  Returns the destination pool id for a given asset
     * @dev     https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
     * @param   dstChainId  The destination chainId
     * @param   srcBridgeToken  The address of the erc20 bridgable asset
     * @return  uint  the destination pool id
     */
    function _stargateAssetToDstPoolId(
        uint16 dstChainId,
        address srcBridgeToken
    ) internal view returns (uint256) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.stargateAssetToDstPoolId[dstChainId][srcBridgeToken];
    }

    /**
     * @notice  Returns the amount of time that has to pass before a bridge can be cancelled by anyone
     * @return  time  the amount of time in seconds
     */
    function _bridgeApprovalCancellationTime() internal view returns (uint256) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.bridgeApprovalCancellationTime;
    }

    /**
     * @notice  Returns the trusted remote address for a given chain id
     * @dev     This is the address that is allowed to send messages to this chain
     * @dev     LayerZeros srcAddress is concatenates the from address and the to address
     * @param   remoteChainId  The destination chain id
     * @return  bytes  the trusted remote address (remoteAddress + address(this))
     */
    function _trustedRemoteLookup(
        uint16 remoteChainId
    ) internal view returns (bytes memory) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.trustedRemoteLookup[remoteChainId];
    }

    /**
     * @notice  Returns the LayerZero endpoint
     * @return  ILayerZeroEndpoint  the LayerZero endpoint
     */
    function _lzEndpoint() internal view returns (ILayerZeroEndpoint) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.lzEndpoint;
    }

    /**
     * @notice  Returns the stargate router
     * @return  address  the stargate router
     */
    function _stargateRouter() internal view returns (address) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.stargateRouter;
    }

    /**
     * @notice  Returns the gas consumption for the given function type
     * @dev     This is how much destination gas will be sent for a given function
     * @param   chainId  The destination chain id
     * @param   gasFunctionType  The function type
     * @return  uint  the amount of gas the function will use
     */
    function _destinationGasUsage(
        uint16 chainId,
        GasFunctionType gasFunctionType
    ) internal view returns (uint) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.gasUsage[chainId][gasFunctionType];
    }

    /**
     * @notice  Returns the valio registry
     * @return  Registry  the valio registry
     */
    function _registry() internal view returns (Registry) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.registry;
    }

    /**
     * @notice  Returns the return message cost for a given chain id
     * @dev     Only used for checking configuration
     * @param   chainId  The destination chain id
     * @return  uint  the amount of gas the function will use
     */
    function _returnMessageCost(uint16 chainId) internal view returns (uint) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.returnMessageCosts[chainId];
    }

    /**
     * @notice  Returns the fee charged to create a ParentVault
     * @dev     Only used for checking configuration
     * @return  uint  The fee in the native token
     */
    function _vaultCreationFee() internal view returns (uint) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.vaultCreationFee;
    }

    /**
     * @notice  Returns the destination transport address for the given chainId
     * @dev     This extracts the address from the trustedRemoteLookup
     * @param   dstChainId  The destination chain id
     * @return  dstAddr  The fully formed destination transport address
     */
    function _getTrustedRemoteDestination(
        uint16 dstChainId
    ) internal view returns (address dstAddr) {
        bytes memory trustedRemote = _trustedRemoteLookup(dstChainId);
        require(
            trustedRemote.length != 0,
            'LzApp: destination chain is not a trusted source'
        );
        assembly {
            dstAddr := mload(add(trustedRemote, 20))
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { VaultChildProxy } from '../vault-child/VaultChildProxy.sol';
import { VaultChild } from '../vault-child/VaultChild.sol';
import { VaultParent } from '../vault-parent/VaultParent.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';

import { ILayerZeroReceiver } from '@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroReceiver.sol';

import { ITransport } from './TransportBase.sol';
import { TransportSend } from './TransportSend.sol';

import { Call } from '../lib/Call.sol';

/**
 * @title   TransportReceive
 * @notice  This contract is responsible for receiving messages from the LayerZero
 * @dev     Any messages that is required to reply, should reply from here for A->B-A communication
 */

abstract contract TransportReceive is TransportSend, ILayerZeroReceiver {
    modifier onlyThis() {
        require(address(this) == msg.sender, 'not this');
        _;
    }

    /**
     * @notice  The lzReceive function is called by the LayerZero contract
     * @dev     We don't have any use for the LzNonce because they are delivered in order
     * @param   srcChainId  the source chain id of the message
     * @param   srcAddress  this (remoteAddress + address(this))
     * @param   payload  the message payload
     */
    function lzReceive(
        uint16 srcChainId,
        bytes calldata srcAddress,
        uint64, // nonce
        bytes calldata payload
    ) external {
        require(
            msg.sender == address(_lzEndpoint()),
            'LzApp: invalid endpoint caller'
        );

        bytes memory trustedRemote = _trustedRemoteLookup(srcChainId);
        require(
            srcAddress.length == trustedRemote.length &&
                keccak256(srcAddress) == keccak256(trustedRemote),
            'LzApp: invalid source sending contract'
        );
        Call._call(address(this), payload);
    }

    ///
    /// Message received callbacks - public onlyThis
    ///

    /**
     * @notice  Receives a bridgeApprovalCancellation request
     * @dev     This means the child vault no longers wants to bridge
     * @dev     Note the `onlyThis` modifier
     * @param   request  the cancellation parameters
     */
    function bridgeApprovalCancellation(
        BridgeApprovalCancellationRequest memory request
    ) public onlyThis {
        VaultParent(payable(request.parentVault))
            .receiveBridgeApprovalCancellation(request.requester);
    }

    /**
     * @notice  Receives a bridgeApproval request
     * @dev     This means the child vault wants to bridge
     * @dev     Note the `onlyThis` modifier
     * @param   request  the approval parameters
     */
    function bridgeApproval(
        BridgeApprovalRequest memory request
    ) public onlyThis {
        VaultChild(payable(request.approvedVault)).receiveBridgeApproval();
    }

    /**
     * @notice  Receives a withdraw request
     * @dev     On success sends the withdraw complete acknowledgement back to the parent
     * @dev     Only child vaults receive these
     * @dev     Note the `onlyThis` modifier
     * @param   request  the withdraw parameters
     */
    function withdraw(WithdrawRequest memory request) public onlyThis {
        VaultChild(payable(request.child.vault)).receiveWithdrawRequest(
            request.tokenId,
            request.withdrawer,
            request.portion
        );

        sendWithdrawComplete(
            ITransport.WithdrawComplete({
                parentChainId: request.parentChainId,
                parentVault: request.parentVault
            })
        );
    }

    /**
     * @notice  Receies the withdraw complete acknoledgment
     * @dev     This is sent by the transport after a withdraw request
     * @dev     Only parent vaults receive this
     * @dev     Note the `onlyThis` modifier
     * @param   request  .
     */
    function withdrawComplete(WithdrawComplete memory request) public onlyThis {
        VaultParent(payable(request.parentVault)).receiveWithdrawComplete();
    }

    /**
     * @notice  Receives a getVaultValue request
     * @dev     This returns/replies the childs total aum to the parent
     * @dev     Note the `onlyThis` modifier
     * @param   request  the getVaultValue parameters
     */
    function getVaultValue(ValueUpdateRequest memory request) public onlyThis {
        uint256 gasRemaining = gasleft();
        try
            // This would fail if for instance chainlink feed is stale
            // If a callback fails the message is deemed failed to deliver by LZ and is queued
            // Retrying it will likely not result in a better outcome and will block message delivery
            // For other vaults
            VaultChild(payable(request.child.vault)).getVaultValue()
        returns (uint _minValue, uint _maxValue, bool _hasHardDeprecatedAsset) {
            _sendValueUpdatedRequest(
                ValueUpdatedRequest({
                    parentChainId: request.parentChainId,
                    parentVault: request.parentVault,
                    child: request.child,
                    time: block.timestamp,
                    minValue: _minValue,
                    maxValue: _maxValue,
                    hasHardDepreactedAsset: _hasHardDeprecatedAsset
                })
            );
        } catch {
            // github.com/vertex-protocol/vertex-contracts
            // /blob/3258d58eb1e56ece0513b3efcc468cc09a7414c4/contracts/Endpoint.sol#L333
            // we need to differentiate between a revert and an out of gas
            // the expectation is that because 63/64 * gasRemaining is forwarded
            // we should be able to differentiate based on whether
            // gasleft() >= gasRemaining / 64. however, experimentally
            // even more gas can be remaining, and i don't have a clear
            // understanding as to why. as a result we just err on the
            // conservative side and provide two conservative
            // asserts that should cover all cases
            // As above in practice more than 1/64th of the gas is remaining
            // The code that executes after the try { // here } requires more than 100k gas anyway
            if (gasleft() <= 100_000 || gasleft() <= gasRemaining / 16) {
                // If we revert the message will fail to deliver and need to be retried
                // In the case of out of gas we want this message to be retried by our keeper
                revert('getVaultValue out of gas');
            }
        }
    }

    /**
     * @notice  Receives a valueUpdated request
     * @dev     This means the child vault has send its updated value
     * @dev     Note the `onlyThis` modifier
     * @param   request  the valueUpdated parameters
     */
    function updateVaultValue(
        ValueUpdatedRequest memory request
    ) public onlyThis {
        VaultParent(payable(request.parentVault)).receiveChildValue(
            request.child.chainId,
            request.minValue,
            request.maxValue,
            request.time,
            request.hasHardDepreactedAsset
        );
    }

    /**
     * @notice  Receives a createVaultChild request
     * @dev     This means the parent vault wants to create a new child
     * @dev     Replies to the parent vault with the child address
     * @dev     Note the `onlyThis` modifier
     * @param   request  the createVaultChild parameters
     */
    function createVaultChild(
        VaultChildCreationRequest memory request
    ) public onlyThis {
        address child = _deployChild(
            request.parentChainId,
            request.parentVault,
            request.manager,
            request.riskProfile,
            request.children
        );
        _sendChildCreatedRequest(
            ChildCreatedRequest({
                parentVault: request.parentVault,
                parentChainId: request.parentChainId,
                newChild: ChildVault({
                    chainId: _registry().chainId(),
                    vault: child
                })
            })
        );
    }

    /**
     * @notice  Receives a childCreated request
     * @dev     This means the child vault has been created
     * @dev     Note the `onlyThis` modifier
     * @param   request  the childCreated parameters
     */
    function childCreated(ChildCreatedRequest memory request) public onlyThis {
        VaultParent(payable(request.parentVault)).receiveChildCreated(
            request.newChild.chainId,
            request.newChild.vault
        );
    }

    /**
     * @notice  Receives a addSibling request
     * @dev     This means that the parent is syndicating a new sibling to existing children
     * @dev     Note the `onlyThis` modifier
     * @param   request  the addSibling parameters
     */
    function addSibling(AddVaultSiblingRequest memory request) public onlyThis {
        VaultChild(payable(request.child.vault)).receiveAddSibling(
            request.newSibling.chainId,
            request.newSibling.vault
        );
    }

    /**
     * @notice  Receives a changeManager request
     * @dev     This means the child vault wants to change its manager
     * @param   request  the change manager parameters
     */
    function changeManager(
        ChangeManagerRequest memory request
    ) public onlyThis {
        VaultChild(payable(request.child.vault)).receiveManagerChange(
            request.newManager
        );
    }

    /**
     * @notice  Receives bridged asset acknoledgment
     * @dev     This means the child vault has received the bridge
     * @dev     Note the parent receives this even if its a Child->Child Bridge
     * @dev     Which means the bridge lock can be removed
     * @dev     Note the `onlyThis` modifier
     * @param   request  the change risk profile parameters
     */
    function sgBridgedAssetReceived(
        SGBridgedAssetReceivedAcknoledgementRequest memory request
    ) public onlyThis {
        VaultParent(payable(request.parentVault))
            .receiveBridgedAssetAcknowledgement(request.receivingChainId);
    }

    /// Deploy Child

    function _deployChild(
        uint16 parentChainId,
        address parentVault,
        address manager,
        VaultRiskProfile riskProfile,
        ITransport.ChildVault[] memory children
    ) internal whenNotPaused returns (address deployment) {
        deployment = address(
            new VaultChildProxy(_registry().childVaultDiamond())
        );
        VaultChild(payable(deployment)).initialize(
            parentChainId,
            parentVault,
            manager,
            riskProfile,
            _registry(),
            children
        );
        _registry().addVaultChild(deployment);

        emit VaultChildCreated(deployment);
        _registry().emitEvent();
    }

    function getVaultChildProxyBytecode() public pure returns (bytes memory) {
        bytes memory bytecode = type(VaultChildProxy).creationCode;
        return bytecode;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { GasFunctionType } from './ITransport.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';
import { TransportBase } from './TransportBase.sol';
import { ITransport } from './ITransport.sol';

/**
 * @title   TransportSend
 * @notice  Contains the logic that serializes and sends messages to the LayerZeroEndpoint
 * @dev     This contract is intended to be inherited by the Transport contract
 */

abstract contract TransportSend is TransportBase {
    /**
     * @notice  Only allows the message sender to be called by a VaultParent
     */
    modifier onlyVaultParent() {
        require(_registry().isVaultParent(msg.sender), 'not parent vault');
        _;
    }

    /**
     * @notice  Only allows the message sender to be called by a VaultChild
     */
    modifier onlyVaultChild() {
        require(_registry().isVaultChild(msg.sender), 'not child vault');
        _;
    }

    /**
     * @notice  Returns the lz fee for the give function
     * @dev     This exposes the cost of sending particular types of messags to the vault
     * @param   gasFunctionType  The type of message being sent
     * @param   dstChainId  The destination lz chain id
     * @return  sendFee  The lz fee for the message + destination gas
     * @return  adapterParams  The lz send parameters (dest gas, native amount)
     */
    function getLzFee(
        GasFunctionType gasFunctionType,
        uint16 dstChainId
    ) external view returns (uint256 sendFee, bytes memory adapterParams) {
        return _getLzFee(gasFunctionType, dstChainId);
    }

    ///
    /// Message senders
    ///
    /**
     * @notice  Sends a change manager request to the destination vault
     * @dev     This function is only callable by a VaultParent
     * @param   request  The change manager request
     */
    // solhint-disable-next-line ordering
    function sendChangeManagerRequest(
        ChangeManagerRequest memory request
    ) external payable whenNotPaused onlyVaultParent {
        _send(
            request.child.chainId,
            abi.encodeCall(ITransport.changeManager, (request)),
            msg.value,
            _getAdapterParams(
                request.child.chainId,
                GasFunctionType.standardNoReturnMessage
            )
        );
    }

    /**
     * @notice  Sends a withdraw request to the destination vault
     * @dev     This function is only callable by a VaultParent
     * @dev     Once the withdraw is processed the childVault will send a withdrawComplete message
     * @param   request  The withdraw request
     */
    function sendWithdrawRequest(
        WithdrawRequest memory request
    ) external payable whenNotPaused onlyVaultParent {
        _send(
            request.child.chainId,
            abi.encodeCall(ITransport.withdraw, (request)),
            msg.value,
            _getAdapterParams(
                request.child.chainId,
                GasFunctionType.withdrawRequiresReturnMessage
            )
        );
    }

    /**
     * @notice  Sends a bridge approval request to a child vault
     * @dev     This function is only callable by a VaultParent
     * @dev     The VaultParent must know the VaultChild is going to bridge, as assets will be inflight
     * @dev     We block deposits(syncs) and withdraws while assets are in flight
     * @param   request  The bridge approval request
     */
    function sendBridgeApproval(
        BridgeApprovalRequest memory request
    ) external payable whenNotPaused onlyVaultParent {
        _send(
            request.approvedChainId,
            abi.encodeCall(ITransport.bridgeApproval, (request)),
            msg.value,
            _getAdapterParams(
                request.approvedChainId,
                GasFunctionType.sendBridgeApprovalNoReturnMessage
            )
        );
    }

    /**
     * @notice  Sends a bridge approval cancellation request to the parent
     * @dev     This function is only callable by a VaultChild
     * @param   request  The bridge approval cancellation request
     */
    function sendBridgeApprovalCancellation(
        BridgeApprovalCancellationRequest memory request
    ) external payable whenNotPaused onlyVaultChild {
        _send(
            request.parentChainId,
            abi.encodeCall(ITransport.bridgeApprovalCancellation, (request)),
            msg.value,
            _getAdapterParams(
                request.parentChainId,
                GasFunctionType.standardNoReturnMessage
            )
        );
    }

    /**
     * @notice  Sends a value update request to the destination vault
     * @dev     When the childVault receives this it will send a valueUpdated message
     * @dev     This function is only callable by a VaultParent
     * @param   request  The value update request
     */
    function sendValueUpdateRequest(
        ValueUpdateRequest memory request
    ) external payable whenNotPaused onlyVaultParent {
        _send(
            request.child.chainId,
            abi.encodeCall(ITransport.getVaultValue, (request)),
            msg.value,
            _getAdapterParams(
                request.child.chainId,
                GasFunctionType.getVaultValueRequiresReturnMessage
            )
        );
    }

    /**
     * @notice  Sends a create child vault request to the destination chain transport
     * @dev     The transport will construct the child vault and send back the childCreated message
     * @param   request  The create child vault request
     */
    function sendVaultChildCreationRequest(
        VaultChildCreationRequest memory request
    ) external payable whenNotPaused onlyVaultParent {
        require(
            _getTrustedRemoteDestination(request.newChainId) != address(0),
            'unsupported destination chain'
        );
        _send(
            request.newChainId,
            abi.encodeCall(ITransport.createVaultChild, (request)),
            msg.value,
            _getAdapterParams(
                request.newChainId,
                GasFunctionType.createChildRequiresReturnMessage
            )
        );
    }

    /// Return/Reply message senders

    /**
     * @notice  Sends an add sibling request to a child vault
     * @dev     This function is only callable by a VaultParent
     * @dev     When the VaultParent is notified there is a new childVault it syndicates it to the other childVaults
     * @param   request  The add sibling request
     */
    function sendAddSiblingRequest(
        AddVaultSiblingRequest memory request
    ) external whenNotPaused onlyVaultParent {
        (uint fee, bytes memory adapterParams) = _getLzFee(
            GasFunctionType.standardNoReturnMessage,
            request.child.chainId
        );
        _send(
            request.child.chainId,
            abi.encodeCall(ITransport.addSibling, (request)),
            fee,
            adapterParams
        );
    }

    /**
     * @notice  Sends a withdraw complete message to the parent vault
     * @dev     Should only be called by the tranport when a withdrawRequest is completed
     * @param   request  The withdraw complete message
     */
    function sendWithdrawComplete(WithdrawComplete memory request) internal {
        (uint fee, bytes memory adapterParams) = _getLzFee(
            GasFunctionType.standardNoReturnMessage,
            request.parentChainId
        );
        _send(
            request.parentChainId,
            abi.encodeCall(ITransport.withdrawComplete, (request)),
            fee,
            adapterParams
        );
    }

    /**
     * @notice  Sends a ValueUpdatedRequest to the parent vault
     * @dev     This function should be called by the transport when it receives a ValueUpdateRequest from the parent
     * @dev     This has bad naming.
     * @param   request  The value updated request
     */
    function _sendValueUpdatedRequest(
        ValueUpdatedRequest memory request
    ) internal {
        (uint fee, bytes memory adapterParams) = _getLzFee(
            GasFunctionType.standardNoReturnMessage,
            request.parentChainId
        );
        _send(
            request.parentChainId,
            abi.encodeCall(ITransport.updateVaultValue, (request)),
            fee,
            adapterParams
        );
    }

    /**
     * @notice  Sends a bridgeAssetAcknowledgment to the parent vault
     * @dev     This means the child vault has received the asset and the bridge lock can be reliquished
     * @param   request  The bridge asset acknowledgment
     */
    function _sendSGBridgedAssetAcknowledment(
        SGBridgedAssetReceivedAcknoledgementRequest memory request
    ) internal {
        (uint fee, bytes memory adapterParams) = _getLzFee(
            GasFunctionType.standardNoReturnMessage,
            request.parentChainId
        );
        _send(
            request.parentChainId,
            abi.encodeCall(ITransport.sgBridgedAssetReceived, (request)),
            fee,
            adapterParams
        );
    }

    /**
     * @notice  Sends a childCreatedRequest to the parent vault
     * @dev     This function should be called by the transport when it executes a createChildRequest
     * @dev     Notifies the parent vault that a new child vault has been created
     * @param   request  The child created request
     */
    function _sendChildCreatedRequest(
        ChildCreatedRequest memory request
    ) internal {
        (uint fee, bytes memory adapterParams) = _getLzFee(
            GasFunctionType.childCreatedNoReturnMessage,
            request.parentChainId
        );
        _send(
            request.parentChainId,
            abi.encodeCall(ITransport.childCreated, (request)),
            fee,
            adapterParams
        );
    }

    /// Internal

    /**
     * @notice  Sends a message to the LayerZeroEndpoint
     * @dev     This function is used to send messages to the LayerZeroEndpoint
     * @param   dstChainId  The destination lz chain id
     * @param   payload  The encoded function calldata with selector, to be called on the destination transport
     * @param   sendFee  The cost to send the message
     * @param   adapterParams  The lz send parameters (dest gas, native amount)
     */
    function _send(
        uint16 dstChainId,
        bytes memory payload,
        uint sendFee,
        bytes memory adapterParams
    ) internal {
        require(
            address(this).balance >= sendFee,
            'Transport: insufficient balance'
        );
        _lzEndpoint().send{ value: sendFee }(
            dstChainId,
            _trustedRemoteLookup(dstChainId),
            payload,
            payable(address(this)),
            payable(address(this)),
            adapterParams
        );
    }

    /**
     * @notice  Returns the lz fee for the give function
     * @dev     This exposes the cost of sending particular types of messags to the vault
     * @param   gasFunctionType  The type of message being sent
     * @param   dstChainId  The destination lz chain id
     * @return  sendFee  The lz fee for the message + destination gas
     * @return  adapterParams  The lz send parameters (dest gas, native amount)
     */
    function _getLzFee(
        GasFunctionType gasFunctionType,
        uint16 dstChainId
    ) internal view returns (uint256 sendFee, bytes memory adapterParams) {
        // We just use the largest message for now
        ChildVault memory childVault = ChildVault({
            chainId: 0,
            vault: address(0)
        });
        ChildVault[] memory childVaults = new ChildVault[](2);
        childVaults[0] = childVault;
        childVaults[1] = childVault;

        VaultChildCreationRequest memory request = VaultChildCreationRequest({
            parentVault: address(0),
            parentChainId: 0,
            newChainId: 0,
            manager: address(0),
            riskProfile: VaultRiskProfile.low,
            children: childVaults
        });

        bytes memory payload = abi.encodeCall(
            this.sendVaultChildCreationRequest,
            (request)
        );

        address dstAddr = _getTrustedRemoteDestination(dstChainId);

        adapterParams = _getAdapterParams(dstChainId, gasFunctionType);

        (sendFee, ) = _lzEndpoint().estimateFees(
            dstChainId,
            dstAddr,
            payload,
            false,
            adapterParams
        );
    }

    /**
     * @notice  Given the functionType returns if a return message is required
     * @dev     I.E ValueUpdateRequest, WithdrawRequest require a return message
     * @param   gasFunctionType  .
     * @return  bool  .
     */
    function _requiresReturnMessage(
        GasFunctionType gasFunctionType
    ) internal pure returns (bool) {
        if (
            gasFunctionType == GasFunctionType.standardNoReturnMessage ||
            gasFunctionType ==
            GasFunctionType.sendBridgeApprovalNoReturnMessage ||
            gasFunctionType == GasFunctionType.childCreatedNoReturnMessage
        ) {
            return false;
        }
        return true;
    }

    /**
     * @notice  Returns the lz adapter params for the given function type
     * @dev     This includes destination gas, return message cost, and gas receiver
     * @param   dstChainId  The destination lz chain id
     * @param   gasFunctionType  The type of message being sent
     * @return  bytes  The lz adapter params
     */
    function _getAdapterParams(
        uint16 dstChainId,
        GasFunctionType gasFunctionType
    ) internal view returns (bytes memory) {
        bool requiresReturnMessage = _requiresReturnMessage(gasFunctionType);
        return
            abi.encodePacked(
                uint16(2),
                // The amount of gas the destination consumes when it receives the messaage
                _destinationGasUsage(dstChainId, gasFunctionType),
                // Amount to Airdrop to the remote transport
                requiresReturnMessage ? _returnMessageCost(dstChainId) : 0,
                // Gas Receiver
                requiresReturnMessage
                    ? _getTrustedRemoteDestination(dstChainId)
                    : address(0)
            );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';
import { VaultBaseExternal } from '../vault-base/VaultBaseExternal.sol';

import { IStargateRouter } from '@layerzerolabs/solidity-examples/contracts/interfaces/IStargateRouter.sol';
import { IStargateReceiver } from '@layerzerolabs/solidity-examples/contracts/interfaces/IStargateReceiver.sol';

import { TransportReceive } from './TransportReceive.sol';
import { GasFunctionType } from './ITransport.sol';

/**
 * @title   TransportStargate
 * @notice  Contains the Transport logic for interfacing  with Stargate
 * @dev     Stargate is the current bridge provider
 * @dev     Note: funds are bridged between transports, the transports forward the funds to the vault
 */

abstract contract TransportStargate is TransportReceive, IStargateReceiver {
    using SafeERC20 for IERC20;

    /**
     * @notice  The stargate callback
     * @dev     The stargate the destination contract must implement this function to receive the tokens and payload
     * @dev     The receiver is a childVault we immediately send a Bridge Acknoledgement message to the parent
     * @dev     This means the parent can remove the BridgeInProgressLock
     * @param   _srcChainId  The source chain id
     * @param   _srcAddress  We use Stargate Composer which forwards the senders address, must be source chain transport
     * @param   _token  The token bridged
     * @param   _amountLD  The amount of the above token
     * @param   _payload  the payload
     */
    function sgReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint, // Nonce
        address _token,
        uint _amountLD,
        bytes memory _payload
    ) external override {
        require(msg.sender == _stargateRouter(), 'only stargate router');

        address trustedRemote = _getTrustedRemoteDestination(_srcChainId);

        // The source of the bridge must be the related Vault via the Transport
        // Otherwise someone could spoof this call by bridging directly to the transport
        require(
            trustedRemote == address(uint160(bytes20(_srcAddress))),
            'untrusted remote'
        );

        SGReceivePayload memory payload = abi.decode(
            _payload,
            (SGReceivePayload)
        );
        // send transfer _token/amountLD to _toAddr
        IERC20(_token).safeTransfer(payload.dstVault, _amountLD);
        VaultBaseExternal(payable(payload.dstVault)).receiveBridgedAsset(
            _token
        );
        // Already on the parent chain - no need to send a message
        if (_registry().chainId() == payload.parentChainId) {
            this.sgBridgedAssetReceived(
                SGBridgedAssetReceivedAcknoledgementRequest({
                    parentChainId: payload.parentChainId,
                    parentVault: payload.parentVault,
                    receivingChainId: payload.parentChainId
                })
            );
        } else {
            _sendSGBridgedAssetAcknowledment(
                SGBridgedAssetReceivedAcknoledgementRequest({
                    parentChainId: payload.parentChainId,
                    parentVault: payload.parentVault,
                    receivingChainId: _registry().chainId()
                })
            );
        }
    }

    /**
     * @notice  Bridges an asset to a destination vault
     * @dev     Constructs the sgReceive Payload to be sent with the bridged asset
     * @param   dstChainId  The lz chainId of the destination
     * @param   dstVault  The address of the destination vault
     * @param   parentChainId  The lz chainId of the parentVault
     * @param   parentVault  The address of the parentVault
     * @param   bridgeToken  The address of the token to bridge
     * @param   amount  The amount of tokens to bridge
     * @param   minAmountOut  The minimum amount of tokens to receive
     */
    function bridgeAsset(
        uint16 dstChainId,
        address dstVault,
        uint16 parentChainId,
        address parentVault,
        address bridgeToken,
        uint amount,
        uint minAmountOut
    ) external payable whenNotPaused onlyVault {
        require(amount > 0, 'error: swap() requires amount > 0');
        address dstAddr = _getTrustedRemoteDestination(dstChainId);

        uint srcPoolId = _stargateAssetToSrcPoolId(bridgeToken);
        uint dstPoolId = _stargateAssetToDstPoolId(dstChainId, bridgeToken);
        require(srcPoolId != 0, 'no srcPoolId');
        require(dstPoolId != 0, 'no dstPoolId');

        // encode payload data to send to destination contract, which it will handle with sgReceive()
        bytes memory data = abi.encode(
            SGReceivePayload({
                dstVault: dstVault,
                srcVault: msg.sender,
                parentChainId: parentChainId,
                parentVault: parentVault
            })
        );

        IStargateRouter.lzTxObj memory lzTxObj = _getStargateTxObj(
            dstChainId,
            dstAddr,
            parentChainId
        );

        IERC20(bridgeToken).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(bridgeToken).safeApprove(_stargateRouter(), amount);

        // Stargate's Router.swap() function sends the tokens to the destination chain.
        IStargateRouter(_stargateRouter()).swap{ value: msg.value }(
            dstChainId, // the destination chain id
            srcPoolId, // the source Stargate poolId
            dstPoolId, // the destination Stargate poolId
            payable(address(this)), // refund adddress. if msg.sender pays too much gas, return extra eth
            amount, // total tokens to send to destination chain
            minAmountOut, // min amount allowed out
            lzTxObj, // default lzTxObj
            abi.encodePacked(dstAddr), // destination address, the sgReceive() implementer
            data // bytes payload
        );
    }

    /**
     * @notice  Returns the fee to bridge an asset to a destination vault
     * @dev     The fee is calculated by the Stargate Router
     * @param   dstChainId  the chainId of the destination
     * @param   dstVault  the address of the destination vault
     * @param   parentChainId  the chainId of the parentVault
     * @param   parentVault  the address of the parentVault
     * @return  fee  the fee to bridge the asset
     */
    function getBridgeAssetQuote(
        uint16 dstChainId,
        address dstVault,
        uint16 parentChainId,
        address parentVault
    ) external view returns (uint fee) {
        address dstAddr = _getTrustedRemoteDestination(dstChainId);

        // Mock payload for quote
        bytes memory data = abi.encode(
            SGReceivePayload({
                dstVault: dstVault,
                srcVault: msg.sender,
                parentChainId: parentChainId,
                parentVault: parentVault
            })
        );

        IStargateRouter.lzTxObj memory lzTxObj = _getStargateTxObj(
            dstChainId,
            dstAddr,
            parentChainId
        );

        (fee, ) = IStargateRouter(_stargateRouter()).quoteLayerZeroFee(
            dstChainId,
            1, // function type: see Stargate Bridge.sol for all types
            abi.encodePacked(dstAddr), // destination contract. it must implement sgReceive()
            data,
            lzTxObj
        );
    }

    /**
     * @notice  Returns the stargate lz transaction parameters
     * @dev     Includes the destination gas for the sgReceive
     * @dev     and the native token  to deliver for the return BridgeAcknowledge message
     * @param   dstChainId  the chainId of the destination
     * @param   dstTransportAddress  the address of the destination transport
     * @param   parentChainId  the chainId of the parentVault (no return message req if the dstChain is parentChain)
     * @return  lzTxObj the lz transaction params object
     */
    function _getStargateTxObj(
        uint16 dstChainId,
        address dstTransportAddress,
        uint16 parentChainId
    ) internal view returns (IStargateRouter.lzTxObj memory lzTxObj) {
        uint DST_GAS = _destinationGasUsage(
            dstChainId,
            GasFunctionType.sgReceiveRequiresReturnMessage
        );
        return
            IStargateRouter.lzTxObj({
                ///
                /// This needs to be enough for the sgReceive to execute successfully on the remote
                /// We will need to accurately access how much the Transport.sgReceive function needs
                ///
                dstGasForCall: DST_GAS,
                // Once the receiving vault receives the bridge the transport sends a message to the parent
                // If the dstChain is the parentChain no return message is required
                dstNativeAmount: dstChainId == parentChainId
                    ? 0
                    : _returnMessageCost(dstChainId),
                dstNativeAddr: abi.encodePacked(dstTransportAddress)
            });
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Registry } from '../registry/Registry.sol';
import { ILayerZeroEndpoint } from '@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol';

import { GasFunctionType } from './ITransport.sol';

library TransportStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.Transport');

    // solhint-disable-next-line ordering
    struct Layout {
        Registry registry;
        ILayerZeroEndpoint lzEndpoint;
        mapping(address => bool) isVault;
        mapping(uint16 => bytes) trustedRemoteLookup;
        address stargateRouter;
        mapping(address => uint) stargateAssetToSrcPoolId;
        // (chainId => (asset => poolId))
        mapping(uint16 => mapping(address => uint)) stargateAssetToDstPoolId;
        uint bridgeApprovalCancellationTime;
        mapping(GasFunctionType => uint) DEPRECATED_gasUsage;
        mapping(uint16 => uint) returnMessageCosts;
        // ChainId => (GasFunctionType => gasUsage)
        // The amount of gas needed for delivery on the destination can change
        // Based on the max number of assets that can be enabled in a vault on that chain
        mapping(uint16 => mapping(GasFunctionType => uint)) gasUsage;
        uint vaultCreationFee;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title   IValuer
 * @dev     The interface for a valio Valuer
 * @notice  The valuer is responsible for calculating the value an asset held by a vault
 */

interface IValuer {
    struct AssetValue {
        address asset;
        uint256 totalMinValue;
        uint256 totalMaxValue;
        AssetBreakDown[] breakDown;
    }

    struct AssetBreakDown {
        address asset;
        uint256 balance;
        uint256 minValue;
        uint256 maxValue;
    }

    /**
     * @notice  Returns the gross value and net value of the asset held by the vault
     * @param   vault  The vault address
     * @param   asset  The asset address
     * @param   unitPrice  The unitPrice of the asset (some assets may not have a unit price)
     * @return  minValue  The net value
     * @return  maxValue  The gross value
     */
    function getVaultValue(
        address vault,
        address asset,
        int256 unitPrice
    ) external view returns (uint256 minValue, uint256 maxValue);

    /**
     * @notice  Returns the value of a given amount of an asset
     * @dev     Assets that are not fungible with revert, individual units cannot be valued
     * @param   amount  The amount of the asset
     * @param   asset  The asset address
     * @param   unitPrice  The unitPrice of the asset
     * @return  minValue  The net value in USD (Constants.VAULT_PRECISION decimals)
     * @return  maxValue  The gross value in USD (Constants.VAULT_PRECISION decimals)
     */
    function getAssetValue(
        uint amount,
        address asset,
        int256 unitPrice
    ) external view returns (uint256 minValue, uint256 maxValue);

    /**
     * @notice  Returns a value breakdown for a given asset
     * @dev     This returns an array because later on we may support assets that have multiple tokens
     * @param   vault  The vault address
     * @param   asset  The asset address
     * @param   unitPrice  The unitPrice of the asset
     * @return  AssetValue  The asset value breakdown
     */
    function getAssetBreakdown(
        address vault,
        address asset,
        int256 unitPrice
    ) external view returns (AssetValue memory);

    function getAssetActive(
        address vault,
        address asset
    ) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

enum VaultRiskProfile {
    low,
    medium,
    high
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Registry } from '../registry/Registry.sol';
import { IGmxPositionRouterCallbackReceiver } from '../interfaces/IGmxPositionRouterCallbackReceiver.sol';
import { VaultBaseInternal } from './VaultBaseInternal.sol';
import { ExecutorIntegration } from '../executors/IExecutor.sol';
import { VaultBaseStorage } from './VaultBaseStorage.sol';
import { VaultRiskProfile } from './IVaultRiskProfile.sol';

/**
 * @title   VaultBaseExternal
 * @dev     Exposes some of the VaultBaseInternal functions externally.
 * @notice  The VaultChild inherits this directly, this is cut into the VaultParentDiamond
 */

contract VaultBaseExternal is
    IGmxPositionRouterCallbackReceiver,
    VaultBaseInternal
{
    /**
     * @notice  If anyone sends ETH to the vault, it will be converted to WETH.
     * @dev     The vault should never hold ETH
     * @dev     Unless the vault is trying to unwrap WETH, transiently, in which case it is allowed
     */
    receive() external payable {
        // We added the wrapping specifically for the gmx orderbook
        // When a gmx decrease trigger order is executed and the collateral
        // token is Weth it automatically converts it to ETH
        // and sends it to the vault. Therefore we need to convert it back to weth.
        // This if clause allows us to withdraw WETH to ETH to send in a call
        // We use this for refunding gmx execution fees, which are returned in WETH
        if (msg.sender != address(_registry().wrappedNativeToken())) {
            _registry().wrappedNativeToken().deposit{ value: msg.value }();
        }
    }

    /**
     * @notice  Called by the transport when it receives an asset from another chain.
     * @dev     The transport transfers the asset to the vault, we need to track the asset
     * @param   asset  the bridged asset being received by the vault
     */
    function receiveBridgedAsset(address asset) external onlyTransport {
        _receiveBridgedAsset(asset);
    }

    /**
     * @notice  Allows the manager to execute a transaction on the vault with the supported integration
     * @dev     NOTE: onlyManager
     * @dev     Executors run as the Vault (Delegate call), this allows us to contain the logic of the executor
     * @dev     When adding an additional executor, no changes to core code are needed.
     * @dev     The executor can be audited in isolation
     * @param   integration  Executor integration
     * @param   encodedWithSelectorPayload  Encoded with the selector and payload to be called on the Executor
     */
    function execute(
        ExecutorIntegration integration,
        bytes memory encodedWithSelectorPayload
    ) external payable nonReentrant onlyManager whenNotPaused {
        ExecutorIntegration[] memory clean = new ExecutorIntegration[](0);
        _execute(integration, encodedWithSelectorPayload, clean);
    }

    /**
     * @notice  Allows the manager to execute a transaction on the vault with the supported integration
     * @dev     NOTE: onlyManager
     * @dev     Executors run as the Vault (Delegate call), this allows us to contain the logic of the executor
     * @dev     When adding an additional executor, no changes to core code are needed.
     * @dev     The executor can be audited in isolation
     * @dev     This will also call the clean() method on the given integrationsToClean.
     * @param   integration  Executor integration
     * @param   integrationsToClean  Executor integrations where the clean() method should be called.
     * @param   encodedWithSelectorPayload  Encoded with the selector and payload to be called on the Executor
     */
    function executeAndClean(
        ExecutorIntegration integration,
        bytes memory encodedWithSelectorPayload,
        ExecutorIntegration[] memory integrationsToClean
    ) external payable nonReentrant onlyManager whenNotPaused {
        _execute(integration, encodedWithSelectorPayload, integrationsToClean);
    }

    /**
     * @notice  GmxCallback for when orders are executed by gmx
     * @dev     This is called by the GMX Position Router
     * @dev     This proxies the call to the GMX Executor
     * @param   positionKey  The gmx position key
     * @param   isExecuted  Whether the order was executed
     * @param   isIncrease  Whether the position was increased
     */
    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool isIncrease
    ) external nonReentrant {
        _gmxPositionCallback(positionKey, isExecuted, isIncrease);
    }

    /**
     * @notice  Returns the vault's registry
     * @dev     Used for tracking
     * @return  Registry  the vault's registry
     */
    function registry() external view returns (Registry) {
        return _registry();
    }

    /**
     * @notice  Returns the manager of the vault
     * @return  address  the managers address
     */
    function manager() external view returns (address) {
        return _manager();
    }

    /**
     * @notice  Returns the vault's ID
     * @dev     Used for tracking
     * @return  bytes32  the vault's ID
     */
    function vaultId() external view returns (bytes32) {
        return _vaultId();
    }

    /**
     * @notice  Uses the Accountant to get the AUM of the vault
     * @dev     This is used to calculate the CPIT
     * @return  minValue  The min value
     * @return  maxValue  The max value
     * @return  hasHardDeprecatedAsset  Whether the vault has a hard deprecated asset
     */
    function getVaultValue()
        external
        view
        returns (uint minValue, uint maxValue, bool hasHardDeprecatedAsset)
    {
        return _getVaultValue();
    }

    /**
     * @notice  Returns the CPIT incured by the manager in the last 24 hours
     * @dev     Note: the CPIT is the price impact of the manager's trading
     * @return  uint256  the CPIT
     */
    function getCurrentCpit() external view returns (uint256) {
        return _getCurrentCpit();
    }

    /**
     * @notice  Returns the risk profile of the vault
     * @return  VaultRiskProfile  the risk profile
     */
    function riskProfile() external view returns (VaultRiskProfile) {
        return _riskProfile();
    }

    /**
     * @notice  Returns if the asset is being tracked by the vault
     * @dev     This should be called `isActiveAsset` or `isTrackedAsset`
     * @param   asset  .
     * @return  bool  .
     */
    function enabledAssets(address asset) external view returns (bool) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.enabledAssets[asset];
    }

    /**
     * @notice  Returns the assets that are tracked by the vault
     * @dev     This should not be called assetsWithBalances, but should be called enabledAssets;
     * @dev     Some assets are enabled even though their balance 0
     * @dev     An example is that the collateralAsset for gmx is enabled for the life of the perp position
     * @return  address[]  the asset addreses
     */
    function assetsWithBalances() external view returns (address[] memory) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.assets;
    }

    /**
     * @notice  Returns how many locks an asset has
     * @dev     Note: if an asset has locks it cannot be removed from the vault tracking
     * @param   asset  the asset to check
     * @return  uint256  the number of locks
     */
    function assetLocks(address asset) external view returns (uint256) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.assetLocks[asset];
    }

    /**
     * @notice  Returns a list of any hard deprecated assets that are being tracked
     * @dev     Note: if a vault has hard deprecated assets it cannot be valued
     * @dev     The manager must trade out of the asset before any further deposits can be made
     * @return  hdeprecatedAssets  the hard deprecated assets
     */
    function hardDeprecatedAssets()
        external
        view
        returns (address[] memory hdeprecatedAssets)
    {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        hdeprecatedAssets = new address[](l.assets.length);
        uint count;
        for (uint i = 0; i < l.assets.length; i++) {
            if (l.registry.hardDeprecatedAssets(l.assets[i])) {
                count++;
                hdeprecatedAssets[i] = (l.assets[i]);
            }
        }

        uint256 reduceLength = l.assets.length - count;
        assembly {
            mstore(
                hdeprecatedAssets,
                sub(mload(hdeprecatedAssets), reduceLength)
            )
        }
    }

    /**
     * @notice  Adds an asset if it is not being tracked
     * @dev     Note: onlyThis, can be called by Executors
     * @param   asset  the asset to add
     */
    function addActiveAsset(address asset) public onlyThis {
        _addAsset(asset);
    }

    /**
     * @notice  Adds an asset if it is not being tracked, removes if it has no balance
     * @dev     Note: onlyThis, can be called by Executors
     * @dev     Should only be called when removing an asset from the vault,
     * @dev     Or if the caller isn't sure if the asset needs to be tracked
     * @dev     More performant to call addAsset
     * @param   asset  the asset to update tracking
     */
    function updateActiveAsset(address asset) public onlyThis {
        _updateActiveAsset(asset);
    }

    /**
     * @notice  Adds an asset lock for the given asset
     * @dev     Note: onlyThis, can be called by Executors
     * @param   asset  the asset to add the lock for
     */
    function addAssetLock(address asset) public onlyThis {
        _addAssetLock(asset);
    }

    /**
     * @notice  Removes an asset lock for the given asset
     * @dev     Note: onlyThis, can be called by Executors
     * @param   asset  the asset to remove the lock for
     */
    function removeAssetLock(address asset) public onlyThis {
        _removeAssetLock(asset);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Registry } from '../registry/Registry.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';
import { IGmxPositionRouterCallbackReceiver } from '../interfaces/IGmxPositionRouterCallbackReceiver.sol';
import { ExecutorIntegration, IExecutor } from '../executors/IExecutor.sol';
import { IRedeemer } from '../redeemers/IRedeemer.sol';
import { Call } from '../lib/Call.sol';
import { VaultBaseStorage } from './VaultBaseStorage.sol';
import { CPIT } from '../cpit/CPIT.sol';

import { ReentrancyGuard } from '@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol';
import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';

/**
 * @title   VaultBaseInternal
 * @notice  Internal functions for for both the VaultParent and VaultChild
 * @dev     This contains logic that both the parent and child need
 */

contract VaultBaseInternal is ReentrancyGuard, CPIT {
    using SafeERC20 for IERC20;

    event Withdraw(
        uint tokenId,
        address withdrawer,
        uint portion,
        address[] assets
    );
    event AssetAdded(address asset);
    event AssetRemoved(address asset);
    event BridgeReceived(address asset);
    event BridgeSent(
        uint16 dstChainId,
        address dstVault,
        address asset,
        uint amount
    );

    /**
     * @notice  Blocks the function if the vault is paused
     */
    modifier whenNotPaused() {
        require(!_registry().paused(), 'paused');
        _;
    }

    /**
     * @notice  Only allows an external call from the transport
     */
    modifier onlyTransport() {
        require(
            address(_registry().transport()) == msg.sender,
            'not transport'
        );
        _;
    }

    /**
     * @notice  Only allows an external call from itself
     * @dev     Used to allow Executors that are delegate called to call some specific functions
     */
    modifier onlyThis() {
        require(address(this) == msg.sender, 'not this');
        _;
    }

    /**
     * @notice  Only allows an external call from the manager
     */
    modifier onlyManager() {
        require(_manager() == msg.sender, 'not manager');
        _;
    }

    /**
     * @notice  Called when the vault is created
     * @dev     Should not be called again
     * @param   registry  Valio Registry
     * @param   manager  Manager address of the vault
     * @param   riskProfile  Risk profile of the vault
     */
    function initialize(
        Registry registry,
        address manager,
        VaultRiskProfile riskProfile
    ) internal {
        require(manager != address(0), 'invalid _manager');
        require(address(registry) != address(0), 'invalid _registry');

        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        l.registry = Registry(registry);
        l.manager = manager;
        l.riskProfile = riskProfile;
    }

    /**
     * @notice  Allows the manager to execute a transaction on the vault with the supported integration
     * @dev     Executors run as the Vault (Delegate call), this allows us to contain the logic of the executor
     * @dev     When adding an additional executor, no changes to core code are needed.
     * @dev     The executor can be audited in isolation
     * @param   integration  Executor integration
     * @param   encodedWithSelectorPayload  Encoded with the selector and payload to be called on the Executor
     */
    function _execute(
        ExecutorIntegration integration,
        bytes memory encodedWithSelectorPayload,
        ExecutorIntegration[] memory cleanIntegrations
    ) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        address executor = l.registry.executors(integration);
        require(executor != address(0), 'no executor');

        // Runs any code thats required to tidy up positions for a given integration
        // I.e Removes GMX positions that have been liquidated from storage
        for (uint i = 0; i < cleanIntegrations.length; i++) {
            address cleanExecutor = l.registry.executors(cleanIntegrations[i]);
            require(cleanExecutor != address(0), 'no clean executor');
            Call._delegate(cleanExecutor, abi.encodeCall(IExecutor.clean, ()));
        }

        // During withdraw we use to check if each asset was still active
        // But this is gas intensive and adds costs to the withdrawer
        _updateAllActiveAssets();

        bool requiresCPIT = IExecutor(executor).requiresCPIT();

        // Get value before manager execution, for CPIT
        (uint minVaultValue, , ) = requiresCPIT
            ? _getVaultValue()
            : (0, 0, false);

        // Make the external call
        Call._delegate(executor, encodedWithSelectorPayload);

        // Get value after for CPIT
        if (requiresCPIT) {
            (uint minVaultValueAfter, , ) = _getVaultValue();
            _updatePriceImpact(
                minVaultValue,
                minVaultValueAfter,
                _registry().maxCpitBips(l.riskProfile)
            );
        }
    }

    /**
     * @notice  Allows a user to withdraw a portion of the vault
     * @dev     The Redeemer runs as the Vault. This allows us to contain the logic of the redeemer
     * @dev     When adding an additional redeemer, no changes to core code are needed.
     * @dev     The redeemer can be audited in isolation
     * @param   tokenId  Token ID of the vault (only used for tracking)
     * @param   withdrawer  Address of the withdrawer (redeemer)
     * @param   portion  Portion of the vault to withdraw
     */
    function _withdraw(
        uint tokenId,
        address withdrawer,
        uint portion
    ) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();

        for (uint i = 0; i < l.assets.length; i++) {
            address redeemer = l.registry.redeemers(l.assets[i]);
            require(redeemer != address(0), 'no redeemer');
            if (IRedeemer(redeemer).hasPreWithdraw()) {
                Call._delegate(
                    redeemer,
                    abi.encodeCall(
                        IRedeemer.preWithdraw,
                        (tokenId, l.assets[i], withdrawer, portion)
                    )
                );
            }
        }

        // We need to take a memory refence as we remove assets that are fully withdrawn
        // And this means that the assets array will change length
        // This should not be moved before preWithdraw because preWithdraw can add active assets
        address[] memory assets = l.assets;

        for (uint i = 0; i < assets.length; i++) {
            address redeemer = l.registry.redeemers(assets[i]);
            Call._delegate(
                redeemer,
                abi.encodeCall(
                    IRedeemer.withdraw,
                    (tokenId, assets[i], withdrawer, portion)
                )
            );
        }

        emit Withdraw(tokenId, withdrawer, portion, assets);
        _registry().emitEvent();
    }

    /**
     * @notice  Loops through all active assets and removes them if they are no longer active
     * @dev     An asset is no longer active if it has no balance
     */
    function _updateAllActiveAssets() internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        for (uint i = 0; i < l.assets.length; i++) {
            _updateActiveAsset(l.assets[i]);
        }
    }

    /**
     * @notice  Adds the asset to the asset tracking list if it is active, removes if not active
     * @param   asset  Asset to check
     */
    function _updateActiveAsset(address asset) internal {
        if (_isActive(asset)) {
            _addAsset(asset);
        } else {
            _removeAsset(asset);
        }
    }

    /**
     * @notice  Receives the bridged asset
     * @dev     Adds the asset to tracking
     * @param   asset  Asset being received from the bridge
     */
    function _receiveBridgedAsset(address asset) internal {
        // Force flag is set to true, because we must receive the bridged asset
        _addAsset(asset, true);
        emit BridgeReceived(asset);
        _registry().emitEvent();
    }

    /**
     * @notice  Allows a manager to bridge an asset
     * @dev     We only pair briding ie USDC:USDC, this means we can determine a safe minout
     * @param   dstChainId  Chain ID of the destination vault
     * @param   dstVault  Address of the destination vault
     * @param   parentChainId  Chain ID of the parent vault
     * @param   vaultParent  Address of the parent vault
     * @param   asset  Asset to bridge
     * @param   amount  Amount of the asset to bridge
     * @param   minAmountOut  Minimum amount of the asset to receive
     * @param   lzFee  Fee to send to the bridge
     */
    function _bridgeAsset(
        uint16 dstChainId,
        address dstVault,
        uint16 parentChainId,
        address vaultParent,
        address asset,
        uint amount,
        uint minAmountOut,
        uint lzFee
    ) internal {
        // The max slippage the stargate ui shows is 1%
        // check minAmountOut is within this threshold
        uint internalMinAmountOut = (amount * 99) / 100;
        require(minAmountOut >= internalMinAmountOut, 'minAmountOut too low');

        IERC20(asset).safeApprove(address(_registry().transport()), amount);
        _registry().transport().bridgeAsset{ value: lzFee }(
            dstChainId,
            dstVault,
            parentChainId,
            vaultParent,
            asset,
            amount,
            minAmountOut
        );
        emit BridgeSent(dstChainId, dstVault, asset, amount);
        _registry().emitEvent();
        _updateActiveAsset(asset);
    }

    /**
     * @notice  GmxCallback for when orders are executed by gmx
     * @dev     This is called by the GMX Position Router
     * @dev     This proxies the call to the GMX Executor
     * @param   positionKey  The gmx position key
     * @param   isExecuted  Whether the order was executed
     * @param   isIncrease  Whether the position was increased
     */
    function _gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool isIncrease
    ) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        require(
            msg.sender == address(l.registry.gmxConfig().positionRouter()),
            'not gmx'
        );
        address executor = l.registry.executors(ExecutorIntegration.GMX);
        require(executor != address(0), 'no executor');
        Call._delegate(
            executor,
            abi.encodeCall(
                IGmxPositionRouterCallbackReceiver.gmxPositionCallback,
                (positionKey, isExecuted, isIncrease)
            )
        );
    }

    /**
     * @notice  Adds a lock to the asset
     * @dev     This is used to prevent the asset from being removed
     * @dev     There can be multiple locks on an asset
     * @dev     EG. If a GMX position is liquidated we dont receive an event
     * @dev     And residual funds are returned to the vault in the collateral token
     * @dev     Its the lockers responsibility to remove the lock
     * @param   asset  Asset to lock
     */
    function _addAssetLock(address asset) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        require(l.enabledAssets[asset], 'lock: asset not enabled');
        l.assetLocks[asset] += 1;
    }

    /**
     * @notice  Removes a lock from the asset
     * @dev     There can be multiple locks on an asset
     * @dev     Its the lockers responsiblity to remove the lock when appropriate
     * @param   asset  Asset to unlock
     */
    function _removeAssetLock(address asset) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        if (l.assetLocks[asset] > 0) {
            l.assetLocks[asset] -= 1;
        }
    }

    /**
     * @notice  Removes an asset from tracking
     * @dev     Will return early if asset is under lock
     * @param   asset  .
     */
    function _removeAsset(address asset) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        if (l.assetLocks[asset] > 0) {
            return;
        }
        if (l.enabledAssets[asset]) {
            for (uint i = 0; i < l.assets.length; i++) {
                if (l.assets[i] == asset) {
                    _removeFromArray(l.assets, i);
                    l.enabledAssets[asset] = false;

                    emit AssetRemoved(asset);
                    _registry().emitEvent();
                }
            }
        }
    }

    /**
     * @notice  Adds an asset to tracking
     * @dev     Will return early if asset is already tracked
     * @param   asset  Asset to add
     */
    function _addAsset(address asset) internal {
        _addAsset(asset, false);
    }

    /**
     * @notice  Adds an asset to tracking
     * @dev     The force flag is used when assets are bridged and we must receive them
     * @dev     It circumvents the maxActiveAssets check
     * @param   asset  Asset to add
     * @param   force  Whether to force the asset to be added
     */
    function _addAsset(address asset, bool force) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        require(
            l.registry.accountant().isSupportedAsset(asset),
            'asset not supported'
        );
        if (!l.enabledAssets[asset]) {
            l.enabledAssets[asset] = true;
            l.assets.push(asset);
            require(
                force || l.assets.length <= l.registry.maxActiveAssets(),
                'too many assets'
            );

            emit AssetAdded(asset);
            _registry().emitEvent();
        }
    }

    /**
     * @notice  Removes an address from an array
     * @dev     This is used to remove assets from the assets array
     * @param   array  the array to remove from
     * @param   index  the index to remove
     */
    function _removeFromArray(address[] storage array, uint index) internal {
        require(index < array.length);
        array[index] = array[array.length - 1];
        array.pop();
    }

    /**
     * @notice  Changes the manager of the vault
     * @dev     This is used to change the manager of the vault
     * @param   newManager  the new manager address
     */
    function _changeManager(address newManager) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        l.manager = newManager;
    }

    /**
     * @notice  Sets the vault ID
     * @dev     Used for offchain tracking
     * @dev     Only call on vault initialize
     * @param   vaultId  the vault ID
     */
    function _setVaultId(bytes32 vaultId) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        l.vaultId = vaultId;
    }

    /**
     * @notice  Returns the valio registry
     * @return  Registry  the valio registry
     */
    function _registry() internal view returns (Registry) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.registry;
    }

    /**
     * @notice  Returns the risk profile of the vault
     * @return  VaultRiskProfile  the risk profile of the vault
     */
    function _riskProfile() internal view returns (VaultRiskProfile) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.riskProfile;
    }

    /**
     * @notice  Returns the manager of the vault
     * @return  address  the manager of the vault
     */
    function _manager() internal view returns (address) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.manager;
    }

    /**
     * @notice  Returns the vault ID
     * @dev     Used for offchain tracking
     * @return  bytes32  the vault ID
     */
    function _vaultId() internal view returns (bytes32) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.vaultId;
    }

    /**
     * @notice  Uses the Accountant to get the AUM of the vault
     * @dev     This is used to calculate the CPIT
     * @return  minValue  The min value
     * @return  maxValue  The max value
     * @return  hasHardDeprecatedAsset  Whether the vault has a hard deprecated asset
     */
    function _getVaultValue()
        internal
        view
        returns (uint minValue, uint maxValue, bool hasHardDeprecatedAsset)
    {
        return _registry().accountant().getVaultValue(address(this));
    }

    /**
     * @notice  Returns if the asset is being tracked
     * @param   asset  Asset to check
     * @return  bool  True if the asset is being tracked
     */
    function _isActive(address asset) internal view returns (bool) {
        return _registry().accountant().assetIsActive(asset, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Registry } from '../registry/Registry.sol';

import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';

library VaultBaseStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.VaultBase');

    // solhint-disable-next-line ordering
    struct Layout {
        Registry registry;
        address manager;
        address[] assets;
        mapping(address => bool) enabledAssets;
        VaultRiskProfile riskProfile;
        bytes32 vaultId;
        // For instance a GMX position can get liquidated at anytime and any collateral
        // remaining is returned to the vault. But the vault is not notified.
        // In this case the collateralToken might not be tracked by the vault anymore
        // To resolve this: A GmxPosition will increament the assetLock for the collateralToken, meaning that it cannot
        // be removed from enabledAssets until the lock for the asset reaches 0
        // Any code that adds a lock is responsible for removing the lock
        mapping(address => uint256) assetLocks;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ITransport, GasFunctionType } from '../transport/ITransport.sol';
import { VaultBaseInternal } from '../vault-base/VaultBaseInternal.sol';
import { VaultBaseExternal } from '../vault-base/VaultBaseExternal.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';
import { Registry } from '../registry/Registry.sol';
import { RegistryStorage } from '../registry/RegistryStorage.sol';
import { VaultChildStorage } from './VaultChildStorage.sol';

import { IRedeemerEvents } from '../redeemers/IRedeemerEvents.sol';
import { IExecutorEvents } from '../executors/IExecutorEvents.sol';

import { IStargateRouter } from '@layerzerolabs/solidity-examples/contracts/interfaces/IStargateRouter.sol';

/**
 * @title   VaultChild
 * @notice  The VaultChild is a child of the VaultParent and is used to the VaultParent to hold funds on other chains
 * @dev     Contains all the logic for the VaultChild
 * @dev     The VaultChild is just a container for assets that a manager controls
 */

contract VaultChild is
    VaultBaseInternal,
    VaultBaseExternal,
    IRedeemerEvents,
    IExecutorEvents
{
    event BridgeApprovalReceived(uint time);

    /**
     * @notice  The VaultChild is approved to bridge to the parent or sibling
     * @dev     This modifier is used to ensure that the VaultChild is approved to bridge
     * @dev     The VaultParent must know the VaultChild is going to bridge, as assets will be inflight
     * @dev     We block deposits(syncs) and withdraws while assets are in flight
     */
    modifier bridgingApproved() {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        require(l.bridgeApproved, 'bridge not approved');
        _;
    }

    /**
     * @notice  Initializes the VaultChild
     * @dev     Only called once when the VaultChild is created, calls initializes of superclasses
     * @param   _parentChainId  The lz chainId of the parent chain
     * @param   _vaultParentAddress  The address of the parent vault
     * @param   __manager  the manager of the vault
     * @param   __riskProfile  the risk profile of the vault
     * @param   __registry  the valio registry
     * @param   _existingSiblings  the existing siblings of the vault (other child vaults on other chains)
     */
    function initialize(
        uint16 _parentChainId,
        address _vaultParentAddress,
        address __manager,
        VaultRiskProfile __riskProfile,
        Registry __registry,
        ITransport.ChildVault[] memory _existingSiblings
    ) external {
        require(_vaultId() == 0, 'already initialized');

        VaultChildStorage.Layout storage l = VaultChildStorage.layout();
        VaultBaseInternal.initialize(__registry, __manager, __riskProfile);
        require(_parentChainId != 0, 'invalid _parentChainId');
        require(
            _vaultParentAddress != address(0),
            'invalid _vaultParentAddress'
        );

        bytes32 __vaultId = keccak256(
            abi.encodePacked(_parentChainId, _vaultParentAddress)
        );
        _setVaultId(__vaultId);

        l.parentChainId = _parentChainId;
        l.vaultParent = _vaultParentAddress;
        for (uint8 i = 0; i < _existingSiblings.length; i++) {
            l.siblingChains.push(_existingSiblings[i].chainId);
            l.siblings[_existingSiblings[i].chainId] = _existingSiblings[i]
                .vault;
        }
    }

    ///
    /// Receivers/CallBacks
    ///

    /**
     * @notice  Called by the parent chain to add a new sibling to the VaultChild
     * @dev     This allows the child to bridge to another child (sibling)
     * @param   siblingChainId  The lz chainId of the sibling
     * @param   siblingVault  The address of the sibling vault
     */
    function receiveAddSibling(
        uint16 siblingChainId,
        address siblingVault
    ) external onlyTransport {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        l.siblings[siblingChainId] = siblingVault;
        l.siblingChains.push(siblingChainId);
    }

    /**
     * @notice  Called by the parent chain to approve the bridge
     * @dev     The parent chain must approve the bridge before the child can bridge
     * @dev     The VaultParent must know the VaultChild is going to bridge, as assets will be inflight
     * @dev     We block deposits(syncs) and withdraws while assets are in flight
     */
    function receiveBridgeApproval() external onlyTransport {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        l.bridgeApproved = true;
        l.bridgeApprovalTime = block.timestamp;
        _registry().emitEvent();
        emit BridgeApprovalReceived(block.timestamp);
    }

    /**
     * @notice  Called by the parent chain to request a Withdraw
     * @dev     The vault child has no concept of `shares` only `portion`
     * @dev     The portion is calculated on the Parent chain and sent to the child
     * @dev     Based on the number of shares burned relative to the total outstanding shares
     * @param   tokenId  The tokenId of holding (only used for tracking)
     * @param   withdrawer  The address of the withdrawer
     * @param   portion  The portion of the vault to withdraw
     */
    function receiveWithdrawRequest(
        uint tokenId,
        address withdrawer,
        uint portion
    ) external nonReentrant onlyTransport {
        _withdraw(tokenId, withdrawer, portion);
    }

    /**
     * @notice  Called by the parent chain to request a manager change
     * @param   newManager  The address of the new manager
     */
    function receiveManagerChange(address newManager) external onlyTransport {
        _changeManager(newManager);
    }

    ///
    /// Cross Chain Requests
    ///

    //
    /**
     * @notice  Sends a message to the Parent cancelling the bridgeApproval.
     * @dev     The VaultParent must know the VaultChild is going to bridge, as assets will be inflight
     * @dev     We block deposits(syncs) and withdraws while assets are in flight
     * @dev     Allows anyone to cancel the bridge lock on the parent after 5 minutes
     * @dev     This stops a bad manager from blocking withdraws
     */
    function requestBridgeApprovalCancellation()
        external
        payable
        whenNotPaused
    {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        require(l.bridgeApproved, 'must be already approved');
        uint timeout = _registry().transport().bridgeApprovalCancellationTime();

        if (msg.sender != _manager()) {
            require(
                l.bridgeApprovalTime + timeout < block.timestamp,
                'cannot cancel yet'
            );
        }

        l.bridgeApproved = false;
        l.bridgeApprovalTime = 0;
        _registry().transport().sendBridgeApprovalCancellation{
            value: msg.value
        }(
            ITransport.BridgeApprovalCancellationRequest({
                parentChainId: l.parentChainId,
                parentVault: l.vaultParent,
                requester: msg.sender
            })
        );
    }

    /**
     * @notice  Bridges an asset to another chain
     * @param   dstChainId  The lz chainId of the destination chain (must have parent/sibling on this chain)
     * @param   asset  The address of the asset to bridge
     * @param   amount  The amount of the asset to bridge
     * @param   minAmountOut  The minimum amount of the asset to receive on the destination chain
     */
    function requestBridgeToChain(
        uint16 dstChainId,
        address asset,
        uint amount,
        uint minAmountOut,
        uint // unused, kept for compatibility
    ) external payable onlyManager whenNotPaused bridgingApproved {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        address dstVault;
        if (dstChainId == l.parentChainId) {
            dstVault = l.vaultParent;
        } else {
            dstVault = l.siblings[dstChainId];
        }

        require(dstVault != address(0), 'no dst vault');

        l.bridgeApproved = false;
        l.bridgeApprovalTime = 0;
        _bridgeAsset(
            dstChainId,
            dstVault,
            l.parentChainId,
            l.vaultParent,
            asset,
            amount,
            minAmountOut,
            msg.value
        );
    }

    ///
    /// Views
    ///

    /**
     * @notice  Returns the lz parentChainId
     * @return  uint16  The lz parentChainId
     */
    function parentChainId() external view returns (uint16) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        return l.parentChainId;
    }

    /**
     * @notice  Returns the address of the parent vault
     * @return  address  The address of the parent vault
     */
    function parentVault() external view returns (address) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        return l.vaultParent;
    }

    /**
     * @notice  Returns the lz chainids where it has a sibling
     * @return  uint16[]  The lz chain ids where it has a sibling
     */
    function allSiblingChainIds() external view returns (uint16[] memory) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();
        return l.siblingChains;
    }

    /**
     * @notice  Returns the childVault address if it has a sibling on the given lz chain id
     * @param   chainId  The lz chain id
     * @return  address  The address of the sibling vault
     */
    function siblings(uint16 chainId) external view returns (address) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();
        return l.siblings[chainId];
    }

    /**
     * @notice  Returns if the child is approved to bridge
     * @dev     Frontend helper
     * @return  bool  True if the child is approved to bridge
     */
    function bridgeApproved() external view returns (bool) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();
        return l.bridgeApproved;
    }

    /**
     * @notice  When the child was approved to bridge
     * @dev     Used to determine if the bridge can be cancelled by any user
     * @return  uint  The time the child was approved to bridge
     */
    function bridgeApprovalTime() external view returns (uint) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();
        return l.bridgeApprovalTime;
    }

    /**
     * @notice  Returns the lz fee for the give function
     * @dev     This is a helper method for the frontend
     * @dev     We use the sighash of the intended function call to identify the action
     * @param   sigHash  The sighash of the intended function call
     * @param   chainId  The destination lz chain id
     * @return  fee  The lz fee for the message + destination gas
     */
    function getLzFee(
        bytes4 sigHash,
        uint16 chainId
    ) external view returns (uint fee) {
        if (sigHash == this.requestBridgeToChain.selector) {
            fee = _bridgeQuote(chainId);
        } else {
            (fee, ) = _registry().transport().getLzFee(
                GasFunctionType.standardNoReturnMessage,
                chainId
            );
        }
    }

    /**
     * @notice  Returns the fee for executing a bridge
     * @dev     Currently this is stargate, but could be different in the future
     * @param   dstChainId  The destination lz chain id
     * @return  fee  The stargate fee for the bridge
     */
    function _bridgeQuote(uint16 dstChainId) internal view returns (uint fee) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        address dstVault;
        if (dstChainId == l.parentChainId) {
            dstVault = l.vaultParent;
        } else {
            dstVault = l.siblings[dstChainId];
        }

        require(dstVault != address(0), 'no dst vault');

        fee = _registry().transport().getBridgeAssetQuote(
            dstChainId,
            dstVault,
            l.parentChainId,
            l.vaultParent
        );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Proxy } from '@solidstate/contracts/proxy/Proxy.sol';
import { IDiamondReadable } from '@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol';

/**
 * @title   VaultChildProxy
 * @dev     An instance of this is created when a manager creates a ChildVault
 * @notice  This proxies to the VaultChildDiamond which is its `implementation`
 */
contract VaultChildProxy is Proxy {
    address private immutable DIAMOND;

    constructor(address diamond) {
        DIAMOND = diamond;
    }

    function _getImplementation() internal view override returns (address) {
        return IDiamondReadable(DIAMOND).facetAddress(msg.sig);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library VaultChildStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.VaultChild');

    // solhint-disable-next-line ordering
    struct Layout {
        bytes32 _deprecated_vaultId;
        uint16 parentChainId;
        address vaultParent;
        bool bridgeApproved;
        uint bridgeApprovalTime;
        uint16[] siblingChains;
        mapping(uint16 => address) siblings;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { VaultFeesStorage } from './VaultFeesStorage.sol';
import { Constants } from '../lib/Constants.sol';

/**
 * @title   VaultFees
 * @dev     Logic for calculating and updating manager fees
 * @dev     Fees are calculated on a per holding basis
 * @dev     Performance fees are fees on profit
 * @dev     Streaming fees are fees on aum charged over time
 */

contract VaultFees {
    uint internal constant _STEAMING_FEE_DURATION = 365 days;

    uint internal constant _MAX_STREAMING_FEE_BASIS_POINTS = 500; // 5%
    uint internal constant _MAX_STREAMING_FEE_BASIS_POINTS_STEP = 50; // 0.5%
    uint internal constant _MAX_PERFORMANCE_FEE_BASIS_POINTS = 5_000; // 50%
    uint internal constant _MAX_PERFORMANCE_FEE_BASIS_POINTS_STEP = 1_000; // 10%
    uint internal constant _FEE_ANNOUNCE_WINDOW = 30 days;

    event FeeIncreaseAnnounced(uint streamingFee, uint performanceFee);
    event FeeIncreaseCommitted(uint streamingFee, uint performanceFee);
    event FeeIncreaseRenounced();
    event ReferrerShareUpdated(uint256 referrerShareBips);

    /**
     * @notice  Initialize the vault fees
     * @dev     Can only be called once on deployment
     * @param   _managerStreamingFeeBasisPoints  the initial manager streaming fee
     * @param   _managerPerformanceFeeBasisPoints  the initial manager performance fee
     */
    function initialize(
        uint _managerStreamingFeeBasisPoints,
        uint _managerPerformanceFeeBasisPoints
    ) internal {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();
        require(
            _managerStreamingFeeBasisPoints <= _MAX_STREAMING_FEE_BASIS_POINTS,
            'streamingFee to high'
        );
        require(
            _managerPerformanceFeeBasisPoints <=
                _MAX_PERFORMANCE_FEE_BASIS_POINTS,
            'performanceFee to high'
        );
        l.managerStreamingFee = _managerStreamingFeeBasisPoints;
        l.managerPerformanceFee = _managerPerformanceFeeBasisPoints;
    }

    /**
     * @notice  Set the referrer share
     * @dev     The referrer share is taken from the managers net fees and given to the referrer
     * @param   referrerShareBips  the referrer share in basis points (ie 10% of manager fees)
     */
    function _setReferrerShareBips(uint256 referrerShareBips) internal {
        require(
            referrerShareBips <= Constants.BASIS_POINTS_DIVISOR,
            'referrerShare to high'
        );
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();
        l.referrerShareBips = referrerShareBips;
        emit ReferrerShareUpdated(referrerShareBips);
    }

    /**
     * @notice  Announce a fee increase
     * @dev     The fee increase will be active after a delay
     * @dev     This protect investors from sudden fee increases
     * @dev     They must wait the _FEE_ANNOUNCE_WINDOW before commiting the change
     * @param   newStreamingFee  The streaming fee in basis points
     * @param   newPerformanceFee  The performance fee in basis points
     */
    function _announceFeeIncrease(
        uint256 newStreamingFee,
        uint256 newPerformanceFee
    ) internal {
        require(
            newStreamingFee <= _MAX_STREAMING_FEE_BASIS_POINTS,
            'streamingFee to high'
        );

        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        require(
            newStreamingFee <=
                l.managerStreamingFee + _MAX_STREAMING_FEE_BASIS_POINTS_STEP,
            'streamingFee step exceeded'
        );
        require(
            newPerformanceFee <= _MAX_PERFORMANCE_FEE_BASIS_POINTS,
            'performanceFee to high'
        );
        require(
            newPerformanceFee <=
                l.managerPerformanceFee +
                    _MAX_PERFORMANCE_FEE_BASIS_POINTS_STEP,
            'performanceFee step exceeded'
        );

        l.announcedFeeIncreaseTimestamp = block.timestamp;
        l.announcedManagerStreamingFee = newStreamingFee;
        l.announcedManagerPerformanceFee = newPerformanceFee;
        emit FeeIncreaseAnnounced(newStreamingFee, newPerformanceFee);
    }

    /**
     * @notice  Allows the manager to renounce a fee increase
     * @dev     Can be called at anytime
     */
    function _renounceFeeIncrease() internal {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        require(
            l.announcedFeeIncreaseTimestamp != 0,
            'no fee increase announced'
        );

        l.announcedFeeIncreaseTimestamp = 0;
        l.announcedManagerStreamingFee = 0;
        l.announcedManagerPerformanceFee = 0;

        emit FeeIncreaseRenounced();
    }

    /**
     * @notice  Commits the fee increase previously announced
     * @dev     Can only be called after _FEE_ANNOUNCE_WINDOW has passed
     */
    function _commitFeeIncrease() internal {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        require(
            l.announcedFeeIncreaseTimestamp != 0,
            'no fee increase announced'
        );
        require(
            block.timestamp >=
                l.announcedFeeIncreaseTimestamp + _FEE_ANNOUNCE_WINDOW,
            'fee delay active'
        );

        l.managerStreamingFee = l.announcedManagerStreamingFee;
        l.managerPerformanceFee = l.announcedManagerPerformanceFee;

        l.announcedFeeIncreaseTimestamp = 0;
        l.announcedManagerStreamingFee = 0;
        l.announcedManagerPerformanceFee = 0;

        emit FeeIncreaseCommitted(
            l.managerStreamingFee,
            l.managerPerformanceFee
        );
    }

    /**
     * @notice  Returns the current performance fee
     * @dev     Denominated in basis points 10000 = 100%
     * @return  uint  The current performance fee
     */
    function _managerPerformanceFee() internal view returns (uint) {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        return l.managerPerformanceFee;
    }

    /**
     * @notice  Returns the current streaming fee
     * @dev     Denominated in basis points 10000 = 100%
     * @return  uint  The current streaming fee
     */
    function _managerStreamingFee() internal view returns (uint) {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        return l.managerStreamingFee;
    }

    /**
     * @notice  Returns the announced manager performance fee
     * @dev     Denominated in basis points 10000 = 100%
     * @dev     Returns 0 if there is no announced fee increase
     * @return  uint  The announced manager performance fee
     */
    function _announcedManagerPerformanceFee() internal view returns (uint) {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        return l.announcedManagerPerformanceFee;
    }

    /**
     * @notice  Returns the announced manager streaming fee
     * @dev     Denominated in basis points 10000 = 100%
     * @dev     Returns 0 if there is no announced fee increase
     * @return  uint  The announced manager streaming fee
     */
    function _announcedManagerStreamingFee() internal view returns (uint) {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();
        return l.announcedManagerStreamingFee;
    }

    /**
     * @notice  Returns the timestamp of the announced fee increase
     * @dev     This is when the fee increase was announced
     * @dev     0 if there is not annonced fee increase
     * @return  uint  The timestamp of the announced fee increase
     */
    function _announcedFeeIncreaseTimestamp() internal view returns (uint) {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        return l.announcedFeeIncreaseTimestamp;
    }

    /**
     * @notice  Returns the current referrer share
     * @dev     Denominated in basis points 10000 = 100%
     * @return  uint  The current referrer share
     */
    function _referrerShareBips() internal view returns (uint256) {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        return l.referrerShareBips;
    }

    /**
     * @notice  Pure function which calculates the streaming fee owed
     * @param   fee  The current streaming fee in bips
     * @param   discount  The streaming fee discount in bips
     * @param   lastFeeTime  The last time the fee was charged
     * @param   totalShares  The total shares in the holding
     * @param   timeNow  The current time
     * @return  tokensOwed  The amount streaming fees owed denominated in shares
     */
    function _streamingFee(
        uint fee,
        uint discount,
        uint lastFeeTime,
        uint totalShares,
        uint timeNow
    ) internal pure returns (uint tokensOwed) {
        if (lastFeeTime >= timeNow) {
            return 0;
        }

        uint discountAdjustment = Constants.BASIS_POINTS_DIVISOR - discount;
        uint timeSinceLastFee = timeNow - lastFeeTime;
        tokensOwed =
            (totalShares * fee * timeSinceLastFee * discountAdjustment) /
            _STEAMING_FEE_DURATION /
            Constants.BASIS_POINTS_DIVISOR /
            Constants.BASIS_POINTS_DIVISOR;
    }

    /**
     * @notice  Pure function which calculates the performance fee owed
     * @param   fee  The current performance fee in bips
     * @param   discount  The performance fee discount in bips
     * @param   totalShares  The total shares in the holding
     * @param   tokenPriceStart  The token price last time performance fees were charged
     * @param   tokenPriceFinish  The current token price
     * @return  tokensOwed  The amount performance fees owed denominated in shares
     */
    function _performanceFee(
        uint fee,
        uint discount,
        uint totalShares,
        uint tokenPriceStart,
        uint tokenPriceFinish
    ) internal pure returns (uint tokensOwed) {
        if (tokenPriceFinish <= tokenPriceStart) {
            return 0;
        }

        uint discountAdjustment = Constants.BASIS_POINTS_DIVISOR - discount;
        uint priceIncrease = tokenPriceFinish - (tokenPriceStart);
        tokensOwed =
            (priceIncrease * fee * totalShares * discountAdjustment) /
            tokenPriceFinish /
            Constants.BASIS_POINTS_DIVISOR /
            Constants.BASIS_POINTS_DIVISOR;
    }

    /**
     * @notice  Calculates the protocols share of the manager fees
     * @param   managerFees  The total manager fees denominated in shares
     * @param   protocolFeeBips  .
     * @return  uint  .
     */
    function _protocolFee(
        uint managerFees,
        uint protocolFeeBips
    ) internal pure returns (uint) {
        return (managerFees * protocolFeeBips) / Constants.BASIS_POINTS_DIVISOR;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library VaultFeesStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.VaultFees');

    // solhint-disable-next-line ordering
    struct Layout {
        uint managerStreamingFee;
        uint managerPerformanceFee;
        uint announcedFeeIncreaseTimestamp;
        uint announcedManagerStreamingFee;
        uint announcedManagerPerformanceFee;
        uint referrerShareBips;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { VaultFees } from '../vault-fees/VaultFees.sol';
import { VaultOwnershipStorage } from './VaultOwnershipStorage.sol';

import { ERC721BaseInternal } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';
import { ERC721EnumerableInternal } from '@solidstate/contracts/token/ERC721/enumerable/ERC721Enumerable.sol';
import { ERC721MetadataStorage } from '@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol';

import { Constants } from '../lib/Constants.sol';

/**
 * @title   VaultOwnershipInternal
 * @notice  This contract is responsible for the creation and management of holdings
 * @dev     One of the components that makes up the VaultParent
 * @dev  Each users is allowed 1 holding. The manager can have two, fee holding and personal
 * @dev  Responsibilities include: Issuing shares, burning shares, levying fees, setting referrers, and fee discounts
 */

contract VaultOwnershipInternal is
    ERC721BaseInternal, //ERC165BaseInternal causes Linearization issue in vaultParentErc721
    ERC721EnumerableInternal,
    VaultFees
{
    // STD Struct
    struct ReferrerInfo {
        address referrerAddress;
        uint referrerFees;
        uint referrerTokenId;
    }

    uint internal constant _MANAGER_TOKEN_ID = 0;
    uint internal constant _PROTOCOL_TOKEN_ID = 1;

    uint internal constant BURN_LOCK_TIME = 24 hours;

    event FeesLeviedOnHolding(
        uint tokenId,
        uint streamingFees,
        uint performanceFees,
        uint protocolFees,
        uint referrerFees,
        uint referrerTokenId,
        address referrer,
        uint managerFees,
        uint currentUnitPrice
    );

    event ReferrerSet(uint tokenId, address referrerAddress);
    event RefererFeesAllocated(
        uint tokenId,
        address referrerAddress,
        uint referrerFees
    );

    /**
     * @notice  Initialises stored data for the vault and creates the manager and protocol holdings
     * @dev     Called when the vault is created
     * @param   __name  The name of the vault
     * @param   _symbol  The symbol/ticker of the vault
     * @param   _manager  The managers address
     * @param   _managerStreamingFeeBasisPoints  The managers streaming fee denominated in basis points
     * @param   _managerPerformanceFeeBasisPoints  The managers performance fee denominated in basis points
     * @param   _protocolAddress  The address of the protocol treasury
     */
    function initialize(
        string memory __name,
        string memory _symbol,
        address _manager,
        uint _managerStreamingFeeBasisPoints,
        uint _managerPerformanceFeeBasisPoints,
        address _protocolAddress
    ) internal {
        super.initialize(
            _managerStreamingFeeBasisPoints,
            _managerPerformanceFeeBasisPoints
        );
        ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();
        l.name = __name;
        l.symbol = _symbol;

        _createManagerHolding(_manager);
        _createProtocolHolding(_protocolAddress);
    }

    /**
     * @notice  Mints a new holding for the user and increments the tokenIdCounter
     * @param   to  The owner of the holding
     * @return  tokenId  The tokenId of the new holding
     */
    function _mint(address to) internal returns (uint256 tokenId) {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        tokenId = l._tokenIdCounter;
        _safeMint(to, tokenId);
        l._tokenIdCounter++;
    }

    /**
     * @notice  Creates the manager holding
     * @dev     Should only be called on vault creation
     * @param   manager  The address of the manager (owner of the holding)
     */
    function _createManagerHolding(address manager) internal {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();

        require(
            _exists(_MANAGER_TOKEN_ID) == false,
            'manager holding already exists'
        );
        require(
            l._tokenIdCounter == _MANAGER_TOKEN_ID,
            'manager holding must be token 0'
        );
        _mint(manager);
    }

    /**
     * @notice  Creates the protocol holding
     * @dev     Should only be called on vault creation
     * @param   protocolTreasury  The address of the protocol treasury (the owner of the holding)
     */
    function _createProtocolHolding(address protocolTreasury) internal {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();

        require(
            _exists(_PROTOCOL_TOKEN_ID) == false,
            'protcool holding already exists'
        );
        require(
            l._tokenIdCounter == _PROTOCOL_TOKEN_ID,
            'protocol holding must be token 1'
        );
        _mint(protocolTreasury);
    }

    /**
     * @notice  Issues shares to the given tokenId
     * @dev     If tokenId == 0, a new holding is created. If the tokenId exists, shares are issued to existing holding
     * @dev     If holding exists it first levies any unpaid fees before issuing new shares
     * @param   tokenId  The tokenId of the holding or 0
     * @param   owner  The owner of the holding
     * @param   shares  The number of shares to issue
     * @param   currentUnitPrice  The current unit price of the vault (for performanceFees and averageEntry)
     * @param   lockupTime  The lockup time that should be placed on the holding
     * @param   protocolFeeBips  The protocol fee in basis points
     * @param   referrerAddress  The address of the referrer
     * @return  uint  The tokenId of the holding where the shares were issued
     */
    function _issueShares(
        uint tokenId,
        address owner,
        uint shares,
        uint currentUnitPrice,
        uint lockupTime,
        uint protocolFeeBips,
        address referrerAddress
    ) internal returns (uint) {
        // Managers cannot deposit directly into their holding, they can only accrue fees there.
        // Users or the Manger can pass tokenId == 0 (which exists) and it will create a new holding for them.
        // This protects against a user depositing to a holding that has not been initialized yet.
        require(_exists(tokenId), 'token does not exist');

        if (tokenId == 0) {
            tokenId = _mint(owner);
            _setReferrer(tokenId, referrerAddress);
        }

        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        VaultOwnershipStorage.Holding storage holding = l.holdings[tokenId];

        if (holding.totalShares == 0) {
            holding.streamingFee = _managerStreamingFee();
            holding.performanceFee = _managerPerformanceFee();
            holding.lastStreamingFeeTime = block.timestamp;
            holding.lastPerformanceFeeUnitPrice = currentUnitPrice;
            holding.averageEntryPrice = currentUnitPrice;
        } else {
            _levyFees(tokenId, currentUnitPrice, protocolFeeBips);
            holding.averageEntryPrice = _calculateAverageEntryPrice(
                holding.totalShares,
                holding.averageEntryPrice,
                shares,
                currentUnitPrice
            );
        }

        l.totalShares += shares;
        holding.unlockTime = block.timestamp + lockupTime;
        holding.totalShares += shares;

        return tokenId;
    }

    /**
     * @notice  Sets the referrer info for the holding
     * @dev     If there is already a referrer set, it will return early
     * @param   tokenId  The tokenId of the holding
     * @param   referrer  The address of the referrer
     */
    function _setReferrer(uint tokenId, address referrer) internal {
        if (referrer == address(0)) {
            return;
        }

        uint referrerShareBips = _referrerShareBips();
        if (referrerShareBips == 0) {
            return;
        }

        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        l.holdingReferrers[tokenId].referrerAddress = referrer;
        l.holdingReferrers[tokenId].referrerShareBips = referrerShareBips;
        emit ReferrerSet(tokenId, referrer);
    }

    /**
     * @notice  Burns shares from the given holding/tokenId
     * @dev     If the holding is locked, it will revert
     * @param   tokenId  The tokenId of the holding
     * @param   shares   The number of shares to burn
     */
    function _burnShares(uint tokenId, uint shares) internal {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();

        VaultOwnershipStorage.Holding storage holding = l.holdings[tokenId];
        require(!_holdingLocked(tokenId), 'locked');
        require(shares <= holding.totalShares, 'not enough shares');
        holding.lastBurnTime = block.timestamp;
        holding.totalShares -= shares;
        l.totalShares -= shares;
    }

    /**
     * @notice  Levies streaming fees and performance fees against the holding
     * @notice  and distributes them to the protocol, manager, and referrer
     * @dev     If the manager has changed the fees, they will be updated here
     * @dev     once fees are harvested at the current rate
     * @param   tokenId  .
     * @param   currentUnitPrice  .
     * @param   protocolFeeBips  .
     */
    function _levyFees(
        uint tokenId,
        uint currentUnitPrice,
        uint protocolFeeBips
    ) internal {
        if (isSystemToken(tokenId)) {
            return;
        }

        // This modifies the holding, subtracting the fees from totalShares
        (uint streamingFees, uint performanceFees) = _levyFeesOnHolding(
            tokenId,
            _managerStreamingFee(),
            _managerPerformanceFee(),
            currentUnitPrice
        );

        uint protocolFees = _protocolFee(
            streamingFees + performanceFees,
            protocolFeeBips
        );

        // Stack To Deep using struct
        ReferrerInfo memory rInfo = _getReferrerInfoAndCalculateFees(
            tokenId,
            streamingFees + performanceFees,
            currentUnitPrice
        );

        uint managerFees = (streamingFees + performanceFees) -
            protocolFees -
            rInfo.referrerFees;

        require(
            protocolFees + managerFees + rInfo.referrerFees ==
                streamingFees + performanceFees,
            'fee math'
        );

        // Stack To Deep
        {
            VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage
                .layout();

            if (rInfo.referrerFees > 0) {
                l.holdings[rInfo.referrerTokenId].totalShares += rInfo
                    .referrerFees;
            }

            l.holdings[_PROTOCOL_TOKEN_ID].totalShares += protocolFees;
            l.holdings[_MANAGER_TOKEN_ID].totalShares += managerFees;
        }

        emit FeesLeviedOnHolding(
            tokenId,
            streamingFees,
            performanceFees,
            protocolFees,
            rInfo.referrerFees,
            rInfo.referrerTokenId,
            rInfo.referrerAddress,
            managerFees,
            currentUnitPrice
        );
    }

    /**
     * @notice  Calculates the referrers share of fees
     * @dev     Creates a new holding for the referrer if they do not have one
     * @param   tokenId  the tokenId of the holding thats paying referral fees
     * @param   totalFees  the total fees being charged to the above holding
     * @param   currentUnitPrice  the current unit price of the shares
     * @return  referrerInfo  The referrer info including referrers tokenId
     */
    function _getReferrerInfoAndCalculateFees(
        uint tokenId,
        uint totalFees,
        uint currentUnitPrice
    ) internal returns (ReferrerInfo memory referrerInfo) {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();

        VaultOwnershipStorage.HoldingReferrer storage referrer = l
            .holdingReferrers[tokenId];

        referrerInfo.referrerAddress = referrer.referrerAddress;
        if (referrerInfo.referrerAddress == address(0)) {
            return referrerInfo;
        }

        referrerInfo.referrerFees =
            (totalFees * referrer.referrerShareBips) /
            Constants.BASIS_POINTS_DIVISOR;

        if (referrerInfo.referrerFees == 0) {
            return referrerInfo;
        }

        if (_balanceOf(referrer.referrerAddress) == 0) {
            // Create a new holding for the referrer with 0 shares
            referrerInfo.referrerTokenId = _issueShares(
                0, // TokenId == 0 == new holding
                referrerInfo.referrerAddress, // owner
                0, // number of shares
                currentUnitPrice,
                0, // lockupTime
                0, // protocolFeeBips
                address(0)
            );
        } else {
            referrerInfo.referrerTokenId = _tokenOfOwnerByIndex(
                referrerInfo.referrerAddress,
                0
            );
        }
    }

    /**
     * @notice  Levies streaming fees and performance fees against the holding and returns the amount levied
     * @dev     If the manager has changed the fees, they will be updated here,
     * @dev     once fees are harvested at the current rate
     * @dev     The assignment of these fees to the manager, protocol and referrer happens upstream
     * @param   tokenId  the tokenId of the holding
     * @param   newStreamingFee    the managers new streamingFee
     * @param   newPerformanceFee  the managers new performanceFee
     * @param   currentUnitPrice   the current unit price of the shares
     * @return  streamingFees    The amount of streaming fees levied
     * @return  performanceFees  The amount of performance fees levied
     */
    function _levyFeesOnHolding(
        uint tokenId,
        uint newStreamingFee,
        uint newPerformanceFee,
        uint currentUnitPrice
    ) internal returns (uint streamingFees, uint performanceFees) {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        VaultOwnershipStorage.Holding storage holding = l.holdings[tokenId];

        uint initialTotalShares = holding.totalShares;

        holding.lastManagerFeeLevyTime = block.timestamp;

        (streamingFees, performanceFees) = _calculateUnpaidFees(
            tokenId,
            currentUnitPrice
        );

        if (streamingFees > 0 || holding.streamingFee != newStreamingFee) {
            holding.lastStreamingFeeTime = block.timestamp;
        }

        if (
            performanceFees > 0 ||
            (holding.performanceFee != newPerformanceFee &&
                currentUnitPrice > holding.lastPerformanceFeeUnitPrice)
        ) {
            holding.lastPerformanceFeeUnitPrice = currentUnitPrice;
        }

        if (holding.streamingFee != newStreamingFee) {
            holding.streamingFee = newStreamingFee;
        }

        if (holding.performanceFee != newPerformanceFee) {
            holding.performanceFee = newPerformanceFee;
        }

        holding.totalShares -= streamingFees + performanceFees;

        require(
            holding.totalShares + streamingFees + performanceFees ==
                initialTotalShares,
            'check failed'
        );

        return (streamingFees, performanceFees);
    }

    /**
     * @notice  Allows the manager to set a fee discount for a holding
     * @dev     The discount is denominated in basis points
     * @param   tokenId  The tokenId of the holding
     * @param   streamingFeeDiscount  the discount on the streaming fee
     * @param   performanceFeeDiscount  the discount on the performance fee
     */
    function _setDiscountForHolding(
        uint tokenId,
        uint streamingFeeDiscount,
        uint performanceFeeDiscount
    ) internal {
        require(
            streamingFeeDiscount <= Constants.BASIS_POINTS_DIVISOR,
            'invalid streamingFeeDiscount'
        );
        require(
            performanceFeeDiscount <= Constants.BASIS_POINTS_DIVISOR,
            'invalid performanceFeeDiscount'
        );

        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        VaultOwnershipStorage.Holding storage holding = l.holdings[tokenId];

        holding.streamingFeeDiscount = streamingFeeDiscount;
        holding.performanceFeeDiscount = performanceFeeDiscount;
    }

    /**
     * @notice  Returns the holding for the given tokenId
     * @param   tokenId  The tokenId of the holding
     * @return  VaultOwnershipStorage.Holding  The holding
     */
    function _holdings(
        uint tokenId
    ) internal view returns (VaultOwnershipStorage.Holding memory) {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        return l.holdings[tokenId];
    }

    /**
     * @notice  Returns of the holding is under lockup
     * @param   tokenId  The tokenId of the holding
     * @return  bool  True if the holding is locked
     */
    function _holdingLocked(uint tokenId) internal view returns (bool) {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();

        VaultOwnershipStorage.Holding storage holding = l.holdings[tokenId];
        if (block.timestamp < holding.unlockTime) {
            return true;
        }

        return false;
    }

    /**
     * @notice  Returns the referrer for the given tokenId
     * @param   tokenId  The tokenId of the holding
     * @return  VaultOwnershipStorage.HoldingReferrer  The referrer info
     */
    function _holdingReferrer(
        uint tokenId
    ) internal view returns (VaultOwnershipStorage.HoldingReferrer memory) {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        return l.holdingReferrers[tokenId];
    }

    /**
     * @notice  Returns the total number of shares across all holdings
     * @dev     This is used to calculate the unit price of the vault and determine a holdings portion
     * @return  uint  The total number of shares
     */
    function _totalShares() internal view returns (uint) {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        return l.totalShares;
    }

    /**
     * @notice  Returns the number of owed fees for the given tokenId and the given tokenPrice
     * @dev     This is used to calculate the amount of fees owed to the manager, protocol, and referrer
     * @param   tokenId  The tokenId of the holding
     * @param   currentUnitPrice  The current unit price of the vault
     * @return  streamingFees  The amount of streaming fees owed
     * @return  performanceFees  The amount of performance fees owed
     */
    function _calculateUnpaidFees(
        uint tokenId,
        uint currentUnitPrice
    ) internal view returns (uint streamingFees, uint performanceFees) {
        if (isSystemToken(tokenId)) {
            return (0, 0);
        }

        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        VaultOwnershipStorage.Holding storage holding = l.holdings[tokenId];

        uint initialTotalShares = holding.totalShares;

        streamingFees = _streamingFee(
            holding.streamingFee,
            holding.streamingFeeDiscount,
            holding.lastStreamingFeeTime,
            initialTotalShares,
            block.timestamp
        );

        performanceFees = _performanceFee(
            holding.performanceFee,
            holding.performanceFeeDiscount,
            // We levy performance fees after levying streamingFees
            initialTotalShares - streamingFees,
            holding.lastPerformanceFeeUnitPrice,
            currentUnitPrice
        );
    }

    /**
     * @notice  Returns the name of the Vault
     * @dev     This is used to identify the vault in the UI
     * @return  string  The name of the vault
     */
    function _name() internal view virtual returns (string memory) {
        return ERC721MetadataStorage.layout().name;
    }

    /**
     * @notice  Returns the average entry price based on the price paid for existing shares
     * @notice  and the price paid for new shares
     * @param   currentShares  The number of shares currently held
     * @param   previousPrice  The average price paid for the above shares
     * @param   newShares  The number of new shares being issued
     * @param   newPrice  The price paid for the new shares
     * @return  uint  The average price paid for all shares
     */
    function _calculateAverageEntryPrice(
        uint currentShares,
        uint previousPrice,
        uint newShares,
        uint newPrice
    ) internal pure returns (uint) {
        return
            ((currentShares * previousPrice) + (newShares * newPrice)) /
            (currentShares + newShares);
    }

    /**
     * @notice  Returns if the tokenId is a system token
     * @dev     System tokens are the manager and protocol holdings
     * @param   tokenId  The tokenId of the holding
     * @return  bool  True if the tokenId is a system token
     */
    function isSystemToken(uint tokenId) internal pure returns (bool) {
        return tokenId == _PROTOCOL_TOKEN_ID || tokenId == _MANAGER_TOKEN_ID;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library VaultOwnershipStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.VaultOwnership');

    // TODO: Move to interface
    // solhint-disable-next-line ordering
    struct Holding {
        uint totalShares;
        uint lastStreamingFeeTime;
        uint lastPerformanceFeeUnitPrice;
        uint streamingFeeDiscount;
        uint performanceFeeDiscount;
        uint streamingFee;
        uint performanceFee;
        uint unlockTime;
        uint averageEntryPrice;
        uint lastManagerFeeLevyTime;
        uint lastBurnTime;
    }

    struct HoldingReferrer {
        address referrerAddress;
        uint256 referrerShareBips;
    }

    // solhint-disable-next-line ordering
    struct Layout {
        // The manager is issued token 0; The protocol is issued token 1; all other tokens are issued to investors
        // All fees are levied to token 0 and a portion to token 1;
        // tokenId to Holding
        mapping(uint => Holding) holdings;
        uint totalShares;
        uint256 _tokenIdCounter;
        // tokenId -> referrer
        mapping(uint => HoldingReferrer) holdingReferrers;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVaultParentInvestor {
    function withdrawMultiChain(
        uint tokenId,
        uint amount,
        uint[] memory lzFees
    ) external payable;

    function requestTotalValueUpdateMultiChain(
        uint[] memory lzFees
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVaultParentManager {
    function requestBridgeToChain(
        uint16 dstChainId,
        address asset,
        uint256 amount,
        uint256 minAmountOut,
        uint
    ) external payable;

    function requestCreateChild(uint16 newChainId, uint) external payable;

    function sendBridgeApproval(uint16 dstChainId, uint) external payable;

    function changeManagerMultiChain(
        address newManager,
        uint[] memory lzFees
    ) external payable;

    function setDiscountForHolding(
        uint256 tokenId,
        uint256 streamingFeeDiscount,
        uint256 performanceFeeDiscount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { VaultParentTransport } from './VaultParentTransport.sol';
import { VaultParentInvestor } from './VaultParentInvestor.sol';
import { VaultParentManager } from './VaultParentManager.sol';
import { VaultParentErc721 } from './VaultParentErc721.sol';
import { VaultParentInternal } from './VaultParentInternal.sol';
import { VaultBaseExternal } from '../vault-base/VaultBaseExternal.sol';
import { VaultOwnershipInternal } from '../vault-ownership/VaultOwnershipInternal.sol';
import { IRedeemerEvents } from '../redeemers/IRedeemerEvents.sol';
import { IExecutorEvents } from '../executors/IExecutorEvents.sol';

import { SolidStateERC721 } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';
import { ERC721MetadataInternal } from '@solidstate/contracts/token/ERC721/metadata/ERC721MetadataInternal.sol';
import { ERC721BaseInternal, ERC165Base } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';

/**
 * @title   VaultParent
 * @dev     Not deployed as It's to large, never deploy for tests always use diamond
 * @dev     The components inherited make up the VaultParentDiamond
 * @notice  ONLY used to generate the ABI and for test interface
 */

contract VaultParent is
    VaultParentInvestor,
    VaultParentErc721,
    VaultParentManager,
    VaultParentTransport,
    VaultBaseExternal,
    IRedeemerEvents,
    IExecutorEvents
{
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(VaultParentErc721, VaultParentInternal) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice ERC721 hook: revert if value is included in external approve function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual override(VaultParentErc721, ERC721BaseInternal) {
        if (value > 0) revert SolidStateERC721__PayableApproveNotSupported();
        super._handleApproveMessageValue(operator, tokenId, value);
    }

    /**
     * @notice ERC721 hook: revert if value is included in external transfer function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual override(VaultParentErc721, ERC721BaseInternal) {
        if (value > 0) revert SolidStateERC721__PayableTransferNotSupported();
        super._handleTransferMessageValue(from, to, tokenId, value);
    }

    function _name()
        internal
        view
        override(VaultOwnershipInternal, VaultParentInvestor, VaultParentErc721)
        returns (string memory)
    {
        return VaultOwnershipInternal._name();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { SolidStateERC721, ERC721BaseInternal } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';
import { ERC721MetadataInternal } from '@solidstate/contracts/token/ERC721/metadata/ERC721MetadataInternal.sol';
import { IERC165 } from '@solidstate/contracts/interfaces/IERC165.sol';
import { IERC721 } from '@solidstate/contracts/interfaces/IERC721.sol';

import { ITransport } from '../transport/ITransport.sol';
import { Registry } from '../registry/Registry.sol';
import { RegistryStorage } from '../registry/RegistryStorage.sol';
import { VaultParentStorage } from './VaultParentStorage.sol';
import { VaultParentInternal } from './VaultParentInternal.sol';
import { VaultBaseInternal } from '../vault-base/VaultBaseInternal.sol';
import { VaultOwnershipInternal } from '../vault-ownership/VaultOwnershipInternal.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';
import { Constants } from '../lib/Constants.sol';

/**
 * @title   VaultParentErc721
 * @dev     One of the components of the VaultParent
 * @dev     Exposes `initialize` function to set up the VaultParent
 * @notice  Used to expost the ERC721 interface to the VaultParent
 */

contract VaultParentErc721 is SolidStateERC721, VaultParentInternal {
    /**
     * @notice  Initializes the VaultParent
     * @dev     Calls all other superclass initializers
     * @param   __name  The name of the Vault
     * @param   __symbol  The symbol of the Vault aka Ticker
     * @param   __manager  The manager of the Vault
     * @param   __managerStreamingFeeBasisPoints  the manager streaming fee in basis points
     * @param   __managerPerformanceFeeBasisPoints  the manager performance fee in basis points
     * @param   __riskProfile  The risk profile of the Vault
     * @param   __registry  The valio registry
     */
    function initialize(
        string memory __name,
        string memory __symbol,
        address __manager,
        uint __managerStreamingFeeBasisPoints,
        uint __managerPerformanceFeeBasisPoints,
        VaultRiskProfile __riskProfile,
        Registry __registry
    ) external {
        require(_vaultId() == 0, 'already initialized');

        bytes32 vaultId = keccak256(
            abi.encodePacked(__registry.chainId(), address(this))
        );
        _setVaultId(vaultId);
        VaultBaseInternal.initialize(__registry, __manager, __riskProfile);
        VaultOwnershipInternal.initialize(
            __name,
            __symbol,
            __manager,
            __managerStreamingFeeBasisPoints,
            __managerPerformanceFeeBasisPoints,
            __registry.protocolTreasury()
        );

        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IERC721).interfaceId, true);
    }

    /**
     * @notice  ERC721 hook: reverts, transfers are disabled
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(SolidStateERC721, VaultParentInternal) {
        VaultParentInternal._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice ERC721 hook: revert if value is included in external approve function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual override(SolidStateERC721, ERC721BaseInternal) {
        if (value > 0) revert SolidStateERC721__PayableApproveNotSupported();
        super._handleApproveMessageValue(operator, tokenId, value);
    }

    /**
     * @notice ERC721 hook: revert if value is included in external transfer function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual override(SolidStateERC721, ERC721BaseInternal) {
        if (value > 0) revert SolidStateERC721__PayableTransferNotSupported();
        super._handleTransferMessageValue(from, to, tokenId, value);
    }

    /**
     * @notice  Returns the name of the Vault
     * @return  string  name
     */
    function _name()
        internal
        view
        virtual
        override(VaultOwnershipInternal, ERC721MetadataInternal)
        returns (string memory)
    {
        return VaultOwnershipInternal._name();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { VaultBaseInternal } from '../vault-base/VaultBaseInternal.sol';
import { VaultOwnershipInternal } from '../vault-ownership/VaultOwnershipInternal.sol';
import { VaultParentStorage } from './VaultParentStorage.sol';
import { IVaultParentManager } from './IVaultParentManager.sol';
import { IVaultParentInvestor } from './IVaultParentInvestor.sol';

import { GasFunctionType } from '../transport/ITransport.sol';

import { Constants } from '../lib/Constants.sol';

/**
 * @title   VaultParentInternal
 * @notice  Logic shared between other VaultParent components
 * @dev     Should be split up
 */

contract VaultParentInternal is VaultOwnershipInternal, VaultBaseInternal {
    /**
     * @notice  Reverts if a brige is in progress
     * @dev     This means funds could be inflight
     */
    modifier noBridgeInProgress() {
        require(!_bridgeInProgress(), 'bridge in progress');
        _;
    }

    /**
     * @notice  Reverts if a vault is closed
     * @dev     This means users can no longer deposit
     */
    modifier vaultNotClosed() {
        require(!_vaultClosed(), 'vault closed');
        _;
    }

    /**
     * @notice  Blocks transfers of tokens
     * @dev     The managers token can be transferred to a new manager internally
     * @param   from  the previous token owner
     * @param   to  the new token owner
     * @param   tokenId  the token id
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        // If minting just return
        if (from == address(0)) {
            return;
        }
        // When using changeManager(), allow transfer to new manager
        if (tokenId == _MANAGER_TOKEN_ID) {
            require(to == _manager(), 'must use changeManager');
            return;
        }

        revert('transfers disabled');
    }

    /**
     * @notice  Returns true of a withdraw is in progress
     * @dev     This means there are outstanding withdraw requests being processed
     * @dev     When a child vault receives a withdraw request, once complete it sends back a withdraw complete message
     * @dev     All outstanding withdraws must be complete this will return false
     * @return  bool  true if a withdraw is in progress
     */
    function _withdrawInProgress() internal view returns (bool) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        return l.withdrawsInProgress > 0;
    }

    /**
     * @notice  Returns true if a bridge is in progress
     * @dev     This means funds could be inflight
     * @return  bool  true if a bridge is in progress
     */
    function _bridgeInProgress() internal view returns (bool) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        return l.bridgeInProgress;
    }

    /**
     * @notice  Returns which child chain is approved to bridge
     * @dev     The child chain must bridge or cancel the bridge to remove the approval
     * @return  uint  the lz child chain id
     */
    function _bridgeApprovedFor() internal view returns (uint16) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        return l.bridgeApprovedFor;
    }

    /**
     * @notice  Returns if the vault has any active child vaults
     * @dev     An active child vault is one that has received funds at some point
     * @dev     Currently once a childVault is active, its always active
     * @return  bool  .
     */
    function _hasActiveChildren() internal view returns (bool) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        for (uint8 i = 0; i < l.childChains.length; i++) {
            if (!_childIsInactive(l.childChains[i])) {
                return true;
            }
        }
        return false;
    }

    /**


    /**
     * @notice  Returns the lz fee for the give function
     * @dev     This is a helper method for the frontend
     * @dev     We use the sighash of the intended function call to identify the action
     * @param   sigHash  The sighash of the intended function call
     * @param   chainId  The destination lz chain id
     * @return  fee  The lz fee for the message + destination gas
     */
    function _getLzFee(
        bytes4 sigHash,
        uint16 chainId
    ) internal view returns (uint fee) {
        if (sigHash == IVaultParentManager.requestBridgeToChain.selector) {
            fee = _bridgeQuote(chainId);
        } else if (sigHash == IVaultParentManager.requestCreateChild.selector) {
            (fee, ) = _registry().transport().getLzFee(
                GasFunctionType.createChildRequiresReturnMessage,
                chainId
            );
        } else if (
            sigHash ==
            IVaultParentInvestor.requestTotalValueUpdateMultiChain.selector
        ) {
            if (_childIsInactive(chainId)) {
                return 0;
            }
            (fee, ) = _registry().transport().getLzFee(
                GasFunctionType.getVaultValueRequiresReturnMessage,
                chainId
            );
        } else if (
            sigHash == IVaultParentInvestor.withdrawMultiChain.selector
        ) {
            if (_childIsInactive(chainId)) {
                return 0;
            }
            (fee, ) = _registry().transport().getLzFee(
                GasFunctionType.withdrawRequiresReturnMessage,
                chainId
            );
        } else if (sigHash == IVaultParentManager.sendBridgeApproval.selector) {
            (fee, ) = _registry().transport().getLzFee(
                GasFunctionType.sendBridgeApprovalNoReturnMessage,
                chainId
            );
        } else {
            (fee, ) = _registry().transport().getLzFee(
                GasFunctionType.standardNoReturnMessage,
                chainId
            );
        }
    }

    /**
     * @notice  Returns the lz fees for the given function on all child chains
     * @dev     This is a helper method for the frontend
     * @dev     We use the sighash of the intended function call to identify the action
     * @param   sigHash  The sighash of the intended function call
     * @param   chainIds  The destination lz chain ids
     * @return  fees  The lz fees for the message + destination gas
     * @return  totalSendFee  The total lz fee for the message + destination gas
     */
    function _getLzFeesMultiChain(
        bytes4 sigHash,
        uint16[] memory chainIds
    ) internal view returns (uint[] memory fees, uint256 totalSendFee) {
        fees = new uint[](chainIds.length);
        for (uint i = 0; i < chainIds.length; i++) {
            fees[i] = _getLzFee(sigHash, chainIds[i]);
            totalSendFee += fees[i];
        }
    }

    /**
     * @notice  Returns the fee for executing a bridge
     * @dev     Currently this is stargate, but could be different in the future
     * @param   dstChainId  The destination lz chain id
     * @return  fee  The stargate fee for the bridge
     */
    function _bridgeQuote(uint16 dstChainId) internal view returns (uint fee) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        address dstVault = l.children[dstChainId];
        require(dstVault != address(0), 'no dst vault');

        fee = _registry().transport().getBridgeAssetQuote(
            dstChainId,
            dstVault,
            _registry().chainId(),
            address(this)
        );
    }

    /**
     * @notice  Returns if a child is not active
     * @dev     The child active state was added after the initial release
     * @dev     Therefore inverse storage flag is used
     * @param   chainId  The lz chain id of the child
     * @return  bool  false if the child is active
     */
    function _childIsInactive(uint16 chainId) internal view returns (bool) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        return l.childIsInactive[chainId];
    }

    /**
     * @notice  Returns if the vault is in sync
     * @dev     This means the vault has the latest value for all child vaults
     * @return  bool  true if the vault is in sync
     */
    function _inSync() internal view returns (bool) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        for (uint8 i = 0; i < l.childChains.length; i++) {
            if (_childIsInactive(l.childChains[i])) {
                continue;
            }
            if (_isNotStale(l.chainTotalValues[l.childChains[i]].lastUpdate)) {
                continue;
            } else {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice  Returns the total value of the vault across all chains (AUM)
     * @dev     Will revert if the child vault values are stale
     * @return  minValue  the min value
     * @return  maxValue  the max value
     * @return  hasHardDeprecatedAsset  if the vault has a hard deprecated asse
     */
    function _totalValueAcrossAllChains()
        internal
        view
        returns (uint minValue, uint maxValue, bool hasHardDeprecatedAsset)
    {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        (minValue, maxValue, hasHardDeprecatedAsset) = _getVaultValue();

        for (uint8 i = 0; i < l.childChains.length; i++) {
            if (_childIsInactive(l.childChains[i])) {
                continue;
            }
            require(
                _isNotStale(l.chainTotalValues[l.childChains[i]].lastUpdate),
                'stale'
            );
            minValue += l.chainTotalValues[l.childChains[i]].minValue;
            maxValue += l.chainTotalValues[l.childChains[i]].maxValue;
            if (l.chainTotalValues[l.childChains[i]].hasHardDeprecatedAsset) {
                hasHardDeprecatedAsset = true;
            }
        }
    }

    /**
     * @notice  Returns the unitPrice of each share in the vault (AUM/shares)
     * @dev     This is returned at Contants.VAULT_PRECISION
     * @return  minPrice  The min price of each share
     * @return  maxPrice  The max price of each share
     */
    function _unitPrice() internal view returns (uint minPrice, uint maxPrice) {
        uint totalShares = _totalShares();
        (uint minValue, uint maxValue, ) = _totalValueAcrossAllChains();
        // Avoids divide by 0;
        if (totalShares == 0 && maxValue == 0) {
            return (0, 0);
        }
        // This should never occur. It's a safety check
        if (totalShares == 0 && maxValue != 0) {
            revert('Vault Error: ttsnvl');
        }

        minPrice = _unitPrice(minValue, totalShares);
        maxPrice = _unitPrice(maxValue, totalShares);
    }

    /**
     * @notice  Returns the lzChainId of the child at the given index
     * @dev     We store a list of lzChainId[] for the child vaults created
     * @param   index  The index
     * @return  chainId  The lz chain id
     */
    function _childChains(uint index) internal view returns (uint16 chainId) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        return l.childChains[index];
    }

    /**
     * @notice  The list of lz chainIds for all child vaults created
     * @dev     We store a list of lzChainId[] for the child vaults created
     * @return  uint16[]  The list of lz chainIds
     */
    function _allChildChains() internal view returns (uint16[] memory) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        return l.childChains;
    }

    /**
     * @notice  Returns the child vault address for the given lz chain id
     * @dev     We store a mapping of lzChainId => childVaultAddress
     * @param   chainId  The lz chain id
     * @return  address  The child vault address
     */
    function _children(uint16 chainId) internal view returns (address) {
        return VaultParentStorage.layout().children[chainId];
    }

    /**
     * @notice  Returns the time until the oldest child vault value expires
     * @dev     This should be named better vaultVaultTimeUntilExpiry
     * @return  uint  The time until the oldest child vault value expires
     */
    function _timeUntilExpiry() internal view returns (uint) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        uint timeTillExpiry;
        for (uint8 i = 0; i < l.childChains.length; i++) {
            uint expiryTime = _timeUntilExpiry(
                l.chainTotalValues[l.childChains[i]].lastUpdate
            );
            // The shortest expiry time is the time until expiry
            if (expiryTime == 0) {
                return 0;
            } else {
                if (expiryTime < timeTillExpiry || timeTillExpiry == 0) {
                    timeTillExpiry = expiryTime;
                }
            }
        }
        return timeTillExpiry;
    }

    /**
     * @notice  Returns if the vault is closed
     * @dev     This means users can no longer deposit
     * @return  bool  true if the vault is closed
     */
    function _vaultClosed() internal view returns (bool) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        return l.vaultClosed;
    }

    /**
     * @notice  Returns how long until the given lastUpdate time is stale
     * @dev     This is the time until the value of the child vault is stale
     * @param   lastUpdate  The last time the child vault value was updated
     * @return  uint  The time until the value is stale
     */
    function _timeUntilExpiry(uint lastUpdate) internal view returns (uint) {
        uint expiry = lastUpdate + _registry().livelinessThreshold();
        if (expiry > block.timestamp) {
            return expiry - block.timestamp;
        } else {
            return 0;
        }
    }

    /**
     * @notice  Returns if the given lastUpdate time is not yet stale
     * @dev     Should have been isStale
     * @param   lastUpdate  The last time the child vault value was updated
     * @return  bool  true if the value is not stale
     */
    function _isNotStale(uint lastUpdate) internal view returns (bool) {
        return lastUpdate > block.timestamp - _registry().livelinessThreshold();
    }

    /**
     * @notice  Returns if the given tokenId requires a sync to harvest fees
     * @param   tokenId  The tokenId of holding
     * @return  bool  true if the tokenId requires a sync to harvest fees
     */
    function _requiresSyncForFees(uint tokenId) internal view returns (bool) {
        if (!_hasActiveChildren() || !_requiresUnitPrice(tokenId)) {
            return false;
        }
        return true;
    }

    /**
     * @notice  Returns if the given tokenId requires a unit price to harvest fees
     * @dev     False if the manager has no performamce fee or the tokenId is a system token
     * @param   tokenId  The tokenId of holding
     * @return  bool  true if the tokenId requires a unit price to harvest fees
     */
    function _requiresUnitPrice(uint tokenId) internal view returns (bool) {
        if (isSystemToken(tokenId)) {
            return false;
        }
        if (
            (_managerPerformanceFee() == 0 &&
                _holdings(tokenId).performanceFee == 0)
        ) {
            return false;
        }

        return true;
    }

    /**
     * @notice  Calculates the unitPrice from the given AUM and Shares
     * @param   totalValueAcrossAllChains  The vaults total aum
     * @param   totalShares  The total outstanding shares
     * @return  price  The unit price of each share
     */
    function _unitPrice(
        uint totalValueAcrossAllChains,
        uint totalShares
    ) internal pure returns (uint price) {
        price =
            (totalValueAcrossAllChains * Constants.VAULT_PRECISION) /
            totalShares;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ITransport } from '../transport/ITransport.sol';
import { Constants } from '../lib/Constants.sol';
import { VaultParentStorage } from './VaultParentStorage.sol';
import { VaultParentInternal } from './VaultParentInternal.sol';
import { VaultParentPermitInternal } from './VaultParentPermitInternal.sol';
import { VaultParentPermitLib } from './VaultParentPermitLib.sol';
import { IVaultParentInvestor } from './IVaultParentInvestor.sol';
import { VaultOwnershipInternal } from '../vault-ownership/VaultOwnershipInternal.sol';

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';

/**
 * @title   VaultParentInvestor
 * @notice  Contains logic for depositing and withdrawing from the vault
 * @dev     Apart of the VaultParent Diamond
 */

contract VaultParentInvestor is
    VaultParentInternal,
    VaultParentPermitInternal,
    IVaultParentInvestor
{
    using SafeERC20 for IERC20;

    struct DepositParams {
        address payer;
        address owner;
        uint tokenId;
        address asset;
        uint amount;
        uint acceptableUnitPrice;
        address referrer;
    }

    event Deposit(
        address depositer,
        uint tokenId,
        address asset,
        uint amount,
        uint currentUnitPrice,
        uint shares
    );

    event WithdrawMultiChain(
        address withdrawer,
        uint tokenId,
        uint portion,
        uint currentUnitPrice,
        uint shares
    );

    /**
     * @notice  This modifier checks if the vault is in the process executing withdraws
     * @dev     We don't allow total value syncs to be initiated during withdraw.
     * @dev     Any vault value messages received after a withdraw is initiated are ignored.
     */
    modifier noWithdrawInProgress() {
        require(!_withdrawInProgress(), 'withdraw in progress');
        _;
    }

    /**
     * @notice  This iniates a `sync` with all the child vaults
     * @dev     The vault is considered insync once it has fresh values from all children
     * @param   lzFees  An array of fees, one for each child chain
     */
    function requestTotalValueUpdateMultiChain(
        uint[] memory lzFees
    ) external payable noBridgeInProgress noWithdrawInProgress whenNotPaused {
        _requestTotalValueUpdateMultiChain(lzFees);
    }

    /**
     * @notice  Allows a deposit to be executed with a 712 Permit
     * @dev     Anyone can relay the Permit on chain.
     * @dev     The ERC20 Permitter and DepositPermitter must be the same
     * @param   _depositPermit  .
     */
    function depositPermit(
        DepositPermit memory _depositPermit
    )
        external
        nonReentrant
        vaultNotClosed
        noBridgeInProgress
        whenNotPaused
        returns (address signer)
    {
        signer = _depositPermitVerifyGetSigner(_depositPermit);

        _deposit(
            DepositParams({
                payer: signer,
                owner: signer,
                tokenId: _depositPermit.tokenId,
                asset: _depositPermit.erc20Permit.token,
                amount: _depositPermit.erc20Permit.value,
                acceptableUnitPrice: _depositPermit.acceptableUnitPrice,
                referrer: _depositPermit.referrer
            })
        );
    }

    /**
     * @notice  Allows a withdraw to be executed with a 712 Permit
     * @dev     Anyone can relay the Permit on chain, the owner just signs
     * @param   _withdrawPermit  The parameters for the withdraw + signature
     * @param   lzFees  The fees to send the withdraw request to each child chain
     */
    function withdrawPermit(
        WithdrawPermit memory _withdrawPermit,
        uint[] memory lzFees
    )
        external
        payable
        nonReentrant
        noBridgeInProgress
        whenNotPaused
        returns (address signer)
    {
        signer = _withdrawPermitVerifyGetSigner(_withdrawPermit);

        // unitPriceTrigger can be set to 0, which will skip this step
        // And redeem the shares at the current unitPrice
        // The vault may still need to be synced if manager needs to harvest fees
        if (_withdrawPermit.unitPriceTrigger != 0) {
            (uint minUnitPrice, ) = _unitPrice();
            if (_withdrawPermit.triggerAbove) {
                require(
                    minUnitPrice > _withdrawPermit.unitPriceTrigger,
                    'unitPriceTrigger: price too low'
                );
            } else {
                require(
                    minUnitPrice < _withdrawPermit.unitPriceTrigger,
                    'unitPriceTrigger: price too high'
                );
            }
        }

        _withdrawMultiChain(
            signer,
            _withdrawPermit.tokenId,
            _withdrawPermit.shares,
            lzFees
        );
    }

    /**
     * @notice  Allows a deposit to be executed by a msg.sender for an owner
     * @dev     DEPRECATED: Added for the DepositAutomator which is now deprecated.
     * @dev     Note: msg.sender is the payer, owner is the owner of the holding
     * @dev     Note: See modifiers for restrictions
     * @param   owner    The owner of the holding or to be owner
     * @param   tokenId  The tokenId of the holding
     * @param   asset  The asset to deposit
     * @param   amount  The amount to deposit
     */
    function depositFor(
        address owner,
        uint tokenId,
        address asset,
        uint amount,
        uint acceptableUnitPrice,
        address referrer
    ) external vaultNotClosed noBridgeInProgress whenNotPaused nonReentrant {
        require(
            msg.sender == _registry().depositAutomator(),
            'only DepositAutomator'
        );
        _deposit(
            DepositParams({
                payer: msg.sender,
                owner: owner,
                tokenId: tokenId,
                asset: asset,
                amount: amount,
                acceptableUnitPrice: acceptableUnitPrice,
                referrer: referrer
            })
        );
    }

    /**
     * @notice  Allows a msg.sender to deposit into a holding
     * @dev     Vault must be `in sync` before calling
     * @dev     Note: See modifiers for restrictions
     * @dev     Note: msg.sender is the payer and owner of the holding
     * @param   tokenId  The tokenId of the holding
     * @param   asset  The asset to deposit
     * @param   amount  The amount to deposit
     * @param   acceptableUnitPrice  The acceptable unit price to pay for shares
     * @param   referrer  The referrer (optional)
     */
    function deposit2(
        uint tokenId,
        address asset,
        uint amount,
        uint acceptableUnitPrice,
        address referrer
    ) external vaultNotClosed noBridgeInProgress whenNotPaused nonReentrant {
        _deposit(
            DepositParams({
                payer: msg.sender,
                owner: msg.sender,
                tokenId: tokenId,
                asset: asset,
                amount: amount,
                acceptableUnitPrice: acceptableUnitPrice,
                referrer: referrer
            })
        );
    }

    /**
     * @notice  Allows a msg.sender to deposit into a holding
     * @dev     DEPRECATED used deposit2 instead, will be replaced with deposit2
     * @dev     Vault must be `in sync` before calling
     * @dev     Note: See modifiers for restrictions
     * @dev     Note: msg.sender is the payer and owner of the holding
     * @param   tokenId  The tokenId of the holding
     * @param   asset  The asset to deposit
     * @param   amount  The amount to deposit
     */
    function deposit(
        uint tokenId,
        address asset,
        uint amount
    ) external vaultNotClosed noBridgeInProgress whenNotPaused nonReentrant {
        _deposit(
            DepositParams({
                payer: msg.sender,
                owner: msg.sender,
                tokenId: tokenId,
                asset: asset,
                amount: amount,
                acceptableUnitPrice: type(uint).max,
                referrer: address(0)
            })
        );
    }

    /**
     * @notice  Allows a msg.sender to withdraw from a holding
     * @dev     msg.sender must be owner of the holding
     * @param   tokenId  The tokenId of the holding
     * @param   amount  The amount of shares to withdraw and burn
     * @param   lzFees  The fees to send the withdraw request to each child chain
     */
    function withdrawMultiChain(
        uint tokenId,
        uint amount,
        uint[] memory lzFees
    ) external payable noBridgeInProgress whenNotPaused nonReentrant {
        _withdrawMultiChain(msg.sender, tokenId, amount, lzFees);
    }

    ///
    /// Internal
    ///

    /**
     * @notice  Deposits an asset into the vault
     * @dev     The vault must be insync if it has active children
     * @param   depositParams  The parameters for the deposit
     */
    function _deposit(DepositParams memory depositParams) internal {
        require(
            _registry().depositAssets(depositParams.asset),
            'not deposit asset'
        );

        /// Hack for now to limit each user to 1 holding
        /// Accept the manager, they can have fee holding + another holding
        /// transferring of tokens is currently disabled
        if (depositParams.tokenId == 0) {
            uint numHoldings = _balanceOf(depositParams.owner);
            if (depositParams.owner == _manager()) {
                require(numHoldings < 2, 'manager already owns holdings');
            } else {
                require(numHoldings < 1, 'already owns holding');
            }
        }

        /// Vaults that have hard deprecated assets cannot be valued accurately
        /// Therefore deposits are blocked until the manager trades out of the asset
        (
            ,
            uint maxVaultValue,
            bool hasHardDeprecatedAsset
        ) = _totalValueAcrossAllChains();

        require(!hasHardDeprecatedAsset, 'holds hard deprecated asset');

        uint totalShares = _totalShares();

        if (totalShares > 0 && maxVaultValue == 0) {
            // This means all the shares issue are currently worthless
            // We can't issue anymore shares
            revert('vault closed');
        }
        (uint depositValueInUSD, ) = _registry().accountant().assetValue(
            depositParams.asset,
            depositParams.amount
        );

        uint customCapForVault = _registry().customVaultValueCap(address(this));

        if (customCapForVault > 0) {
            require(
                maxVaultValue + depositValueInUSD <= customCapForVault,
                'vault will exceed custom cap'
            );
        } else {
            require(
                maxVaultValue + depositValueInUSD <=
                    _registry().vaultValueCap(),
                'vault will exceed cap'
            );
        }

        // if tokenId == 0 means were creating a new holding
        if (depositParams.tokenId == 0) {
            require(
                depositValueInUSD >= _registry().minDepositAmount(),
                'min deposit not met'
            );
        }

        // Note: that we are taking the deposit asset from the payer
        IERC20(depositParams.asset).safeTransferFrom(
            depositParams.payer,
            address(this),
            depositParams.amount
        );
        _updateActiveAsset(depositParams.asset);

        uint shares;
        uint currentUnitPrice;
        if (totalShares == 0) {
            shares = depositValueInUSD;
            // We should debate if the base unit of the vaults is to be 10**18 or 10**8.
            // 10**8 is the natural unit for USD (which is what the unitPrice is denominated in),
            // but 10**18 gives us more precision when it comes to leveling fees.
            currentUnitPrice = _unitPrice(depositValueInUSD, shares);
        } else {
            shares = (depositValueInUSD * totalShares) / maxVaultValue;
            // Don't used unitPrice() because it will encorporate the deposited funds, but shares haven't been issue yet
            currentUnitPrice = _unitPrice(maxVaultValue, totalShares);
        }

        require(
            currentUnitPrice <= depositParams.acceptableUnitPrice,
            'unit price too high'
        );

        uint issuedToTokenId = _issueShares(
            depositParams.tokenId,
            depositParams.owner,
            shares,
            currentUnitPrice,
            _registry().depositLockupTime(),
            _registry().protocolFeeBips(),
            depositParams.referrer
        );

        uint holdingTotalShares = _holdings(issuedToTokenId).totalShares;
        uint holdingTotalValue = (currentUnitPrice * holdingTotalShares) /
            Constants.VAULT_PRECISION;

        // If the vault has a custom cap
        // there is not holding maxDepositAmount
        require(
            customCapForVault > 0 ||
                holdingTotalValue <= _registry().maxDepositAmount(),
            'exceeds max deposit'
        );

        emit Deposit(
            depositParams.owner,
            issuedToTokenId,
            depositParams.asset,
            depositParams.amount,
            currentUnitPrice,
            shares
        );
        _registry().emitEvent();
    }

    /**
     * @notice  Burns shares and redeems assets
     * @dev     Note: the holding owner always receives the assets
     * @dev     If the vault has active children and the manager has performance fees enabled
     * @dev     The vault must be insync
     * @param   _msgSender The msg.sender or permitter
     * @param   tokenId    The tokenId of the holding
     * @param   amount     The amount of shares to burn
     * @param   lzFees     The fees to send the withdraw request to each child chain
     */
    function _withdrawMultiChain(
        address _msgSender,
        uint tokenId,
        uint amount,
        uint[] memory lzFees
    ) internal {
        // Withdraws are always redeemed to the owner
        address owner = _ownerOf(tokenId);
        require(
            _msgSender == owner ||
                _msgSender == _registry().withdrawAutomator(),
            'not allowed'
        );

        uint minUnitPrice = _getFeeLevyUnitPrice(tokenId);
        _levyFees(tokenId, minUnitPrice, _registry().protocolFeeBips());

        uint sharesRemainingAfterFeeLevy = _holdings(tokenId).totalShares;

        // If the shares remaining after the fee levy is less than the amount
        // the user wants to withdraw, we will just withdraw all the remaining shares
        if (sharesRemainingAfterFeeLevy < amount) {
            amount = sharesRemainingAfterFeeLevy;
        }

        uint portion = (amount * Constants.PORTION_DIVISOR) / _totalShares();
        _burnShares(tokenId, amount);
        _withdraw(tokenId, owner, portion);
        _adjustCachedChainTotalValues(portion);
        _sendWithdrawRequestsToChildrenMultiChain(
            tokenId,
            owner,
            portion,
            lzFees
        );

        emit WithdrawMultiChain(owner, tokenId, portion, minUnitPrice, amount);
        _registry().emitEvent();
    }

    /**
     * @notice  Adjusts the cached chain total values for all the child vaults down proportionally
     * @dev     This is called during withdraw. So that other withdraws/deposits can be executed for a single sync
     * @param   withdrawnPortion  The portion of shares that were withdrawn
     */
    function _adjustCachedChainTotalValues(uint withdrawnPortion) internal {
        // We want to allow multiple withdraws to be processed at once.
        // So they can share the same `sync` and not block deposits during withdraw.
        // Because we are burning shares, during withdraw
        // We must adjust the cached values for all the child vaults proportionally
        // Otherwise the unitPrice will be incorrect
        // We block requestTotalValueUpdateMultiChain & receiveChildValue until all withdraws are 100% complete.
        // This was added after the fact and probably could have been achieved in a better way
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        for (uint8 i = 0; i < l.childChains.length; i++) {
            if (_childIsInactive(l.childChains[i])) {
                continue;
            }

            l.chainTotalValues[l.childChains[i]].minValue -=
                (l.chainTotalValues[l.childChains[i]].minValue *
                    withdrawnPortion) /
                Constants.PORTION_DIVISOR;
            l.chainTotalValues[l.childChains[i]].maxValue -=
                (l.chainTotalValues[l.childChains[i]].maxValue *
                    withdrawnPortion) /
                Constants.PORTION_DIVISOR;
        }
    }

    ///
    /// Cross Chain Requests
    ///

    /**
     * @notice  Sends a totalValueUpdateRequest to all the active child vaults
     * @dev     This will force the child vault to send back a vaultValue update
     * @param   lzFees  An array of fees, one for each child chain
     */
    function _requestTotalValueUpdateMultiChain(uint[] memory lzFees) internal {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        uint totalFees;

        for (uint8 i = 0; i < l.childChains.length; i++) {
            if (_childIsInactive(l.childChains[i])) {
                require(lzFees[i] == 0, 'no fee required');
                continue;
            }
            totalFees += lzFees[i];
            uint16 childChainId = l.childChains[i];

            _registry().transport().sendValueUpdateRequest{ value: lzFees[i] }(
                ITransport.ValueUpdateRequest({
                    parentChainId: _registry().chainId(),
                    parentVault: address(this),
                    child: ITransport.ChildVault({
                        vault: l.children[childChainId],
                        chainId: childChainId
                    })
                })
            );
        }

        require(msg.value >= totalFees, 'insufficient fee sent');
    }

    /**
     * @notice  This sends the withdraw requests to all the active child vaults
     * @dev     This will force the child to redeem the assets it holds to the withdrawer
     * @dev     This will force the child vault to send back a withdraw complete update
     * @param   tokenId  The tokenId of the holding (only used for offchain tracking)
     * @param   withdrawer  The address to redeem the assets to
     * @param   portion  The portion of the vault to redeem
     * @param   lzFees  The fees to send the withdraw request to each child chain
     */
    function _sendWithdrawRequestsToChildrenMultiChain(
        uint tokenId,
        address withdrawer,
        uint portion,
        uint[] memory lzFees
    ) internal {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        uint totalFees;
        for (uint8 i = 0; i < l.childChains.length; i++) {
            if (_childIsInactive(l.childChains[i])) {
                require(lzFees[i] == 0, 'no fee required');
                continue;
            }
            totalFees += lzFees[i];
            _sendWithdrawRequest(
                l.childChains[i],
                tokenId,
                withdrawer,
                portion,
                lzFees[i]
            );
        }
        require(msg.value >= totalFees, 'insufficient fee');
    }

    /**
     * @notice  Sends a withdraw request to a child vault
     * @dev     This will force the child to redeem the assets it holds to the withdrawer
     * @dev     This will force the child vault to send back a withdraw complete update
     * @param   dstChainId  The chainId of the destination
     * @param   tokenId  The tokenId of the holding (only used for offchain tracking)
     * @param   withdrawer  The address to redeem the assets to
     * @param   portion  The portion of the vault to redeem
     * @param   sendFee  The lz fee to send the withdraw request to the child chain
     */
    function _sendWithdrawRequest(
        uint16 dstChainId,
        uint tokenId,
        address withdrawer,
        uint portion,
        uint sendFee
    ) internal {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        l.withdrawsInProgress++;
        _registry().transport().sendWithdrawRequest{ value: sendFee }(
            ITransport.WithdrawRequest({
                parentChainId: _registry().chainId(),
                parentVault: address(this),
                child: ITransport.ChildVault({
                    chainId: dstChainId,
                    vault: l.children[dstChainId]
                }),
                tokenId: tokenId,
                withdrawer: withdrawer,
                portion: portion
            })
        );
    }

    /**
     * @notice  Returns the unit price of the vault used to calculate fees
     * @dev     If the vault is not in sync, this will revert
     * @dev     If the Manager is not charging a performance fees we do not need the unitPrice
     * @dev     If tokenId is precluded from paying fees we do not need the unitPrice
     * @param   tokenId  The tokenId of the holding
     * @return  uint  The unit price of the vault
     */
    function _getFeeLevyUnitPrice(uint tokenId) internal view returns (uint) {
        // If a Manager is not charging a performance fee we do not need the currentUnitPrice
        // to process a withdraw, because all withdraws are porpotional.
        // In addition if the tokendId is System Token (manager, protocol). We don't levy fees on these tokens.
        // I don't really like smuggling this logic in here at this level
        // But it means that if a manager isn't charging a performanceFee then we don't have to impose a totalValueSync
        uint minUnitPrice;
        if (!_inSync() && !_requiresUnitPrice(tokenId)) {
            minUnitPrice = 0;
        } else {
            // This will revert if the vault is not in sync
            // We are discarding hasHardDeprecatedAsset because we don't want to block withdraws
            (minUnitPrice, ) = _unitPrice();
        }

        return minUnitPrice;
    }

    /**
     * @notice  Returns the vault name used for eip712
     * @return  string the name of the vault
     */
    function _name()
        internal
        view
        virtual
        override(VaultParentPermitInternal, VaultOwnershipInternal)
        returns (string memory)
    {
        return VaultOwnershipInternal._name();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ITransport } from '../transport/ITransport.sol';
import { IStargateRouter } from '@layerzerolabs/solidity-examples/contracts/interfaces/IStargateRouter.sol';
import { VaultParentStorage } from './VaultParentStorage.sol';
import { VaultParentInternal } from './VaultParentInternal.sol';
import { IVaultParentManager } from './IVaultParentManager.sol';
import { Constants } from '../lib/Constants.sol';
import { VaultOwnershipStorage } from '../vault-ownership/VaultOwnershipStorage.sol';

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';

contract VaultParentManager is VaultParentInternal, IVaultParentManager {
    using SafeERC20 for IERC20;

    uint public constant CLOSE_FEE = 0.027 ether;

    event FundClosed();

    /**
     * @notice  Allows a manager to close their vault
     * @dev     Once closed a vault cannot be deposited into, withdraws can still be made
     * @dev     Cannot be reopened
     */
    function closeVault()
        external
        payable
        vaultNotClosed
        onlyManager
        whenNotPaused
    {
        require(msg.value >= CLOSE_FEE, 'insufficient fee');
        (bool sent, ) = _registry().protocolTreasury().call{ value: msg.value }(
            ''
        );
        require(sent, 'Failed to process close fee');
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        l.vaultClosed = true;
        _registry().emitEvent();
        emit FundClosed();
    }

    /**
     * @notice  Allows manager to set a manager fee discount on a holding
     * @dev     Denominated in basis points 10000 = 100%
     * @param   tokenId  the tokenId of the holding
     * @param   streamingFeeDiscount the discount to apply to the streaming fee
     * @param   performanceFeeDiscount  the discount to apply to the performance fee
     */
    function setDiscountForHolding(
        uint tokenId,
        uint streamingFeeDiscount,
        uint performanceFeeDiscount
    ) external onlyManager whenNotPaused {
        _setDiscountForHolding(
            tokenId,
            streamingFeeDiscount,
            performanceFeeDiscount
        );
    }

    /**
     * @notice  Levies both the streaming and performance fees on a holding
     * @dev     At the moment this function is only callable by the manager
     * @dev     The caller should make sure that each tokenId can harvest fees before calling
     * @dev     This could be revised
     * @param   tokenIds  the tokenIds of the holdings to levy fees on
     */
    function levyFeesOnHoldings(
        uint[] memory tokenIds
    ) external onlyManager whenNotPaused {
        uint minUnitPrice;
        bool isInSync = _inSync();
        if (isInSync) {
            (minUnitPrice, ) = _unitPrice();
        }

        for (uint i = 0; i < tokenIds.length; i++) {
            require(
                block.timestamp >=
                    _holdings(tokenIds[i]).lastManagerFeeLevyTime + 24 hours,
                'already levied this period'
            );
            // If the manager has performance fees enabled and its a multichain
            // vault we must sync the vault before levying fees so we have the correct unitPrice
            if (!isInSync && _requiresSyncForFees(tokenIds[i])) {
                revert('vault not in sync');
            }
            _levyFees(tokenIds[i], minUnitPrice, _registry().protocolFeeBips());
        }
        _registry().emitEvent();
    }

    /// Fees

    /**
     * @notice  Sets the current referrer share
     * @dev     Denominated in basis points 10000 = 100%
     * @dev     Any existing referrers will keep their exsiting share
     * @param   newReferrerShareBips  .
     */
    function setReferrerShareBips(
        uint newReferrerShareBips
    ) external onlyManager whenNotPaused {
        _setReferrerShareBips(newReferrerShareBips);
        _registry().emitEvent();
    }

    /**
     * @notice  Allows the manager to annouce a streaming fee or performance fee increase
     * @dev     They must wait the _FEE_ANNOUNCE_WINDOW before commiting the change
     * @param   newStreamingFee  The streaming fee in basis points
     * @param   newPerformanceFee  The performance fee in basis points
     */
    function announceFeeIncrease(
        uint256 newStreamingFee,
        uint256 newPerformanceFee
    ) external onlyManager whenNotPaused {
        require(_registry().canChangeManagerFees(), 'fee change disabled');
        _announceFeeIncrease(newStreamingFee, newPerformanceFee);
        _registry().emitEvent();
    }

    /**
     * @notice  Commits the fee increase previously announced
     * @dev     Can only be called after _FEE_ANNOUNCE_WINDOW has passed
     */
    function commitFeeIncrease() external onlyManager whenNotPaused {
        _commitFeeIncrease();
        _registry().emitEvent();
    }

    /**
     * @notice  Allows the manager to renounce a fee increase
     * @dev     Can be called at anytime
     */
    function renounceFeeIncrease() external onlyManager whenNotPaused {
        _renounceFeeIncrease();
        _registry().emitEvent();
    }

    // Manager Actions

    /**
     * @notice  Allows the manager to send a bridge approval to a child vault
     * @dev     A childVault cannot bridge unless approved by the parent vault
     * @dev     This is to avoid the case where funds are inflight during a sync or withdraw
     * @dev     The parent vault is locked (no deposits, no withdraws) while there is an outstanding bridge approval
     * @dev     The manager must initate a bridge from the child or cancel the bridge approval from the child
     * @dev     This is not ideal and we are working on a better solution
     * @param   dstChainId  The lzChainId of the child vault
     */
    function sendBridgeApproval(
        uint16 dstChainId,
        uint // unused kept for compatibility
    )
        external
        payable
        nonReentrant
        onlyManager
        noBridgeInProgress
        whenNotPaused
    {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        // If the bridge approval is cancelled the manager is block from initiating another for 1 hour
        // This protects users from being ddos'd and not being able to withdraw
        // because the manager keeps applying a bridge lock
        require(
            l.lastBridgeCancellation + 1 hours < block.timestamp,
            'bridge approval timeout'
        );
        address dstVault = l.children[dstChainId];
        require(dstVault != address(0), 'no dst vault');
        l.bridgeInProgress = true;
        l.bridgeApprovedFor = dstChainId;

        _registry().transport().sendBridgeApproval{ value: msg.value }(
            ITransport.BridgeApprovalRequest({
                approvedChainId: dstChainId,
                approvedVault: dstVault
            })
        );
    }

    /**
     * @notice  Allows the manager to bridge an asset from the parent vault to a child vault
     * @dev     Currently via stargate via the transport layer
     * @dev     Note: the vault is locked until the child receives and acknowledges the bridge
     * @param   dstChainId  The lzChainId of the child vault
     * @param   asset  The address of the asset to bridge
     * @param   amount  The amount of the asset to bridge
     * @param   minAmountOut  The minimum amount of the asset to receive on the child chain
     */
    function requestBridgeToChain(
        uint16 dstChainId,
        address asset,
        uint amount,
        uint minAmountOut,
        uint // unused kept for compatibility
    )
        external
        payable
        nonReentrant
        onlyManager
        noBridgeInProgress
        whenNotPaused
    {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        address dstVault = l.children[dstChainId];
        require(dstVault != address(0), 'no dst vault');
        l.bridgeInProgress = true;
        // Once the manager has bridged we must include the childChains in our total value
        l.childIsInactive[dstChainId] = false;
        _bridgeAsset(
            dstChainId,
            dstVault,
            _registry().chainId(),
            address(this),
            asset,
            amount,
            minAmountOut,
            msg.value
        );
    }

    /**
     * @notice  Allows the manager to create a child vault
     * @dev     1 child vault per chain only
     * @dev     Can only create 1 child at a time, locked until the child acknowledges the creation
     * @param   newChainId  The lzChainId of the child vault
     */
    function requestCreateChild(
        uint16 newChainId,
        uint // unsused kept for compatibility
    ) external payable nonReentrant onlyManager whenNotPaused {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        require(!l.childCreationInProgress, 'sibling creation inprogress');
        require(l.children[newChainId] == address(0), 'sibling exists');
        require(newChainId != _registry().chainId(), 'not same chain');
        l.childCreationInProgress = true;
        ITransport.ChildVault[]
            memory existingChildren = new ITransport.ChildVault[](
                l.childChains.length
            );

        for (uint8 i = 0; i < l.childChains.length; i++) {
            existingChildren[i].chainId = l.childChains[i];
            existingChildren[i].vault = l.children[l.childChains[i]];
        }
        _registry().transport().sendVaultChildCreationRequest{
            value: msg.value
        }(
            ITransport.VaultChildCreationRequest({
                parentVault: address(this),
                parentChainId: _registry().chainId(),
                newChainId: newChainId,
                manager: _manager(),
                riskProfile: _riskProfile(),
                children: existingChildren
            })
        );
    }

    /**
     * @notice  Changes the manager of the parent vault and all children
     * @param   newManager  The address of the new manager
     * @param   lzFees  The fees to send the update message to each child
     */
    function changeManagerMultiChain(
        address newManager,
        uint[] memory lzFees
    ) external payable nonReentrant onlyManager whenNotPaused {
        require(_registry().canChangeManager(), 'manager change disabled');
        require(newManager != address(0), 'invalid newManager');
        address oldManager = _manager();
        _changeManager(newManager);
        _transfer(oldManager, newManager, _MANAGER_TOKEN_ID);
        _sendChangeManagerRequestToChildren(newManager, lzFees);
    }

    /**
     * @notice  Returns true if the parent has anonymous active child vaults
     * @return  bool  True if the parent has active children
     */
    function hasActiveChildren() external view returns (bool) {
        return _hasActiveChildren();
    }

    /**
     * @notice  Returns the total number of all outstanding shares
     * @return  uint  The total number of all outstanding shares
     */
    function totalShares() external view returns (uint) {
        return _totalShares();
    }

    /**
     * @notice  Returns the min and max unitprice for a vault
     * @dev     Will revert if vault is not insync
     * @return  minPrice  The min unit price
     * @return  maxPrice  The max unit price
     */
    function unitPrice() external view returns (uint minPrice, uint maxPrice) {
        return _unitPrice();
    }

    /**
     * @notice  Returns a holding by tokenId
     * @param   tokenId  the tokenId of the holding
     * @return  VaultOwnershipStorage.Holding  The holding struct
     */
    function holdings(
        uint tokenId
    ) external view returns (VaultOwnershipStorage.Holding memory) {
        return _holdings(tokenId);
    }

    /**
     * @notice  Returns if a bridge is in progress
     * @dev     Frontend helper
     * @return  bool  True if a bridge is in progress
     */
    function bridgeInProgress() external view returns (bool) {
        return _bridgeInProgress();
    }

    /**
     * @notice  Returns the lzChainId if there is a outstanding bridge approval
     * @dev     Returns 0 if there is no outstanding bridge approval
     * @return  uint16  the lzChainId or 0
     */
    function bridgeApprovedFor() external view returns (uint16) {
        return _bridgeApprovedFor();
    }

    /**
     * @notice  Calculates the unpaid fees for a holding based on the given unit price
     * @dev     The currentMinUnitPrice can be calculated offChain and used
     * @dev     Used to display owed fees in the frontend
     * @param   tokenId  The tokenId of the holding
     * @param   currentMinUnitPrice  the current minUnitPrice of the vault
     * @return  streamingFees  owed streaming fees denominated in shares
     * @return  performanceFees  owed performance fees denominated in shares
     */
    function calculateUnpaidFees(
        uint tokenId,
        uint currentMinUnitPrice
    ) external view returns (uint streamingFees, uint performanceFees) {
        return _calculateUnpaidFees(tokenId, currentMinUnitPrice);
    }

    /**
     * @notice  Returns if the vault is closed
     * @dev     Helper for frontend
     * @return  bool  True if the vault is closed
     */
    function vaultClosed() external view returns (bool) {
        return _vaultClosed();
    }

    /**
     * @notice  Returns if the tokenId requires a sync for harvesting fees
     * @dev     Helper for the frontend to calculated tokenIds for levyFeesOnHoldings
     * @param   tokenId  the tokenId of the holding
     * @return  bool  True if the tokenId requires a sync for harvesting fees
     */
    function requiresSyncForFees(uint tokenId) external view returns (bool) {
        return _requiresSyncForFees(tokenId);
    }

    /// Fees

    /**
     * @notice  Returns the holdings referrer information
     * @dev     The struct can be empty
     * @param   tokenId  the tokenId of the holding
     * @return  VaultOwnershipStorage.HoldingReferrer  The holding referrer struct
     */
    function holdingReferrer(
        uint tokenId
    ) external view returns (VaultOwnershipStorage.HoldingReferrer memory) {
        return _holdingReferrer(tokenId);
    }

    /**
     * @notice  Returns the current referrer share
     * @dev     Denominated in basis points 10000 = 100%
     * @return  uint  The current referrer share
     */
    function referrerShareBips() external view returns (uint) {
        return _referrerShareBips();
    }

    /**
     * @notice  Returns the current performance fee
     * @dev     Denominated in basis points 10000 = 100%
     * @return  uint  The current performance fee
     */
    function managerPerformanceFee() external view returns (uint) {
        return _managerPerformanceFee();
    }

    /**
     * @notice  Returns the current streaming fee
     * @dev     Denominated in basis points 10000 = 100%
     * @return  uint  The current streaming fee
     */
    function managerStreamingFee() external view returns (uint) {
        return _managerStreamingFee();
    }

    /**
     * @notice  Returns the announced manager performance fee
     * @dev     Denominated in basis points 10000 = 100%
     * @dev     Returns 0 if there is no announced fee increase
     * @return  uint  The announced manager performance fee
     */
    function announcedManagerPerformanceFee() external view returns (uint) {
        return _announcedManagerPerformanceFee();
    }

    /**
     * @notice  Returns the announced manager streaming fee
     * @dev     Denominated in basis points 10000 = 100%
     * @dev     Returns 0 if there is no announced fee increase
     * @return  uint  The announced manager streaming fee
     */
    function announcedManagerStreamingFee() external view returns (uint) {
        return _announcedManagerStreamingFee();
    }

    /**
     * @notice  Returns the timestamp of the announced fee increase
     * @dev     This is when the fee increase was announced
     * @dev     0 if there is not annonced fee increase
     * @return  uint  The timestamp of the announced fee increase
     */
    function announcedFeeIncreaseTimestamp() external view returns (uint) {
        return _announcedFeeIncreaseTimestamp();
    }

    /**
     * @notice  Returns the protocols share of the given fees
     * @param   managerFees  The total fees
     * @return  uint  The protocols share of the given fees
     */
    function protocolFee(uint managerFees) external view returns (uint) {
        return _protocolFee(managerFees, _registry().protocolFeeBips());
    }

    /**
     * @notice  Returns the vaults unit precision
     * @return  uint  The vaults unit precision
     */
    function VAULT_PRECISION() external pure returns (uint) {
        return Constants.VAULT_PRECISION;
    }

    /**
     * @notice  Returns the performance fees owed given the parameters
     * @dev     Helper for the frontend
     * @param   fee  The performance fee in basis points
     * @param   discount  The discount in basis points
     * @param   __totalShares  The total shares
     * @param   tokenPriceStart  The token price at the start
     * @param   tokenPriceFinish  The token price at the finish
     * @return  sharesOwed  the performance fees owed to the manager in shares
     */
    function performanceFee(
        uint fee,
        uint discount,
        uint __totalShares,
        uint tokenPriceStart,
        uint tokenPriceFinish
    ) external pure returns (uint sharesOwed) {
        return
            _performanceFee(
                fee,
                discount,
                __totalShares,
                tokenPriceStart,
                tokenPriceFinish
            );
    }

    /**
     * @notice  Returns the streaming fees owed given the parameters
     * @dev     Helper for the frontend
     * @param   fee  The streaming fee in basis points
     * @param   discount  The discount in basis points
     * @param   lastFeeTime  The last time the fee was levied
     * @param   __totalShares  The total shares
     * @param   timeNow  The current time
     * @return  sharesOwed  the streaming fees owed to the manager in shares
     */
    function streamingFee(
        uint fee,
        uint discount,
        uint lastFeeTime,
        uint __totalShares,
        uint timeNow
    ) external pure returns (uint sharesOwed) {
        return
            _streamingFee(fee, discount, lastFeeTime, __totalShares, timeNow);
    }

    /**
     * @notice  Returns the current fee announce window
     * @dev     The amount of time that needs to pass before a fee change can be commited
     * @return  uint  The current fee announce window
     */
    function FEE_ANNOUNCE_WINDOW() external pure returns (uint) {
        return _FEE_ANNOUNCE_WINDOW;
    }

    /**
     * @notice  Returns the maximum streaming fee that can be set by the manager
     * @dev     Denominated in basis points 10000 = 100%
     * @return  uint  The maximum streaming fee that can be set by the manager
     */
    function MAX_STREAMING_FEE_BASIS_POINTS() external pure returns (uint) {
        return _MAX_STREAMING_FEE_BASIS_POINTS;
    }

    /**
     * @notice  Returns the maximum single step change in the streaming fee that can be made by a manager
     * @dev     Denominated in basis points 10000 = 100%
     * @dev     Manager cannot just immediately go from 0% to 5%
     * @return  uint  The maximum single step change in the streaming fee that can be made by a manager
     */
    function MAX_STREAMING_FEE_BASIS_POINTS_STEP()
        external
        pure
        returns (uint)
    {
        return _MAX_STREAMING_FEE_BASIS_POINTS_STEP;
    }

    /**
     * @notice  Returns the maximum performance fee that can be set by the manager
     * @dev     Denominated in basis points 10000 = 100%
     * @return  uint  The maximum performance fee that can be set by the manager
     */
    function MAX_PERFORMANCE_FEE_BASIS_POINTS() external pure returns (uint) {
        return _MAX_PERFORMANCE_FEE_BASIS_POINTS;
    }

    /**
     * @notice  Returns the duration of the streaming fee period
     * @dev     Currently 365 days, 1% streaming fee is delivered 1/365th per day
     * @return  uint  The duration of the streaming fee period
     */
    function STEAMING_FEE_DURATION() external pure returns (uint) {
        return _STEAMING_FEE_DURATION;
    }

    /**
     * @notice  The tokenId of the manager holding
     * @dev     The manager holding is create on vault creation
     * @return  uint  The tokenId of the manager holding
     */
    function MANAGER_TOKEN_ID() external pure returns (uint) {
        return _MANAGER_TOKEN_ID;
    }

    /**
     * @notice  The tokenId of the protocol holding
     * @dev     The protocol holding is create on vault creation
     * @return  uint  The tokenId of the protocol holding
     */
    function PROTOCOL_TOKEN_ID() external pure returns (uint) {
        return _PROTOCOL_TOKEN_ID;
    }

    /**
     * @notice  Returns the maximum single step change in the performance fee that can be made by a manager
     * @dev     Denominated in basis points 10000 = 100%
     * @dev     Manager cannot just immediately go from 0% to 50%
     * @return  uint  The maximum single step change in the performance fee that can be made by a manager
     */
    function MAX_PERFORMANCE_FEE_BASIS_POINTS_STEP()
        external
        pure
        returns (uint)
    {
        return _MAX_PERFORMANCE_FEE_BASIS_POINTS_STEP;
    }

    /// Internals

    /**
     * @notice  Changes the manager of the parent vault and all children
     * @param   newManager  The address of the new manager
     * @param   lzFees The fees to send the update message to each child
     */
    function _sendChangeManagerRequestToChildren(
        address newManager,
        uint[] memory lzFees
    ) internal {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        uint totalFees;
        for (uint8 i = 0; i < l.childChains.length; i++) {
            totalFees += lzFees[i];
            _sendChangeManagerRequest(l.childChains[i], newManager, lzFees[i]);
        }
        require(msg.value >= totalFees, 'insufficient fee');
    }

    /**
     * @notice  Sends a change manager request to a child vault
     * @param   dstChainId  The lzChainId of the child vault
     * @param   newManager  The address of the new manager
     * @param   sendFee  the lzFee to send the change mesage
     */
    function _sendChangeManagerRequest(
        uint16 dstChainId,
        address newManager,
        uint sendFee
    ) internal {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        _registry().transport().sendChangeManagerRequest{ value: sendFee }(
            ITransport.ChangeManagerRequest({
                child: ITransport.ChildVault({
                    chainId: dstChainId,
                    vault: l.children[dstChainId]
                }),
                newManager: newManager
            })
        );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC2612 } from '@solidstate/contracts/token/ERC20/permit/IERC2612.sol';
import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { IERC20Metadata } from '@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol';
import { ECDSA } from '@solidstate/contracts/cryptography/ECDSA.sol';
import { EIP712 } from '@solidstate/contracts/cryptography/EIP712.sol';

import { VaultParentPermitStorage } from './VaultParentPermitStorage.sol';
import { VaultParentPermitLib, IVaultParentPermit } from './VaultParentPermitLib.sol';
import { TrustlessPermit } from '../lib/TrustlessPermit.sol';

/**
 * @title   VaultParentPermitInternal
 * @notice  Adds EIP712 Permit functionality to the VaultParent
 * @dev     Users can have their withdraws or deposits relayed,
 * @dev     by signing a message with their private key.
 */

abstract contract VaultParentPermitInternal is IVaultParentPermit {
    using VaultParentPermitLib for DepositPermit;
    using VaultParentPermitLib for WithdrawPermit;
    using ECDSA for bytes32;
    using TrustlessPermit for address;

    string public constant version = '1';
    bytes32 public constant VERSION_HASH = keccak256(bytes(version));

    error VaultParentPermit__InvalidParams();
    error VaultParentPermit__NonMatchingSigners();
    error VaultParentPermit__InvalidNonce();
    error VaultParentPermit__Deadline();

    /**
     * @notice  Gets the signer of the deposit permit from the signature
     * @dev     Reverts if the signer of the deposit permit is not the signer of the ERC20 permit
     * @dev     Reverts if the permit is past its deadline
     * @param   depositPermitParams  the deposit permit params
     * @return  signer  the signer of the deposit permit
     */
    function _depositPermitVerifyGetSigner(
        DepositPermit memory depositPermitParams
    ) internal returns (address signer) {
        if (block.timestamp > depositPermitParams.deadline) {
            revert VaultParentPermit__Deadline();
        }

        if (
            depositPermitParams.depositAmount !=
            depositPermitParams.erc20Permit.value
        ) {
            revert VaultParentPermit__InvalidParams();
        }

        signer = _getSigner(
            depositPermitParams.hash(),
            depositPermitParams.signature,
            depositPermitParams.signerNonce
        );

        // This is very important because it also acts as a InvalidSignature signature check
        // ie if the deposit parameters are changed after signing
        if (signer != depositPermitParams.erc20Permit.owner) {
            revert VaultParentPermit__NonMatchingSigners();
        }

        depositPermitParams.erc20Permit.token.trustlessPermit(
            depositPermitParams.erc20Permit.owner,
            address(this),
            depositPermitParams.erc20Permit.value,
            depositPermitParams.erc20Permit.deadline,
            depositPermitParams.erc20Permit.v,
            depositPermitParams.erc20Permit.r,
            depositPermitParams.erc20Permit.s
        );

        _useNonce(signer, depositPermitParams.signerNonce);
    }

    /**
     * @notice  Gets the signer of the withdraw permit from the signature
     * @dev     Reverts if the permit is past its deadline
     * @param   withdrawPermitParams  .
     * @return  signer  .
     */
    function _withdrawPermitVerifyGetSigner(
        WithdrawPermit memory withdrawPermitParams
    ) internal returns (address signer) {
        if (block.timestamp > withdrawPermitParams.deadline) {
            revert VaultParentPermit__Deadline();
        }

        signer = _getSigner(
            withdrawPermitParams.hash(),
            withdrawPermitParams.signature,
            withdrawPermitParams.signerNonce
        );

        _useNonce(signer, withdrawPermitParams.signerNonce);
    }

    /**
     * @notice  Recovers the signer from the signature
     * @dev     Checks to make sure the payloads nonce has not be used
     * @param   structHash  the hash of the payload
     * @param   signature  the signature of the payload
     * @param   payloadNonce  the nonce of the payload
     */
    function _getSigner(
        bytes32 structHash,
        bytes memory signature,
        uint256 payloadNonce
    ) internal returns (address signer) {
        bytes32 hash = keccak256(
            abi.encodePacked(uint16(0x1901), _DOMAIN_SEPARATOR(), structHash)
        );

        // recover signer
        signer = hash.recover(signature);

        if (
            VaultParentPermitStorage.layout().signerNonces[signer][payloadNonce]
        ) {
            revert VaultParentPermit__InvalidNonce();
        }
    }

    function _useNonce(address signer, uint256 nonce) internal {
        VaultParentPermitStorage.layout().signerNonces[signer][nonce] = true;
    }

    /**
     * @notice  Returns the domain separator for the current chain
     * @return  bytes32  domain separator
     */
    function _DOMAIN_SEPARATOR() internal returns (bytes32) {
        VaultParentPermitStorage.Layout storage l = VaultParentPermitStorage
            .layout();

        if (l.domainSeparators[block.chainid] == 0x00) {
            l.domainSeparators[block.chainid] = EIP712.calculateDomainSeparator(
                keccak256(bytes(_name())),
                VERSION_HASH
            );
        }

        return l.domainSeparators[block.chainid];
    }

    /**
     * @notice  EIP712 Requires name for the domain
     * @dev     Enforces the upstream consumer to have name
     * @return  string  name
     */
    function _name() internal view virtual returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title   IVaultParentPermit
 * @dev     Structs for VaultParentPermit
 */

interface IVaultParentPermit {
    struct ERC2612Permit {
        address owner;
        address token;
        uint value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // To create an immediate withdraw
    // Set the triggerAbove to false
    // And the unitPriceTrigger to 3% below the current price
    struct WithdrawPermit {
        uint tokenId;
        uint shares;
        uint unitPriceTrigger;
        bool triggerAbove; // take profit == true // stop loss == false
        uint deadline;
        uint signerNonce;
        bytes signature;
    }

    struct DepositPermit {
        uint tokenId;
        uint depositAmount;
        uint acceptableUnitPrice;
        address referrer;
        uint deadline;
        uint signerNonce;
        bytes signature;
        ERC2612Permit erc20Permit;
    }
}

/**
 * @title   VaultParentPermitLib
 * @dev     Hashing and signatures for VaultParentPermit
 */
library VaultParentPermitLib {
    bytes32 internal constant DEPOSIT_PERMIT_EIP712_TYPE_HASH =
        keccak256(
            'DepositPermit('
            'uint256 tokenId,'
            'uint256 depositAmount,'
            'uint256 acceptableUnitPrice,'
            'address referrer,'
            'uint256 deadline,'
            'uint256 signerNonce)'
        );

    bytes32 internal constant WITHDRAW_PERMIT_EIP712_TYPE_HASH =
        keccak256(
            'WithdrawPermit('
            'uint256 tokenId,'
            'uint256 shares,'
            'uint256 unitPriceTrigger,'
            'bool triggerAbove,'
            'uint256 deadline,'
            'uint256 signerNonce)'
        );

    /**
     * @notice  Returns the EIP712 hash of a DepositPermit
     * @dev     This is used to reconstruct the hash from the parameters
     * @dev     Must match DEPOSIT_PERMIT_EIP712_TYPE_HASH
     * @param   queueDepositParams  the DepositPermit struct
     * @return  bytes32  the hash of the DepositPermit params
     */
    function hash(
        IVaultParentPermit.DepositPermit memory queueDepositParams
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DEPOSIT_PERMIT_EIP712_TYPE_HASH,
                    queueDepositParams.tokenId,
                    queueDepositParams.depositAmount,
                    queueDepositParams.acceptableUnitPrice,
                    queueDepositParams.referrer,
                    queueDepositParams.deadline,
                    queueDepositParams.signerNonce
                )
            );
    }

    /**
     * @notice  Returns the EIP712 hash of a WithdrawPermit
     * @dev     This is used to reconstruct the hash from the parameters
     * @dev     Must match WITHDRAW_PERMIT_EIP712_TYPE_HASH
     * @param   withdrawPermitParams  the WithdrawPermit struct
     * @return  bytes32  the hash of the WithdrawPermit params
     */
    function hash(
        IVaultParentPermit.WithdrawPermit memory withdrawPermitParams
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    WITHDRAW_PERMIT_EIP712_TYPE_HASH,
                    withdrawPermitParams.tokenId,
                    withdrawPermitParams.shares,
                    withdrawPermitParams.unitPriceTrigger,
                    withdrawPermitParams.triggerAbove,
                    withdrawPermitParams.deadline,
                    withdrawPermitParams.signerNonce
                )
            );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library VaultParentPermitStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.vaultParentPermit');

    // solhint-disable-next-line ordering
    struct Layout {
        // Mapping of ChainID to domain separators. This is a very gas efficient way
        // to not recalculate the domain separator on every call, while still
        // automatically detecting ChainID changes.
        mapping(uint256 => bytes32) domainSeparators;
        // Signer -> usedNonces
        mapping(address => mapping(uint256 => bool)) signerNonces;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Proxy } from '@solidstate/contracts/proxy/Proxy.sol';
import { IDiamondReadable } from '@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol';

/**
 * @title   VaultParentProxy
 * @dev     An instance of this is created when a manager creates a Vault
 * @notice  This proxies to the VaultParentDiamond which is its `implementation`
 */
contract VaultParentProxy is Proxy {
    address private immutable DIAMOND;

    constructor(address diamond) {
        DIAMOND = diamond;
    }

    function _getImplementation() internal view override returns (address) {
        return IDiamondReadable(DIAMOND).facetAddress(msg.sig);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library VaultParentStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.vaultParent');

    // solhint-disable-next-line ordering
    struct ChainValue {
        uint minValue;
        uint lastUpdate;
        uint maxValue;
        bool hasHardDeprecatedAsset;
    }

    // solhint-disable-next-line ordering
    struct Layout {
        bytes32 _deprecated_vaultId;
        bool childCreationInProgress;
        bool bridgeInProgress;
        uint lastBridgeCancellation;
        uint withdrawsInProgress;
        uint16[] childChains;
        // chainId => childVault address
        mapping(uint16 => address) children;
        mapping(uint16 => ChainValue) chainTotalValues;
        uint16 bridgeApprovedFor;
        // Not a big fan of inverted flags, but some vaults were already deployed.
        // Would have preferred to have childIsActive
        mapping(uint16 => bool) childIsInactive;
        bool vaultClosed;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ITransport } from '../transport/ITransport.sol';
import { VaultParentInternal } from '../vault-parent/VaultParentInternal.sol';
import { VaultParentStorage } from './VaultParentStorage.sol';

contract VaultParentTransport is VaultParentInternal {
    event ReceivedChildValue();
    event ReceivedWithdrawComplete(uint withdrawsStillInProgress);
    event ReceivedChildCreated(uint16 childChainId, address childVault);

    ///
    /// Receivers/CallBacks
    ///

    function receiveWithdrawComplete() external onlyTransport {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        l.withdrawsInProgress--;
        _registry().emitEvent();
        emit ReceivedWithdrawComplete(l.withdrawsInProgress);
    }

    // Callback for once the sibling has been created on the dstChain
    function receiveChildCreated(
        uint16 childChainId,
        address childVault
    ) external onlyTransport {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        if (l.children[childChainId] == address(0)) {
            l.childCreationInProgress = false;
            l.childIsInactive[childChainId] = true;
            for (uint8 i = 0; i < l.childChains.length; i++) {
                // Federate the new sibling to the other children
                _registry().transport().sendAddSiblingRequest(
                    ITransport.AddVaultSiblingRequest({
                        // The existing child
                        child: ITransport.ChildVault({
                            vault: l.children[l.childChains[i]],
                            chainId: l.childChains[i]
                        }),
                        // The new Sibling
                        newSibling: ITransport.ChildVault({
                            vault: childVault,
                            chainId: childChainId
                        })
                    })
                );
            }
            // It's important these are here and not before the for loop
            // We only want to iterate over the existing children
            l.children[childChainId] = childVault;
            l.childChains.push(childChainId);

            _registry().emitEvent();
            emit ReceivedChildCreated(childChainId, childVault);
        }
    }

    // Callback to notify the parent the bridge has taken place
    function receiveBridgedAssetAcknowledgement(
        uint16 receivingChainId
    ) external onlyTransport {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        // While a bridge is underway everything is locked (deposits/withdraws etc)
        // Once the bridge is complete we need to clear the stale values we have for the childVaults
        // If a requestTotalSync completes (which is valid for 10 mins),
        // then a bridge takes place from a child to the parent and completes within 10 mins,
        // then the parent will have stale values for the childVaults but the extra value from the bridge
        // This enforces that a requestTotalSync must happen after a bridge completes.
        for (uint8 i = 0; i < l.childChains.length; i++) {
            l.chainTotalValues[l.childChains[i]].lastUpdate = 0;
        }
        // Update the childChain to be active
        l.childIsInactive[receivingChainId] = false;
        l.bridgeInProgress = false;
        l.bridgeApprovedFor = 0;
    }

    // Allows the bridge approval to be cancelled by the receiver
    // after a period of time if the bridge doesn't take place
    function receiveBridgeApprovalCancellation(
        address requester
    ) external onlyTransport {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        l.bridgeInProgress = false;
        l.bridgeApprovedFor = 0;
        if (requester != _manager()) {
            l.lastBridgeCancellation = block.timestamp;
        }
    }

    // Callback to receive value/supply updates
    function receiveChildValue(
        uint16 childChainId,
        uint minValue,
        uint maxValue,
        uint time,
        bool hasHardDeprecatedAsset
    ) external onlyTransport {
        // We don't accept value updates while WithdrawInProgress
        // As the value could be stale (from before the withdraw is executed)
        // We also don't allow requestTotalValueUpdateMultiChain to be called
        // until all withdraw processing on all chains is complete.
        // We adjust the min and maxValues proportionally after each withdraw
        if (!_withdrawInProgress()) {
            VaultParentStorage.Layout storage l = VaultParentStorage.layout();

            l.chainTotalValues[childChainId] = VaultParentStorage.ChainValue({
                minValue: minValue,
                maxValue: maxValue,
                lastUpdate: time,
                hasHardDeprecatedAsset: hasHardDeprecatedAsset
            });

            _registry().emitEvent();
            emit ReceivedChildValue();
        }
    }

    ///
    /// All of the below need to be moved to a VaultParentExternal Contract
    /// Moved here temporarily to avoid contract sizing issues
    ///

    /**
     * @notice  Returns the lz fee for the give function
     * @dev     This is a helper method for the frontend
     * @dev     We use the sighash of the intended function call to identify the action
     * @param   sigHash  The sighash of the intended function call
     * @param   chainId  The destination lz chain id
     * @return  fee  The lz fee for the message + destination gas
     */
    function getLzFee(
        bytes4 sigHash,
        uint16 chainId
    ) external view returns (uint fee) {
        return _getLzFee(sigHash, chainId);
    }

    /**
     * @notice  Returns the lzFees for a given sigHash
     * @dev     The sigHash is the 4 byte hash of the function that will be called.
     * @dev     E.G For withdrawal a message will be sent to each child chain
     * @param   sigHash  The hash of the function signature
     * @return  lzFees  The fees to send the message to each child chain
     * @return  totalSendFee  The total fee to send the message to all child chains
     */
    function getLzFeesMultiChain(
        bytes4 sigHash
    ) external view returns (uint[] memory lzFees, uint256 totalSendFee) {
        return _getLzFeesMultiChain(sigHash, _allChildChains());
    }

    /**
     * @notice  Returns the lzChainId for a given index
     * @dev     The childChains are ie [101, 111]
     * @param   index  The index of the childChain
     * @return  uint16  The lzChainId
     */
    function childChains(uint index) external view returns (uint16) {
        return _childChains(index);
    }

    /**
     * @notice  Returns the child vault address for a given chainId
     * @param   chainId  The chainId of the child
     * @return  address  The child vault address
     */
    function children(uint16 chainId) external view returns (address) {
        return _children(chainId);
    }

    /**
     * @notice  Returns which chains the parent vault has children
     * @dev     These are lzChainIds, ideally we should have used chainIds
     * @return  uint16[]  An array of lzChainIds
     */
    function allChildChains() external view returns (uint16[] memory) {
        return _allChildChains();
    }

    /**
     * @notice  Returns the AUM of the parent and all children
     * @dev     Will revert if the vault is not in sync
     * @dev     Will skip children where if no funds have ever been sent there
     * @return  minValue  The min value of the parent and all children
     * @return  maxValue  The max value of the parent and all children
     * @return  hasHardDeprecatedAsset  If any of the vaults hold a hard deprecated asset
     */
    function totalValueAcrossAllChains()
        external
        view
        returns (uint minValue, uint maxValue, bool hasHardDeprecatedAsset)
    {
        return _totalValueAcrossAllChains();
    }

    /**
     * @notice  Returns if the vault has a fresh vault value from all children
     * @dev     If the value has been received < `livelinessThreshold`, it is considered fresh
     * @return  bool  If the vault is in sync
     */
    function inSync() external view returns (bool) {
        return _inSync();
    }

    /**
     * @notice  Returns if the vault is in the process of executing withdraws
     * @dev     This will be false once all child vaults report the withdraw request is complete
     * @dev     Note: multiple withdraws can be processed at once
     * @return  bool  If the vault is in the process of executing withdraws
     */
    function withdrawInProgress() external view returns (bool) {
        return _withdrawInProgress();
    }

    /**
     * @notice  Returns if a sync is required to process a withdraw for the given tokenId
     * @dev     tokenIds that are precluded from paying performance fees do not require a sync
     * @dev     This means if a manager does not have a performance fee this is all tokenIds
     * @param   tokenId  The tokenId of the holding
     * @return  bool  If a sync is required to process a withdraw
     */
    function requiresSyncForWithdraw(
        uint tokenId
    ) external view returns (bool) {
        return _requiresSyncForFees(tokenId);
    }

    /**
     * @notice  Returns if a sync is required to process a deposit
     * @dev     If the vault has active children, a sync is required
     * @dev     This is purely a helper method for the frontend
     * @return  bool  If a sync is required to process a deposit
     */
    function requiresSyncForDeposit() external view returns (bool) {
        return _requiresSyncForDeposit();
    }

    // Returns the number of seconds until the totalValueSync expires
    /**
     * @notice  Returns the number of seconds until the totalValueSync expires
     * @dev     If the vault is not in sync, this will be 0
     * @dev     Not if there is two children this will return the lowest tte
     * @return  uint  The number of seconds until the totalValueSync expires
     */
    function timeUntilExpiry() external view returns (uint) {
        return _timeUntilExpiry();
    }

    /**
     * @notice  Returns if a holding is locked and cannot be withdraw from
     * @dev     Helper function for the frontend
     * @param   tokenId  The tokenId of the holding
     * @return  bool  If the holding is locked
     */
    function holdingLocked(uint tokenId) external view returns (bool) {
        return _holdingLocked(tokenId);
    }

    /**
     * @notice  Returns if a sync is required to process a deposit
     * @dev     If the vault has active children, a sync is required
     * @dev     This is purely a helper method for the frontend
     * @return  bool  If a sync is required to process a deposit
     */
    function _requiresSyncForDeposit() internal view returns (bool) {
        if (_hasActiveChildren()) {
            return true;
        }
        return false;
    }
}