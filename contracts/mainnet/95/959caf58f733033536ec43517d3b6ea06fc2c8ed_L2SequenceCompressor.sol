/**
 *Submitted for verification at Arbiscan.io on 2024-01-12
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.23;

interface IModuleCalls {
  // Events
  event TxFailed(bytes32 indexed _tx, uint256 _index, bytes _reason);
  event TxExecuted(bytes32 indexed _tx, uint256 _index);

  // Errors
  error NotEnoughGas(uint256 _index, uint256 _requested, uint256 _available);
  error InvalidSignature(bytes32 _hash, bytes _signature);

  // Transaction structure
  struct Transaction {
    bool delegateCall;   // Performs delegatecall
    bool revertOnError;  // Reverts transaction bundle if tx fails
    uint256 gasLimit;    // Maximum gas to be forwarded
    address target;      // Address of the contract to call
    uint256 value;       // Amount of ETH to pass with the call
    bytes data;          // calldata to pass
  }

  /**
   * @notice Allow wallet owner to execute an action
   * @param _txs        Transactions to process
   * @param _nonce      Signature nonce (may contain an encoded space)
   * @param _signature  Encoded signature
   */
  function execute(
    Transaction[] calldata _txs,
    uint256 _nonce,
    bytes calldata _signature
  ) external;

  /**
   * @notice Allow wallet to execute an action
   *   without signing the message
   * @param _txs  Transactions to execute
   */
  function selfExecute(
    Transaction[] calldata _txs
  ) external;
}

library SubModuleNonce {
  // Nonce schema
  //
  // - space[160]:nonce[96]
  //
  uint256 internal constant NONCE_BITS = 96;
  bytes32 internal constant NONCE_MASK = bytes32(uint256(type(uint96).max));

  /**
   * @notice Decodes a raw nonce
   * @dev Schema: space[160]:type[96]
   * @param _rawNonce Nonce to be decoded
   * @return _space The nonce space of the raw nonce
   * @return _nonce The nonce of the raw nonce
   */
  function decodeNonce(uint256 _rawNonce) internal pure returns (
    uint256 _space,
    uint256 _nonce
  ) {
    unchecked {
      // Decode nonce
      _space = _rawNonce >> NONCE_BITS;
      _nonce = uint256(bytes32(_rawNonce) & NONCE_MASK);
    }
  }

  function encodeNonce(uint256 _space, uint256 _nonce) internal pure returns (uint256) {
    unchecked {
      // Combine space and nonce
      return (_space << NONCE_BITS) | _nonce;
    }
  }
}

interface IERC1271Wallet {

  /**
   * @notice Verifies whether the provided signature is valid with respect to the provided data
   * @dev MUST return the correct magic value if the signature provided is valid for the provided data
   *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
   *   > This function MAY modify Ethereum's state
   * @param _data       Arbitrary length data signed on the behalf of address(this)
   * @param _signature  Signature byte array associated with _data
   * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
   */
  function isValidSignature(
    bytes calldata _data,
    bytes calldata _signature)
    external
    view
    returns (bytes4 magicValue);

  /**
   * @notice Verifies whether the provided signature is valid with respect to the provided hash
   * @dev MUST return the correct magic value if the signature provided is valid for the provided hash
   *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
   *   > This function MAY modify Ethereum's state
   * @param _hash       keccak256 hash that was signed
   * @param _signature  Signature byte array associated with _data
   * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
   */
  function isValidSignature(
    bytes32 _hash,
    bytes calldata _signature)
    external
    view
    returns (bytes4 magicValue);
}

/**
 * @title Library for reading data from bytes arrays
 * @author Agustin Aguilar ([email protected])
 * @notice This library contains functions for reading data from bytes arrays.
 *
 * @dev These functions do not check if the input index is within the bounds of the data array.
 *         Reading out of bounds may return dirty values.
 */
library LibBytes {

  /**
   * @notice Returns the bytes32 value at the given index in the input data.
   * @param data The input data.
   * @param index The index of the value to retrieve.
   * @return a The bytes32 value at the given index.
   */
  function readBytes32(
    bytes calldata data,
    uint256 index
  ) internal pure returns (
    bytes32 a
  ) {
    assembly {
      a := calldataload(add(data.offset, index))
    }
  }

  /**
   * @notice Returns the uint8 value at the given index in the input data.
   * @param data The input data.
   * @param index The index of the value to retrieve.
   * @return a The uint8 value at the given index.
   */
  function readUint8(
    bytes calldata data,
    uint256 index
  ) internal pure returns (
    uint8 a
  ) {
    assembly {
      let word := calldataload(add(index, data.offset))
      a := shr(248, word)
    }
  }

  /**
   * @notice Returns the first uint16 value in the input data.
   * @param data The input data.
   * @return a The first uint16 value in the input data.
   */
  function readFirstUint16(
    bytes calldata data
  ) internal pure returns (
    uint16 a
  ) {
    assembly {
      let word := calldataload(data.offset)
      a := shr(240, word)
    }
  }

  /**
   * @notice Returns the uint32 value at the given index in the input data.
   * @param data The input data.
   * @param index The index of the value to retrieve.
   * @return a The uint32 value at the given index.
   */
  function readUint32(
    bytes calldata data,
    uint256 index
  ) internal pure returns (
    uint32 a
  ) {
    assembly {
      let word := calldataload(add(index, data.offset))
      a := shr(224, word)
    }
  }

  function readMBytes4(
    bytes memory data,
    uint256 index
  ) internal pure returns (
    bytes4 a
  ) {
    assembly {
      let word := mload(add(add(data, 0x20), index))
      a := and(word, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
    }
  }

  function readMBytes32(
    bytes memory data,
    uint256 index
  ) internal pure returns (
    bytes32 a
  ) {
    assembly {
      a := mload(add(add(data, 0x20), index))
    }
  }
}

/**
 * @dev Contains logic for signature validation.
 * Signatures from wallet contracts assume ERC-1271 support (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1271.md)
 * Notes: Methods are strongly inspired by contracts in https://github.com/0xProject/0x-monorepo/blob/development/
 */
library SignatureValidator {
  // Errors
  error InvalidSignatureLength(bytes _signature);
  error EmptySignature();
  error InvalidSValue(bytes _signature, bytes32 _s);
  error InvalidVValue(bytes _signature, uint256 _v);
  error UnsupportedSignatureType(bytes _signature, uint256 _type, bool _recoverMode);
  error SignerIsAddress0(bytes _signature);

  using LibBytes for bytes;

  /***********************************|
  |             Variables             |
  |__________________________________*/

  // bytes4(keccak256("isValidSignature(bytes,bytes)"))
  bytes4 constant internal ERC1271_MAGICVALUE = 0x20c13b0b;

  // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
  bytes4 constant internal ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e;

  // Allowed signature types.
  uint256 private constant SIG_TYPE_EIP712 = 1;
  uint256 private constant SIG_TYPE_ETH_SIGN = 2;
  uint256 private constant SIG_TYPE_WALLET_BYTES32 = 3;

  /***********************************|
  |        Signature Functions        |
  |__________________________________*/

 /**
   * @notice Recover the signer of hash, assuming it's an EOA account
   * @dev Only for SignatureType.EIP712 and SignatureType.EthSign signatures
   * @param _hash      Hash that was signed
   *   encoded as (bytes32 r, bytes32 s, uint8 v, ... , SignatureType sigType)
   */
  function recoverSigner(
    bytes32 _hash,
    bytes calldata _signature
  ) internal pure returns (address signer) {
    if (_signature.length != 66) revert InvalidSignatureLength(_signature);
    uint256 signatureType = _signature.readUint8(_signature.length - 1);

    // Variables are not scoped in Solidity.
    uint8 v = _signature.readUint8(64);
    bytes32 r = _signature.readBytes32(0);
    bytes32 s = _signature.readBytes32(32);

    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
    // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
    //
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    //
    // Source OpenZeppelin
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol

    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      revert InvalidSValue(_signature, s);
    }

    if (v != 27 && v != 28) {
      revert InvalidVValue(_signature, v);
    }

    // Signature using EIP712
    if (signatureType == SIG_TYPE_EIP712) {
      signer = ecrecover(_hash, v, r, s);

    // Signed using web3.eth_sign() or Ethers wallet.signMessage()
    } else if (signatureType == SIG_TYPE_ETH_SIGN) {
      signer = ecrecover(
        keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)),
        v,
        r,
        s
      );

    } else {
      // We cannot recover the signer for any other signature type.
      revert UnsupportedSignatureType(_signature, signatureType, true);
    }

    // Prevent signer from being 0x0
    if (signer == address(0x0)) revert SignerIsAddress0(_signature);

    return signer;
  }

 /**
   * @notice Returns true if the provided signature is valid for the given signer.
   * @dev Supports SignatureType.EIP712, SignatureType.EthSign, and ERC1271 signatures
   * @param _hash      Hash that was signed
   * @param _signer    Address of the signer candidate
   * @param _signature Signature byte array
   */
  function isValidSignature(
    bytes32 _hash,
    address _signer,
    bytes calldata _signature
  ) internal view returns (bool valid) {
    if (_signature.length == 0) {
      revert EmptySignature();
    }

    uint256 signatureType = uint8(_signature[_signature.length - 1]);
    if (signatureType == SIG_TYPE_EIP712 || signatureType == SIG_TYPE_ETH_SIGN) {
      // Recover signer and compare with provided
      valid = recoverSigner(_hash, _signature) == _signer;

    } else if (signatureType == SIG_TYPE_WALLET_BYTES32) {
      // Remove signature type before calling ERC1271, restore after call
      valid = ERC1271_MAGICVALUE_BYTES32 == IERC1271Wallet(_signer).isValidSignature(_hash, _signature[0:_signature.length - 1]);

    } else {
      // We cannot validate any other signature type.
      // We revert because we can say nothing about its validity.
      revert UnsupportedSignatureType(_signature, signatureType, false);
    }
  }
}

/**
 * @title Library for reading data from bytes arrays with a pointer
 * @author Agustin Aguilar ([email protected])
 * @notice This library contains functions for reading data from bytes arrays with a pointer.
 *
 * @dev These functions do not check if the input index is within the bounds of the data array.
 *         Reading out of bounds may return dirty values.
 */
library LibBytesPointer {

  /**
   * @dev Returns the first uint16 value in the input data and updates the pointer.
   * @param _data The input data.
   * @return a The first uint16 value.
   * @return newPointer The new pointer.
   */
  function readFirstUint16(
    bytes calldata _data
  ) internal pure returns (
    uint16 a,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(_data.offset)
      a := shr(240, word)
      newPointer := 2
    }
  }

  /**
   * @notice Returns the uint8 value at the given index in the input data and updates the pointer.
   * @param _data The input data.
   * @param _index The index of the value to retrieve.
   * @return a The uint8 value at the given index.
   * @return newPointer The new pointer.
   */
  function readUint8(
    bytes calldata _data,
    uint256 _index
  ) internal pure returns (
    uint8 a,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(add(_index, _data.offset))
      a := shr(248, word)
      newPointer := add(_index, 1)
    }
  }

  function readAddress(
    bytes calldata _data,
    uint256 _index
  ) internal pure returns (
    address a,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(add(_index, _data.offset))
      a := and(shr(96, word), 0xffffffffffffffffffffffffffffffffffffffff)
      newPointer := add(_index, 20)
    }
  }

  /**
   * @notice Returns the uint8 value and the address at the given index in the input data and updates the pointer.
   * @param _data The input data.
   * @param _index The index of the value to retrieve.
   * @return a The uint8 value at the given index.
   * @return b The following address value.
   * @return newPointer The new pointer.
   */
  function readUint8Address(
    bytes calldata _data,
    uint256 _index
  ) internal pure returns (
    uint8 a,
    address b,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(add(_index, _data.offset))
      a := shr(248, word)
      b := and(shr(88, word), 0xffffffffffffffffffffffffffffffffffffffff)
      newPointer := add(_index, 21)
    }
  }

  /**
   * @notice Returns the uint16 value at the given index in the input data and updates the pointer.
   * @param _data The input data.
   * @param _index The index of the value to retrieve.
   * @return a The uint16 value at the given index.
   * @return newPointer The new pointer.
   */
  function readUint16(
    bytes calldata _data,
    uint256 _index
  ) internal pure returns (
    uint16 a,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(add(_index, _data.offset))
      a := and(shr(240, word), 0xffff)
      newPointer := add(_index, 2)
    }
  }

  function readUintX(
    bytes calldata _data,
    uint256 _bytes,
    uint256 _index
  ) internal pure returns (
    uint256 a,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(add(_index, _data.offset))
      let shift := sub(256, mul(_bytes, 8))
      a := and(shr(shift, word), sub(shl(mul(8, _bytes), 1), 1))
      newPointer := add(_index, _bytes)
    }
  }

  /**
   * @notice Returns the uint24 value at the given index in the input data and updates the pointer.
   * @param _data The input data.
   * @param _index The index of the value to retrieve.
   * @return a The uint24 value at the given index.
   * @return newPointer The new pointer.
   */
  function readUint24(
    bytes calldata _data,
    uint256 _index
  ) internal pure returns (
    uint24 a,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(add(_index, _data.offset))
      a := and(shr(232, word), 0xffffff)
      newPointer := add(_index, 3)
    }
  }

  /**
   * @notice Returns the uint64 value at the given index in the input data and updates the pointer.
   * @param _data The input data.
   * @param _index The index of the value to retrieve.
   * @return a The uint64 value at the given index.
   * @return newPointer The new pointer.
   */
  function readUint64(
    bytes calldata _data,
    uint256 _index
  ) internal pure returns (
    uint64 a,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(add(_index, _data.offset))
      a := and(shr(192, word), 0xffffffffffffffff)
      newPointer := add(_index, 8)
    }
  }

  function readBytes4(
    bytes calldata _data,
    uint256 _pointer
  ) internal pure returns (
    bytes4 a,
    uint256 newPointer
  ) {
    assembly {
      a := calldataload(add(_pointer, _data.offset))
      a := and(a, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
      newPointer := add(_pointer, 4)
    }
  }

  /**
   * @notice Returns the bytes32 value at the given index in the input data and updates the pointer.
   * @param _data The input data.
   * @param _pointer The index of the value to retrieve.
   * @return a The bytes32 value at the given index.
   * @return newPointer The new pointer.
   */
  function readBytes32(
    bytes calldata _data,
    uint256 _pointer
  ) internal pure returns (
    bytes32 a,
    uint256 newPointer
  ) {
    assembly {
      a := calldataload(add(_pointer, _data.offset))
      newPointer := add(_pointer, 32)
    }
  }
}

/**
 * @title Library for optimized EVM operations
 * @author Agustin Aguilar ([email protected])
 * @notice This library contains functions for optimizing certain EVM operations.
 */
library LibOptim {

  /**
   * @notice Computes the keccak256 hash of two 32-byte inputs.
   * @dev It uses only scratch memory space.
   * @param _a The first 32 bytes of the hash.
   * @param _b The second 32 bytes of the hash.
   * @return c The keccak256 hash of the two 32-byte inputs.
   */
  function fkeccak256(
    bytes32 _a,
    bytes32 _b
  ) internal pure returns (bytes32 c) {
    assembly {
      mstore(0, _a)
      mstore(32, _b)
      c := keccak256(0, 64)
    }
  }

  /**
   * @notice Returns the return data from the last call.
   * @return r The return data from the last call.
   */
  function returnData() internal pure returns (bytes memory r) {
    assembly {
      let size := returndatasize()
      r := mload(0x40)
      let start := add(r, 32)
      mstore(0x40, add(start, size))
      mstore(r, size)
      returndatacopy(start, 0, size)
    }
  }

  /**
   * @notice Calls another contract with the given parameters.
   * @dev This method doesn't increase the memory pointer.
   * @param _to The address of the contract to call.
   * @param _val The value to send to the contract.
   * @param _gas The amount of gas to provide for the call.
   * @param _data The data to send to the contract.
   * @return r The success status of the call.
   */
  function call(
    address _to,
    uint256 _val,
    uint256 _gas,
    bytes calldata _data
  ) internal returns (bool r) {
    assembly {
      let tmp := mload(0x40)
      calldatacopy(tmp, _data.offset, _data.length)

      r := call(
        _gas,
        _to,
        _val,
        tmp,
        _data.length,
        0,
        0
      )
    }
  }

  /**
   * @notice Calls another contract with the given parameters, using delegatecall.
   * @dev This method doesn't increase the memory pointer.
   * @param _to The address of the contract to call.
   * @param _gas The amount of gas to provide for the call.
   * @param _data The data to send to the contract.
   * @return r The success status of the call.
   */
  function delegatecall(
    address _to,
    uint256 _gas,
    bytes calldata _data
  ) internal returns (bool r) {
    assembly {
      let tmp := mload(0x40)
      calldatacopy(tmp, _data.offset, _data.length)

      r := delegatecall(
        _gas,
        _to,
        tmp,
        _data.length,
        0,
        0
      )
    }
  }
}

/**
 * @title SequenceBaseSig Library
 * @author Agustin Aguilar ([email protected])
 * @notice A Solidity implementation for handling signatures in the Sequence protocol.
 */
library SequenceBaseSig {
  using LibBytesPointer for bytes;

  uint256 internal constant FLAG_SIGNATURE = 0;
  uint256 internal constant FLAG_ADDRESS = 1;
  uint256 internal constant FLAG_DYNAMIC_SIGNATURE = 2;
  uint256 internal constant FLAG_NODE = 3;
  uint256 internal constant FLAG_BRANCH = 4;
  uint256 internal constant FLAG_SUBDIGEST = 5;
  uint256 internal constant FLAG_NESTED = 6;

  error InvalidNestedSignature(bytes32 _hash, address _addr, bytes _signature);
  error InvalidSignatureFlag(uint256 _flag);

  /**
  * @notice Generates a subdigest for the input digest (unique for this wallet and network).
  * @param _digest The input digest to generate the subdigest from.
  * @return bytes32 The subdigest generated from the input digest.
  */
  function subdigest(
    bytes32 _digest
  ) internal view returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        "\x19\x01",
        block.chainid,
        address(this),
        _digest
      )
    );
  }

  /**
  * @notice Generates the leaf for an address and weight.
  * @dev The leaf is generated by concatenating the address and weight.
  *
  * @param _addr The address to generate the leaf for.
  * @param _weight The weight to generate the leaf for.
  * @return bytes32 The leaf generated from the address and weight.
  */
  function _leafForAddressAndWeight(
    address _addr,
    uint96 _weight
  ) internal pure returns (bytes32) {
    unchecked {
      return bytes32(uint256(_weight) << 160 | uint256(uint160(_addr)));
    }
  }

  /**
  * @notice Generates the leaf for a hardcoded subdigest.
  * @dev The leaf is generated by hashing 'Sequence static digest:\n' and the subdigest.
  * @param _subdigest The subdigest to generate the leaf for.
  * @return bytes32 The leaf generated from the hardcoded subdigest.
  */
  function _leafForHardcodedSubdigest(
    bytes32 _subdigest
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked('Sequence static digest:\n', _subdigest));
  }

  /**
  * @notice Generates the leaf for a nested tree node.
  * @dev The leaf is generated by hashing 'Sequence nested config:\n', the node, the threshold and the weight.
  *
  * @param _node The root of the node to generate the leaf for.
  * @param _threshold The internal threshold of the tree.
  * @param _weight The external weight of the tree.
  * @return bytes32 The leaf generated from the nested tree.
  */
  function _leafForNested(
    bytes32 _node,
    uint256 _threshold,
    uint256 _weight
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked('Sequence nested config:\n', _node, _threshold, _weight));
  }

  /**
   * @notice Returns the weight and root of a signature branch.
   * @dev If the signature contains a hardcoded subdigest, and it matches the input digest, then the weight is set to 2 ** 256 - 1.
   *
   * @param _subdigest The digest to verify the signature against.
   * @param _signature The signature branch to recover.
   * @return weight The total weight of the recovered signatures.
   * @return root The root hash of the recovered configuration.
   */
  function recoverBranch(
    bytes32 _subdigest,
    bytes calldata _signature
  ) internal view returns (
    uint256 weight,
    bytes32 root
  ) {
    unchecked {
      uint256 rindex;

      // Iterate until the image is completed
      while (rindex < _signature.length) {
        // Read next item type
        uint256 flag;
        (flag, rindex) = _signature.readUint8(rindex);

        if (flag == FLAG_ADDRESS) {
          // Read plain address
          uint8 addrWeight; address addr;
          (addrWeight, addr, rindex) = _signature.readUint8Address(rindex);

          // Write weight and address to image
          bytes32 node = _leafForAddressAndWeight(addr, addrWeight);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        if (flag == FLAG_SIGNATURE) {
          // Read weight
          uint8 addrWeight;
          (addrWeight, rindex) = _signature.readUint8(rindex);

          // Read single signature and recover signer
          uint256 nrindex = rindex + 66;
          address addr = SignatureValidator.recoverSigner(_subdigest, _signature[rindex:nrindex]);
          rindex = nrindex;

          // Acumulate total weight of the signature
          weight += addrWeight;

          // Write weight and address to image
          bytes32 node = _leafForAddressAndWeight(addr, addrWeight);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        if (flag == FLAG_DYNAMIC_SIGNATURE) {
          // Read signer and weight
          uint8 addrWeight; address addr;
          (addrWeight, addr, rindex) = _signature.readUint8Address(rindex);

          // Read signature size
          uint256 size;
          (size, rindex) = _signature.readUint24(rindex);

          // Read dynamic size signature
          uint256 nrindex = rindex + size;
          if (!SignatureValidator.isValidSignature(_subdigest, addr, _signature[rindex:nrindex])) {
            revert InvalidNestedSignature(_subdigest, addr, _signature[rindex:nrindex]);
          }
          rindex = nrindex;

          // Acumulate total weight of the signature
          weight += addrWeight;

          // Write weight and address to image
          bytes32 node = _leafForAddressAndWeight(addr, addrWeight);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        if (flag == FLAG_NODE) {
          // Read node hash
          bytes32 node;
          (node, rindex) = _signature.readBytes32(rindex);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        if (flag == FLAG_BRANCH) {
          // Enter a branch of the signature merkle tree
          uint256 size;
          (size, rindex) = _signature.readUint24(rindex);
          uint256 nrindex = rindex + size;

          uint256 nweight; bytes32 node;
          (nweight, node) = recoverBranch(_subdigest, _signature[rindex:nrindex]);

          weight += nweight;
          root = LibOptim.fkeccak256(root, node);

          rindex = nrindex;
          continue;
        }

        if (flag == FLAG_NESTED) {
          // Enter a branch of the signature merkle tree
          // but with an internal threshold and an external fixed weight
          uint256 externalWeight;
          (externalWeight, rindex) = _signature.readUint8(rindex);

          uint256 internalThreshold;
          (internalThreshold, rindex) = _signature.readUint16(rindex);

          uint256 size;
          (size, rindex) = _signature.readUint24(rindex);
          uint256 nrindex = rindex + size;

          uint256 internalWeight; bytes32 internalRoot;
          (internalWeight, internalRoot) = recoverBranch(_subdigest, _signature[rindex:nrindex]);
          rindex = nrindex;

          if (internalWeight >= internalThreshold) {
            weight += externalWeight;
          }

          bytes32 node = _leafForNested(internalRoot, internalThreshold, externalWeight);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;

          continue;
        }

        if (flag == FLAG_SUBDIGEST) {
          // A hardcoded always accepted digest
          // it pushes the weight to the maximum
          bytes32 hardcoded;
          (hardcoded, rindex) = _signature.readBytes32(rindex);
          if (hardcoded == _subdigest) {
            weight = type(uint256).max;
          }

          bytes32 node = _leafForHardcodedSubdigest(hardcoded);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        revert InvalidSignatureFlag(flag);
      }
    }
  }

  /**
   * @notice Returns the threshold, weight, root, and checkpoint of a signature.
   * @dev To verify the signature, the weight must be greater than or equal to the threshold, and the root
   *      must match the expected `imageHash` of the wallet.
   *
   * @param _subdigest The digest to verify the signature against.
   * @param _signature The signature to recover.
   * @return threshold The minimum weight required for the signature to be valid.
   * @return weight The total weight of the recovered signatures.
   * @return imageHash The root hash of the recovered configuration
   * @return checkpoint The checkpoint of the signature.
   */
  function recover(
    bytes32 _subdigest,
    bytes calldata _signature
  ) internal view returns (
    uint256 threshold,
    uint256 weight,
    bytes32 imageHash,
    uint256 checkpoint
  ) {
    unchecked {
      (weight, imageHash) = recoverBranch(_subdigest, _signature[6:]);

      // Threshold & checkpoint are the top nodes
      // (but they are first on the signature)
      threshold = LibBytes.readFirstUint16(_signature);
      checkpoint = LibBytes.readUint32(_signature, 2);

      imageHash = LibOptim.fkeccak256(imageHash, bytes32(threshold));
      imageHash = LibOptim.fkeccak256(imageHash, bytes32(checkpoint));
    }
  }
}

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
    }

    function log(uint p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
    }

    function log(uint p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
    }

    function log(uint p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
    }

    function log(uint p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
    }

    function log(uint p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
    }

    function log(uint p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
    }

    function log(uint p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
    }

    function log(uint p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
    }

    function log(uint p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
    }

    function log(uint p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
    }

    function log(uint p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
    }

    function log(bool p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
    }

    function log(bool p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
    }

    function log(bool p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
    }

    function log(address p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
    }

    function log(address p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
    }

    function log(address p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}

function bytesToUint256(
  bytes memory _b
) pure returns (uint256 result) {
  assembly {
    // Load 32 bytes of data from the memory pointed to by _b
    result := mload(add(_b, 0x20))

    // Shift right to discard the extra bytes in case of shorter lengths
    let size := mload(_b)
    if lt(size, 32) {
      result := shr(mul(sub(32, size), 8), result)
    }
  }
}

function bytesToAddress(bytes memory _b) pure returns (address addr) {
  assembly {
    // Load 32 bytes from memory, but only use the last 20 bytes for the address
    addr := and(mload(add(_b, 0x14)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
  }
}

contract L2SequenceDecompressor {
  using LibBytesPointer for bytes;

  // 128 bits for bytes32 and 128 bits for addresses
  uint256 private knownBytes32AndAddressesSizes;
  mapping(uint256 => bytes32) public knownBytes32s;
  mapping(uint256 => address) public knownAdresses;

  error UnknownFlag(uint256 _flag, uint256 _index);

  function numKnownBytes32() public view returns (uint256 _val, uint256 _word) {
    _word = knownBytes32AndAddressesSizes;
    _val = _word & 0xFFFFFFFFFFFFFFFF;
  }

  function numKnownAddresses() public view returns (uint256 _val, uint256 _word) {
    _word = knownBytes32AndAddressesSizes;
    _val = _word >> 128;
  }

  function setNumKnownBytes32(uint256 _val, uint256 _prev) internal {
    knownBytes32AndAddressesSizes = (_val & 0xFFFFFFFFFFFFFFFF) | (_prev & 0xFFFFFFFFFFFFFFFF0000000000000000);
  }

  function setNumKnownAddresses(uint256 _val, uint256 _prev) internal {
    knownBytes32AndAddressesSizes = (_val << 128) | (_prev & 0xFFFFFFFFFFFFFFFF);
  }

  function nextIndexBytes32() internal returns (uint256) {
    (uint256 index, uint256 word) = numKnownBytes32();
    setNumKnownBytes32(index + 1, word);
    return index;
  }

  function nextIndexAddress() internal returns (uint256) {
    (uint256 index, uint256 word) = numKnownAddresses();
    setNumKnownAddresses(index + 1, word);
    return index;
  }

  fallback() external {
    (
      address wallet,
      IModuleCalls.Transaction[] memory transactions,
      uint256 nonce,
      bytes memory signature,
    ) = decodeSequenceTransaction(0);

    bytes memory encoded = abi.encodeWithSelector(IModuleCalls.execute.selector, transactions, nonce, signature);
    (bool success,) = wallet.call(encoded);
    require(success, "L2SequenceCompressor: call failed");
  }

  function decodeSequenceTransaction(
    uint256 _pointer
  ) internal returns (
    address wallet,
    IModuleCalls.Transaction[] memory transactions,
    uint256 nonce,
    bytes memory signature,
    uint256 newPointer
  ) {
    unchecked {
      bytes memory data;

      // A Sequence transaction is composed of:
      // - a Signature
      // - a list of transactions
      // - a nonce
      // The order is always [wallet]:[ntransactions]:[transactions]:[nonce]:[signaturesize][signature]

      // Read wallet address, this is where we will send the call
      (data, newPointer) = readAdvanced(_pointer);
      wallet = bytesToAddress(data);

      // Read list of transactions
      (data, newPointer) = readAdvanced(newPointer);
      uint256 ntransactions = bytesToUint256(data);

      transactions = new IModuleCalls.Transaction[](ntransactions);

      for (uint256 i = 0; i < ntransactions; i++) {
        (transactions[i], newPointer) = readTransaction(wallet, newPointer);
      }

      // Read the nonce
      (nonce, newPointer) = readNonce(newPointer);

      // Read the signature
      (signature, newPointer) = readAllSignature(newPointer);
      // (signature, newPointer) = readAdvanced(newPointer);
    }
  }

  function readAllSignature(
    uint256 _pointer
  ) internal returns (
    bytes memory signature,
    uint256 newPointer
  ) {
    unchecked {
      uint8 flag;
      (flag, newPointer) = msg.data.readUint8(_pointer);

      // Doesn't have any special encoding
      // just read the signature as any set of bytes
      if (flag == 0x00) {
        return readAdvanced(newPointer);

      // Single signature with chain id
      } else if (flag == 0x01) {
        return readSignature(newPointer, false);

      // Chained signature
      } else if (flag == 0x02) {
        bytes memory data;
        (data, newPointer) = readAdvanced(newPointer);
        uint256 subparts = bytesToUint256(data);

        for (uint256 i = 0; i < subparts; i++) {
          (data, newPointer) = readAllSignature(newPointer);
          signature = abi.encodePacked(signature, uint24(data.length), data);
        }

        signature = abi.encodePacked(uint8(0x03), signature);
      }
    }
  }

  function readSignature(
    uint256 _pointer,
    bool _noChainId
  ) internal returns (
    bytes memory signature,
    uint256 newPointer
  ) {
    unchecked {
      bytes memory data;

      // Read the threshold first, use advanced as it may be 1 or 2 bytes
      (data, newPointer) = readAdvanced(_pointer);
      uint256 threshold = bytesToUint256(data);

      // Read the checkpoint, use advanced as it may have up to 4 bytes
      (data, newPointer) = readAdvanced(newPointer);
      uint256 checkpoint = bytesToUint256(data);

      // Read the tree
      (signature, newPointer) = readSignatureBranch(newPointer);

      // Build the signature, 0x01 type, 2 bytes for the threshold, 4 bytes for the checkpoint, the rest is the signature
      signature = abi.encodePacked(uint8(_noChainId ? 0x02 : 0x01), uint16(threshold), uint32(checkpoint), signature);
    }
  }

  function readSignatureBranch(
    uint256 _pointer
  ) internal returns (
    bytes memory signature,
    uint256 newPointer
  ) {
    bytes memory data;

    // Now load the number of "parts" that we will read after this
    (data, newPointer) = readAdvanced(_pointer);
    uint256 nparts = bytesToUint256(data);

    // Read part by part, concatenate them
    for (uint256 i = 0; i < nparts; i++) {
      (data, newPointer) = readAdvanced(newPointer);
      signature = abi.encodePacked(signature, data);
    }

    return (signature, newPointer);
  }

  function readNonce(
    uint256 _pointer
  ) internal returns (
    uint256 encodedNonce,
    uint256 newPointer
  ) {
    unchecked {
      bytes memory data;

      (data, newPointer) = readAdvanced(_pointer);
      uint256 space = bytesToUint256(data);

      (data, newPointer) = readAdvanced(newPointer);
      uint256 nonce = bytesToUint256(data);

      encodedNonce = SubModuleNonce.encodeNonce(space, nonce);
    }
  }

  function readTransaction(
    address _self,
    uint256 _pointer
  ) internal returns (
    IModuleCalls.Transaction memory transaction,
    uint256 newPointer
  ) {
    unchecked {
      uint256 miscflags;
      (miscflags, newPointer) = msg.data.readUint8(_pointer);

      transaction.delegateCall = (miscflags & 0x80) != 0;  // 1000 0000 for delegateCall
      transaction.revertOnError = (miscflags & 0x40) != 0; // 0100 0000 for revertOnError

      bool hasGasLimit = (miscflags & 0x20) != 0;          // 0010 0000 for gasLimit
      bool hasValue = (miscflags & 0x10) != 0;             // 0001 0000 for value
      bool hasData = (miscflags & 0x08) != 0;              // 0000 1000 for data
      bool selfTarget = (miscflags & 0x04) != 0;           // 0000 0100 for selfTarget
      // bool isNestedSequence = (miscflags & 0x02) != 0;     // 0000 0010 for nestedSequence

      bytes memory data;

      if (hasGasLimit) {
        (data, newPointer) = readAdvanced(newPointer);
        transaction.gasLimit = bytesToUint256(data);
      }

      if (hasValue) {
        (data, newPointer) = readAdvanced(newPointer);
        transaction.value = bytesToUint256(data);
      }

      if (hasData) {
        (data, newPointer) = readAdvanced(newPointer);
        transaction.data = data;
      }

      // bool isNestedSequence = (miscflags & 0x02) != 0;     // 0000 0010 for nestedSequence
      if ((miscflags & 0x02) != 0) {
        address wallet;
        IModuleCalls.Transaction[] memory transactions;
        uint256 nonce;
        bytes memory signature;

        (wallet, transactions, nonce, signature, newPointer) = decodeSequenceTransaction(newPointer); 
        transaction.data = abi.encodeWithSelector(IModuleCalls.execute.selector, transactions, nonce, signature);
        transaction.target = wallet;
      }

      if (selfTarget) {
        transaction.target = _self;
      } else {
        (data, newPointer) = readAdvanced(newPointer);
        transaction.target = bytesToAddress(data);
      }
    }
  }

  uint8 constant internal FLAG_READ_BYTES32_0_BYTES  = 0x00;
  uint8 constant internal FLAG_READ_BYTES32_32_BYTES = 0x20;
  uint8 constant internal FLAG_SAVE_ADDRESS          = 0x21;
  uint8 constant internal FLAG_SAVE_BYTES32          = 0x22;
  uint8 constant internal FLAG_READ_BYTES32_2_BYTES  = 0x23;
  uint8 constant internal FLAG_READ_BYTES32_5_BYTES  = 0x26;
  uint8 constant internal FLAG_READ_ADDRESS_2_BYTES  = 0x27;
  uint8 constant internal FLAG_READ_ADDRESS_3_BYTES  = 0x28;
  uint8 constant internal FLAG_READ_ADDRESS_4_BYTES  = 0x29;
  uint8 constant internal FLAG_READ_ADDRESS_5_BYTES  = 0x2a;
  uint8 constant internal FLAG_READ_N_BYTES          = 0x2f;
  uint8 constant internal FLAG_ABI_1_PARAM           = 0x30;
  uint8 constant internal FLAG_ABI_2_PARAMS          = 0x31;
  uint8 constant internal FLAG_ABI_3_PARAMS          = 0x32;
  uint8 constant internal FLAG_ABI_4_PARAMS          = 0x33;
  uint8 constant internal FLAG_ABI_5_PARAMS          = 0x34;
  uint8 constant internal FLAG_ABI_6_PARAMS          = 0x35;
  uint8 constant internal FLAG_SIGNATURE             = 0x36;
  uint8 constant internal FLAG_SIGNATURE_W1          = 0x37;
  uint8 constant internal FLAG_SIGNATURE_W2          = 0x38;
  uint8 constant internal FLAG_SIGNATURE_W3          = 0x39;
  uint8 constant internal FLAG_SIGNATURE_W4          = 0x3a;
  uint8 constant internal FLAG_ADDRESS               = 0x3b;
  uint8 constant internal FLAG_ADDRESS_W0            = 0x3c;
  uint8 constant internal FLAG_ADDRESS_W1            = 0x3d;
  uint8 constant internal FLAG_ADDRESS_W2            = 0x3e;
  uint8 constant internal FLAG_ADDRESS_W3            = 0x3f;
  uint8 constant internal FLAG_ADDRESS_W4            = 0x40;
  uint8 constant internal FLAG_DYNAMIC_SIGNATURE     = 0x41;
  uint8 constant internal FLAG_NODE                  = 0x42;
  uint8 constant internal FLAG_BRANCH                = 0x43;
  uint8 constant internal FLAG_SUBDIGEST             = 0x44;
  uint8 constant internal FLAG_NESTED                = 0x45;

  uint8 constant internal HIGHEST_FLAG = FLAG_NESTED;

  function readAdvanced(
    uint256 _pointer
  ) internal returns (
    bytes memory data,
    uint256 newPointer
  ) {
    unchecked {
      uint256 flag;
      (flag, newPointer) = msg.data.readUint8(_pointer);

      // None
      if (flag == FLAG_READ_BYTES32_0_BYTES) {
        return (data, newPointer);

      // Read 1 byte to 32 bytes (0x01, 0x02, etc)
      } else if (flag <= FLAG_READ_BYTES32_32_BYTES) {
        data = msg.data[newPointer:newPointer + flag];
        newPointer += flag;
        return (data, newPointer);
      
      // Read 20 bytes and save it
      } else if (flag == FLAG_SAVE_ADDRESS) {
        address addr;
        (addr, newPointer) = msg.data.readAddress(newPointer);
        knownAdresses[nextIndexAddress()] = addr;
        data = msg.data[newPointer - 20: newPointer];
        return (data, newPointer);

      // Read 32 bytes and save it
      } else if (flag == FLAG_SAVE_BYTES32) {
        bytes32 bytes32data;
        (bytes32data, newPointer) = msg.data.readBytes32(newPointer);
        knownBytes32s[nextIndexBytes32()] = bytes32data;
        data = msg.data[newPointer - 32: newPointer];
        return (data, newPointer);

      // Read 32 bytes using a 2 to 5 bytes pointer - 0x23 0x24 0x25 0x26
      } else if (flag >= FLAG_READ_BYTES32_2_BYTES && flag < FLAG_READ_BYTES32_5_BYTES) {
        uint256 index;
        uint256 b = flag - 0x21;
        (index, newPointer) = msg.data.readUintX(b, newPointer);
        data = abi.encode(knownBytes32s[index]);
        return (data, newPointer);

      // Read an address using a 2 to 5 bytes pointer - 0x27 0x28 0x29 0x2a
      } else if (flag >= FLAG_READ_ADDRESS_2_BYTES && flag < FLAG_READ_ADDRESS_5_BYTES) {
        uint256 index;
        uint256 b = flag - 0x25;
        (index, newPointer) = msg.data.readUintX(b, newPointer);
        data = abi.encodePacked(knownAdresses[index]);
        return (data, newPointer);

      // Read power of 2
      } else if (flag == 0x2b) {
        uint256 power;
        (power, newPointer) = msg.data.readUint8(newPointer);
        data = abi.encode(2 ** power);
        return (data, newPointer);

      // Nothing
      } else if (flag == 0x2c) {
        return (data, newPointer);

      // ONE
      } else if (flag == 0x2d) {
        data = abi.encode(1);
        return (data, newPointer);

      // Complex (dynamic size, many reads)
      } else if (flag == 0x2e) {
        bytes memory scrap;

        (scrap, newPointer) = readAdvanced(newPointer);
        uint256 size = bytesToUint256(scrap);

        for (uint256 read = 0; read < size;) {
          (scrap, newPointer) = readAdvanced(newPointer);
          data = abi.encodePacked(data, scrap);
          read += scrap.length;
        }

        return (data, newPointer);

      // Read size and that many bytes
      } else if (flag == FLAG_READ_N_BYTES) {
        bytes memory scrap;

        (scrap, newPointer) = readAdvanced(newPointer);
        uint256 size = bytesToUint256(scrap);

        uint256 nextPointer = newPointer + size;
        data = msg.data[newPointer:nextPointer];
        newPointer = nextPointer;

        return (data, newPointer);

      // Read abi pending encode
      } else if (flag <= FLAG_ABI_6_PARAMS) {
        // Read the number of params
        uint256 nparams = flag - FLAG_ABI_1_PARAM + 1;

        // Read selector
        bytes4 selector;
        (selector, newPointer) = msg.data.readBytes4(newPointer);

        data = abi.encodePacked(selector);
        bytes memory data2;

        for (uint256 i = 0; i < nparams; i++) {
          (data2, newPointer) = readAdvanced(newPointer);
          // TODO: Handle dynamic data

          data = abi.encodePacked(data, abi.encode(bytesToUint256(data2)));
        }

        return (data, newPointer);

      // Read signature
      } else if (flag <= FLAG_SIGNATURE_W4) {
        uint256 weight = flag - FLAG_SIGNATURE + 1;
        if (weight == 0) {
          // Then the weight must be loaded from the next byte
          (weight, newPointer) = msg.data.readUint8(newPointer);
        }

        // Sequence EOA signatures use 66 bytes
        // these will never be a pointer
        uint256 nextPointer = newPointer + 66;
        data = abi.encodePacked(uint8(SequenceBaseSig.FLAG_SIGNATURE), uint8(weight), msg.data[newPointer:nextPointer]);
        newPointer = nextPointer;

        return (data, newPointer);

      // Read address
      } else if (flag <= FLAG_ADDRESS_W4) {
        uint256 weight;
        if (flag == FLAG_ADDRESS) {
          // Then the weight must be loaded from the next byte
          (weight, newPointer) = msg.data.readUint8(newPointer);
        } else {
          weight = flag - FLAG_ADDRESS_W0;
        }

        // Read advanced, since the address may be known
        (data, newPointer) = readAdvanced(newPointer);
        address addr = bytesToAddress(data);
        data = abi.encodePacked(uint8(SequenceBaseSig.FLAG_ADDRESS), uint8(weight), addr);

        return (data, newPointer);
      
      // Read dynamic signature
      } else if (flag == FLAG_DYNAMIC_SIGNATURE) {
        // Read weigth, always 1 byte
        uint256 weight;
        (weight, newPointer) = msg.data.readUint8(newPointer);

        // Read address, use advanced read as it may be a pointer
        (data, newPointer) = readAdvanced(newPointer);
        address addr = bytesToAddress(data);

        // Read rest of the signature
        // use advanced, as it may contain more pointers!
        (data, newPointer) = readAllSignature(newPointer);

        // Encode everything packed together
        data = abi.encodePacked(uint8(SequenceBaseSig.FLAG_DYNAMIC_SIGNATURE), uint8(weight), addr, uint24(data.length + 1), data, uint8(3));
        return (data, newPointer);

      // Read node
      } else if (flag == FLAG_NODE) {
        // Use advanced as it may contain a pointer
        (data, newPointer) = readAdvanced(newPointer);
        uint256 node = bytesToUint256(data);
        data = abi.encodePacked(uint8(SequenceBaseSig.FLAG_NODE), node);

        return (data, newPointer);

      // Read branch
      } else if (flag == FLAG_BRANCH) {
        (data, newPointer) = readSignatureBranch(newPointer);
        data = abi.encodePacked(uint8(SequenceBaseSig.FLAG_BRANCH), uint24(data.length), data);

        return (data, newPointer);

      // Read nested
      } else if (flag == FLAG_NESTED) {
        uint256 externalWeight;
        (externalWeight, newPointer) = msg.data.readUint8(newPointer);

        (data, newPointer) = readAdvanced(newPointer);
        uint256 internalThreshold = bytesToUint256(data);

        (data, newPointer) = readSignatureBranch(newPointer);
        data = abi.encodePacked(uint8(SequenceBaseSig.FLAG_NESTED), uint8(externalWeight), uint8(internalThreshold), uint24(data.length), data);

        return (data, newPointer);

      // Read subdigest
      } else if (flag == FLAG_SUBDIGEST) {
        (data, newPointer) = readAdvanced(newPointer);
        uint256 subdigest = bytesToUint256(data);
        data = abi.encodePacked(uint8(SequenceBaseSig.FLAG_SUBDIGEST), subdigest);

        return (data, newPointer);
      }

      // If no flag is defined, then this is a literal number
      uint8 val = uint8(flag) - HIGHEST_FLAG;
      return (abi.encodePacked(val), newPointer);

      // revert UnknownFlag(flag, _pointer);
    }
  }
}

contract L2SequenceCompressor is L2SequenceDecompressor {
  using LibBytesPointer for bytes;
  using LibBytes for bytes;

  function encodeSequenceTransaction(
    address _wallet,
    IModuleCalls.Transaction[] memory _transactions,
    uint256 _nonce,
    bytes calldata _signature
  ) external view returns (bytes memory encoded) {
    // Encode the wallet address first
    encoded = encodeAddress(_wallet);

    // Encode the number of transactions
    encoded = abi.encodePacked(encoded, encode(_transactions.length));

    // Encode every transaction one after another
    for (uint256 i = 0; i < _transactions.length; i++) {
      encoded = abi.encodePacked(encoded, encodeTransaction(_wallet, _transactions[i]));
    }

    // Encode nonce
    encoded = abi.encodePacked(encoded, encodeNonce(_nonce));

    // Encode signature
    encoded = abi.encodePacked(encoded, encodeSignature(_signature));
  }

  function requiredBytesFor(bytes32 value) internal pure returns (uint8) {
    return requiredBytesFor(uint256(value));
  }

  function requiredBytesFor(uint256 value) internal pure returns (uint8) {
    if (value <= type(uint8).max) {
      return 1;
    } else if (value <= type(uint16).max) {
      return 2;
    } else if (value <= type(uint24).max) {
      return 3;
    } else if (value <= type(uint32).max) {
      return 4;
    } else if (value <= type(uint40).max) {
      return 5;
    } else if (value <= type(uint48).max) {
      return 6;
    } else if (value <= type(uint56).max) {
      return 7;
    } else if (value <= type(uint64).max) {
      return 8;
    } else if (value <= type(uint72).max) {
      return 9;
    } else if (value <= type(uint80).max) {
      return 10;
    } else if (value <= type(uint88).max) {
      return 11;
    } else if (value <= type(uint96).max) {
      return 12;
    } else if (value <= type(uint104).max) {
      return 13;
    } else if (value <= type(uint112).max) {
      return 14;
    } else if (value <= type(uint120).max) {
      return 15;
    } else if (value <= type(uint128).max) {
      return 16;
    } else if (value <= type(uint136).max) {
      return 17;
    } else if (value <= type(uint144).max) {
      return 18;
    } else if (value <= type(uint152).max) {
      return 19;
    } else if (value <= type(uint160).max) {
      return 20;
    } else if (value <= type(uint168).max) {
      return 21;
    } else if (value <= type(uint176).max) {
      return 22;
    } else if (value <= type(uint184).max) {
      return 23;
    } else if (value <= type(uint192).max) {
      return 24;
    } else if (value <= type(uint200).max) {
      return 25;
    } else if (value <= type(uint208).max) {
      return 26;
    } else if (value <= type(uint216).max) {
      return 27;
    } else if (value <= type(uint224).max) {
      return 28;
    } else if (value <= type(uint232).max) {
      return 29;
    } else if (value <= type(uint240).max) {
      return 30;
    } else if (value <= type(uint248).max) {
      return 31;
    }

    return 32;
  }

  function packToBytes(bytes32 value, uint256 b) internal pure returns (bytes memory) {
    return packToBytes(uint256(value), b);
  }

  function packToBytes(uint256 value, uint256 b) internal pure returns (bytes memory) {
    if (b == 1) {
      return abi.encodePacked(uint8(value));
    } else if (b == 2) {
      return abi.encodePacked(uint16(value));
    } else if (b == 3) {
      return abi.encodePacked(uint24(value));
    } else if (b == 4) {
      return abi.encodePacked(uint32(value));
    } else if (b == 5) {
      return abi.encodePacked(uint40(value));
    } else if (b == 6) {
      return abi.encodePacked(uint48(value));
    } else if (b == 7) {
      return abi.encodePacked(uint56(value));
    } else if (b == 8) {
      return abi.encodePacked(uint64(value));
    } else if (b == 9) {
      return abi.encodePacked(uint72(value));
    } else if (b == 10) {
      return abi.encodePacked(uint80(value));
    } else if (b == 11) {
      return abi.encodePacked(uint88(value));
    } else if (b == 12) {
      return abi.encodePacked(uint96(value));
    } else if (b == 13) {
      return abi.encodePacked(uint104(value));
    } else if (b == 14) {
      return abi.encodePacked(uint112(value));
    } else if (b == 15) {
      return abi.encodePacked(uint120(value));
    } else if (b == 16) {
      return abi.encodePacked(uint128(value));
    } else if (b == 17) {
      return abi.encodePacked(uint136(value));
    } else if (b == 18) {
      return abi.encodePacked(uint144(value));
    } else if (b == 19) {
      return abi.encodePacked(uint152(value));
    } else if (b == 20) {
      return abi.encodePacked(uint160(value));
    } else if (b == 21) {
      return abi.encodePacked(uint168(value));
    } else if (b == 22) {
      return abi.encodePacked(uint176(value));
    } else if (b == 23) {
      return abi.encodePacked(uint184(value));
    } else if (b == 24) {
      return abi.encodePacked(uint192(value));
    } else if (b == 25) {
      return abi.encodePacked(uint200(value));
    } else if (b == 26) {
      return abi.encodePacked(uint208(value));
    } else if (b == 27) {
      return abi.encodePacked(uint216(value));
    } else if (b == 28) {
      return abi.encodePacked(uint224(value));
    } else if (b == 29) {
      return abi.encodePacked(uint232(value));
    } else if (b == 30) {
      return abi.encodePacked(uint240(value));
    } else if (b == 31) {
      return abi.encodePacked(uint248(value));
    } else if (b == 32) {
      return abi.encodePacked(uint256(value));
    } else {
      revert("Invalid number of bytes");
    }
  }

  function encodeNonce(uint256 _nonce) internal view returns (bytes memory encoded) {
    unchecked {
      (uint256 space, uint256 nonce) = SubModuleNonce.decodeNonce(_nonce);
      return abi.encodePacked(encode(space), encode(nonce));
    }
  }

  function encodeTransaction(address _wallet, IModuleCalls.Transaction memory _tx) internal view returns (bytes memory data) {
    unchecked {
      // TODO: Handle nested sequence

      bool hasValue = _tx.value != 0;
      bool hasGasLimit = _tx.gasLimit != 0;
      bool hasData = _tx.data.length != 0;
      bool selfTarget = _tx.target == _wallet;

      uint8 flag = 0;

      if (_tx.delegateCall) {
        flag |= 0x80;
      }

      if (_tx.revertOnError) {
        flag |= 0x40;
      }

      if (hasGasLimit) {
        flag |= 0x20;

        data = encode(_tx.gasLimit);
      }

      if (hasValue) {
        flag |= 0x10;

        data = abi.encodePacked(data, encode(_tx.value));
      }

      if (hasData) {
        flag |= 0x08;

        data = abi.encodePacked(data, encodeCalldata(_tx.data));
      }

      if (selfTarget) {
        flag |= 0x04;
      } else {
        data = abi.encodePacked(data, encodeAddress(_tx.target));
      }

      data = abi.encodePacked(flag, data);
    }
  }

  function encodeAddress(address _addr) internal view returns (bytes memory encoded) {
    unchecked {
      // Find address in knownAdresses
      (uint256 size,) = numKnownAddresses();

      for (uint256 i = 0; i < size; i++) {
        if (knownAdresses[i] == _addr) {
          uint256 needs = requiredBytesFor(i);
          needs = ((needs < 2) ? 2 : needs);
          uint8 flag = FLAG_READ_ADDRESS_2_BYTES + uint8(needs - 2);
          return abi.encodePacked(flag, packToBytes(i, needs));
        }
      }

      // If not found, then we can save it
      return abi.encodePacked(FLAG_SAVE_ADDRESS, _addr);
    }
  }

  function encodeBytes32(bytes32 _b) internal view returns (bytes memory encoded) {
    unchecked {
      // Find bytes32 in knownBytes32s
      (uint256 size,) = numKnownBytes32();

      for (uint256 i = 0; i < size; i++) {
        if (knownBytes32s[i] == _b) {
          uint256 needs = requiredBytesFor(i);
          needs = ((needs < 2) ? 2 : needs);
          uint8 flag = FLAG_READ_BYTES32_2_BYTES + uint8(needs - 2);
          return abi.encodePacked(flag, packToBytes(i, needs));
        }
      }

      return abi.encodePacked(FLAG_SAVE_BYTES32, _b);
    }
  }

  function encodeCalldata(bytes memory _b) internal view returns (bytes memory encoded) {
    // Not calldata
    if (_b.length < 4 || (_b.length - 4) % 32 != 0) {
      return encodeBytes(_b);
    }

    // Too many params
    uint256 paramsNum = (_b.length - 4) / 32;
    if (paramsNum > 6) {
      return encodeBytes(_b);
    }

    // If all entries require 256 bits then we should just encode it as bytes
    bool canOptimize;

    for (uint256 i = 4; i < _b.length; i += 32) {
      if (requiredBytesFor(_b.readMBytes32(i)) != 32) {
        canOptimize = true;
        break;
      }
    }

    if (!canOptimize) {
      return encodeBytes(_b);
    }

    bytes4 selector = _b.readMBytes4(0);
    uint8 flag = uint8(FLAG_ABI_1_PARAM + paramsNum - 1);

    encoded = abi.encodePacked(flag, selector);

    for (uint256 i = 4; i < _b.length; i += 32) {
      encoded = abi.encodePacked(encoded, encode(_b.readMBytes32(i)));
    }
  }

  function encodeSignature(bytes calldata _b) internal view returns (bytes memory encoded) {
    // If it does not start with 0x00, then we must just encode the bytes
    if (_b.length == 0 || (_b[0] != 0x00 && _b[0] != 0x01) || _b.length < 6) {
      return abi.encodePacked(bytes1(0x00), encodeBytes(_b));
    }

    uint256 threshold;
    uint256 rindex = 1;

    // Start by decode the threshold, this is just the next byte or two
    if (_b[0] == 0x00) {
      threshold = uint256(uint8(_b[rindex]));
      rindex += 1;
    } else {
      (threshold, rindex) = _b.readUint16(rindex);
    }

    // Now decode the checkpoint, this is the next 4 bytes
    uint256 checkpoint = uint32(_b.readMBytes4(rindex));
    rindex += 4;

    // Encode branch
    bool failed;
    (encoded, failed) = encodeSignatureBranch(_b, rindex);

    if (failed) {
      return abi.encodePacked(uint8(0x00), encodeBytes(_b));
    }

    encoded = abi.encodePacked(uint8(0x01), encode(threshold), encode(checkpoint), encoded);
  }

  function encodeSignatureBranch(bytes calldata _b, uint256 _rindex) internal view returns (bytes memory encoded, bool failed) {
    uint256 totalParts;
    uint256 rindex = _rindex;

    // Now decode part by part, until the signature is complete
    while (rindex < _b.length) {
      // Read next item type
      uint256 flag;
      (flag, rindex) = LibBytesPointer.readUint8(_b, rindex);

      totalParts++;

      if (flag == SequenceBaseSig.FLAG_ADDRESS) {
        uint8 addrWeight; address addr;
        (addrWeight, addr, rindex) = _b.readUint8Address(rindex);

        // If weight is <= 4, then it is encoded on the flag
        // if not we need flag + weight
        if (addrWeight > 4) {
          encoded = abi.encodePacked(encoded, FLAG_ADDRESS, uint8(addrWeight), encodeAddress(addr));
        } else {
          uint8 flag2 = FLAG_ADDRESS_W0 + addrWeight;
          encoded = abi.encodePacked(encoded, flag2, encodeAddress(addr));
        }

        continue;
      }

      if (flag == SequenceBaseSig.FLAG_SIGNATURE) {
        // Read weight
        uint8 addrWeight;
        (addrWeight, rindex) = LibBytesPointer.readUint8(_b, rindex);

        // Read single signature and recover signer
        uint256 nrindex = rindex + 66;
        if (nrindex > _b.length) {
          return (encoded, true);
        }

        bytes memory signature = _b[rindex:nrindex];
        rindex = nrindex;

        if (addrWeight > 4) {
          encoded = abi.encodePacked(encoded, FLAG_SIGNATURE, uint8(addrWeight), signature);
        } else {
          uint8 flag2 = FLAG_SIGNATURE_W1 + addrWeight - 2;
          encoded = abi.encodePacked(encoded, flag2, signature);
        }

        continue;
      }

      if (flag == SequenceBaseSig.FLAG_DYNAMIC_SIGNATURE) {        // Read signer and weight
        uint8 addrWeight; address addr;
        (addrWeight, addr, rindex) = _b.readUint8Address(rindex);

        // Read signature size
        uint256 size;
        (size, rindex) = _b.readUint24(rindex);

        // Read dynamic size signature
        uint256 nrindex = rindex + size;
        if (nrindex > _b.length) {
          return (encoded, true);
        }

        // If last byte is not 0x03 lets abort, but if it is
        // remove it. The encoder knows to add it bacl.
        if (_b[nrindex - 1] != 0x03) {
          return (encoded, true);
        }

        bytes calldata signature = _b[rindex:nrindex - 1];
        rindex = nrindex;

        bytes memory r = encodeSignature(signature);
        encoded = abi.encodePacked(encoded, FLAG_DYNAMIC_SIGNATURE, uint8(addrWeight), encodeAddress(addr), r);
        continue;
      }

      if (flag == SequenceBaseSig.FLAG_NODE) {
        // Read node hash
        bytes32 node;
        (node, rindex) = LibBytesPointer.readBytes32(_b, rindex);

        encoded = abi.encodePacked(encoded, FLAG_NODE, encode(node));

        continue;
      }

      if (flag == SequenceBaseSig.FLAG_BRANCH) {
        // Enter a branch of the signature merkle tree
        uint256 size;
        (size, rindex) = _b.readUint24(rindex);

        uint256 nrindex = rindex + size;
        if (nrindex > _b.length) {
          return (encoded, true);
        }
        bytes calldata data = _b[rindex:nrindex];
        rindex = nrindex;

        bytes memory sub;
        (sub, failed) = encodeSignatureBranch(data, 0);
        if (failed) {
          return (encoded, true);
        }

        encoded = abi.encodePacked(encoded, FLAG_BRANCH, sub);

        continue;
      }

      if (flag == SequenceBaseSig.FLAG_NESTED) {
        // Enter a branch of the signature merkle tree
        // but with an internal threshold and an external fixed weight
        uint256 externalWeight;
        (externalWeight, rindex) = LibBytesPointer.readUint8(_b, rindex);

        uint256 internalThreshold;
        (internalThreshold, rindex) = _b.readUint16(rindex);

        uint256 size;
        (size, rindex) = _b.readUint24(rindex);
        uint256 nrindex = rindex + size;
        if (nrindex > _b.length) {
          return (encoded, true);
        }
        bytes calldata data = _b[rindex:nrindex];
        rindex = nrindex;

        bytes memory sub;
        (sub, failed) = encodeSignatureBranch(data, 0);
        if (failed) {
          return (encoded, true);
        }

        encoded = abi.encodePacked(encoded, FLAG_NESTED, uint8(externalWeight), encode(internalThreshold), sub);

        continue;
      }

      if (flag == FLAG_SUBDIGEST) {
        // A hardcoded always accepted digest
        // it pushes the weight to the maximum
        bytes32 hardcoded;
        (hardcoded, rindex) = LibBytesPointer.readBytes32(_b, rindex);

        encoded = abi.encodePacked(encoded, FLAG_SUBDIGEST, encode(hardcoded));
        continue;
      }

      // There is something wrong here, this doesn't look like a normal sequence signature
      // we can still salvage it by encoding it as a regular set of bytes
      return (encoded, true);
    }

    encoded = abi.encodePacked(encode(totalParts), encoded);
  }

  function encodeBytes(bytes memory _b) internal view returns (bytes memory encoded) {
    return abi.encodePacked(FLAG_READ_N_BYTES, encode(_b.length), _b);
  }

  function encode(uint256 _val) internal view returns (bytes memory encoded) {
    return encode(bytes32(_val));
  }

  function encode(bytes32 _val) internal view returns (bytes memory encoded) {
    if (_val == 0) {
      return abi.encodePacked(FLAG_READ_BYTES32_0_BYTES);
    }

    // If value is below (type(uint8).max - HIGHEST_FLAG)
    // then it can be encoded directly on the FLAG by adding HIGHEST_FLAG
    if (uint256(_val) <= type(uint8).max - HIGHEST_FLAG) {
      return abi.encodePacked(uint8(uint256(_val)) + HIGHEST_FLAG);
    }

    // TODO Encode as raw value (1 to 64 maybe ?)
    uint256 needs = requiredBytesFor(_val);

    // If it needs 20 bytes can be encoded as an address
    if (needs == 20) {
      return encodeAddress(address(uint160(uint256(_val))));
    }

    // If it needs 32 bytes, can be encoded as a hash
    if (needs == 32) {
      return encodeBytes32(_val);
    }

    uint8 flag = FLAG_READ_BYTES32_0_BYTES + uint8(needs);
    return abi.encodePacked(flag, packToBytes(_val, needs));
  }
}

contract CompressCalldata {
    L2SequenceCompressor private immutable imp;

    constructor(L2SequenceCompressor _imp) {
        imp = _imp;
    }

    function compress(address _wallet, bytes calldata _data) external view returns (bytes memory) {
        (
            IModuleCalls.Transaction[] memory transactions,
            uint256 nonce,
            bytes memory signature
        ) = abi.decode(_data[4:], (IModuleCalls.Transaction[], uint256, bytes));

        return imp.encodeSequenceTransaction(_wallet, transactions, nonce, signature);
    }
}