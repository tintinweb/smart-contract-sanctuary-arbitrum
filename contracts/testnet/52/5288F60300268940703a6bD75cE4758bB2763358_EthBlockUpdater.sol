// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/IBlockUpdater.sol";
import "../libraries/ScaleCodec.sol";
import "./MerkleProof.sol";
import "./EthBlockVerifier.sol";
import "./EthSyncCommitteeVerifier.sol";

contract EthBlockUpdater is IBlockUpdater, EthBlockVerifier, EthSyncCommitteeVerifier, MerkleProof, Initializable, OwnableUpgradeable {
    event ImportSyncCommitteeRoot(uint64 indexed period, bytes32 indexed syncCommitteeRoot);
    event ModBlockConfirmation(uint256 oldBlockConfirmation, uint256 newBlockConfirmation);

    struct SyncCommitteeInput {
        uint64 period;
        bytes32 syncCommitteeRoot;
        bytes32 nextSyncCommitteeRoot;
    }

    struct BlockInput {
        uint64 slot;
        bytes32 syncCommitteeRoot;
        bytes32 receiptHash;
        bytes32 blockHash;
        uint256 blockConfirmation;
    }

    struct SyncCommitteeProof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[3] inputs;
    }

    struct BlockProof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[7] inputs;
    }

    struct Chain {
        uint64 slot;
        uint64 proposerIndex;
        bytes32 parentRoot;
        bytes32 stateRoot;
        bytes32 bodyRoot;
        bytes32 domain;
        bytes32 blockHash;
        bytes32 receiptRoot;
        bytes32 payloadHash;
        bytes32[] receiptBranch;
        bytes32[] payloadBranch;
        bytes32[] bodyBranch;
        bytes32[] headerBranch;
        bytes32[] blockHashBranch;
    }

    // period=>syncCommitteeRoot
    mapping(uint64 => bytes32) public syncCommitteeRoots;

    // blockHash=>receiptsRoot =>BlockConfirmation
    mapping(bytes32 => mapping(bytes32 => uint256)) public blockInfos;

    uint256 public minBlockConfirmation;

    uint64 public currentPeriod;

    function initialize(uint64 period, bytes32 syncCommitteeRoot, uint256 _minBlockConfirmation) public initializer {
        __Ownable_init();
        currentPeriod = period;
        syncCommitteeRoots[period] = syncCommitteeRoot;
        minBlockConfirmation = _minBlockConfirmation;
    }

    function importNextSyncCommittee(bytes calldata _proof) external {
        SyncCommitteeProof memory proofData;
        (proofData.a, proofData.b, proofData.c, proofData.inputs) = abi.decode(_proof, (uint256[2], uint256[2][2], uint256[2], uint256[3]));
        SyncCommitteeInput memory input = _parseInput(proofData.inputs);

        uint64 nextPeriod = input.period + 1;
        require(syncCommitteeRoots[input.period] == input.syncCommitteeRoot, "invalid syncCommitteeRoot");
        require(syncCommitteeRoots[nextPeriod] == bytes32(0), "nextSyncCommitteeRoot already exist");

        uint256[1] memory compressInput;
        compressInput[0] = _hashInput(proofData.inputs);
        require(verifyCommitteeProof(proofData.a, proofData.b, proofData.c, compressInput), "invalid proof");
        syncCommitteeRoots[nextPeriod] = input.nextSyncCommitteeRoot;
        currentPeriod = nextPeriod;
        emit ImportSyncCommitteeRoot(nextPeriod, input.nextSyncCommitteeRoot);
    }

    function importBlock(bytes calldata _proof) external {
        BlockProof memory proofData;
        (proofData.a, proofData.b, proofData.c, proofData.inputs) = abi.decode(_proof, (uint256[2], uint256[2][2], uint256[2], uint256[7]));
        BlockInput memory parsedInput = _parseInput(proofData.inputs);

        require(parsedInput.blockConfirmation >= minBlockConfirmation, "Not enough block confirmations");
        (bool exist,uint256 blockConfirmation) = _checkBlock(parsedInput.blockHash, parsedInput.receiptHash);
        if (exist && parsedInput.blockConfirmation <= blockConfirmation) {
            revert("already exist");
        }
        uint64 period = _computeSyncCommitteePeriod(parsedInput.slot);
        require(syncCommitteeRoots[period] == parsedInput.syncCommitteeRoot, "invalid committeeRoot");

        uint256[1] memory compressInput;
        compressInput[0] = _hashInput(proofData.inputs);
        require(verifyBlockProof(proofData.a, proofData.b, proofData.c, compressInput), "invalid proof");

        blockInfos[parsedInput.blockHash][parsedInput.receiptHash] = parsedInput.blockConfirmation;
        emit ImportBlock(parsedInput.slot, parsedInput.blockHash, parsedInput.receiptHash);
    }

    function checkBlock(bytes32 _blockHash, bytes32 _receiptHash) external view returns (bool, uint256) {
        return _checkBlock(_blockHash, _receiptHash);
    }

    function submitBlockChain(Chain[] calldata blockChains) external {
        require(blockChains.length > 1, "invalid chain length");
        uint256 firstBlockConfirmation;
        for (uint i = 0; i < blockChains.length; i++) {
            Chain memory blockChain = blockChains[i];
            bytes32[] memory leaves = new bytes32[](5);
            leaves[0] = bytes32(_toLittleEndian64(blockChain.slot));
            leaves[1] = bytes32(_toLittleEndian64(blockChain.proposerIndex));
            leaves[2] = blockChain.parentRoot;
            leaves[3] = blockChain.stateRoot;
            leaves[4] = blockChain.bodyRoot;
            bytes32 headerHash = merkleRoot(leaves);
            if (i == 0) {
                (bool exist,uint256 blockConfirmation) = _checkBlock(blockChain.blockHash, blockChain.receiptRoot);
                require(exist, "invalid proof");
                firstBlockConfirmation = blockConfirmation;
            } else {
                require(headerHash == blockChains[i - 1].parentRoot, "invalid proof");
            }
            require(isValidMerkleBranch(blockChain.receiptBranch, blockChain.receiptRoot, blockChain.payloadHash, 3, 4), "invalid receiptBranch");
            require(isValidMerkleBranch(blockChain.payloadBranch, blockChain.payloadHash, blockChain.bodyRoot, 9, 4), "invalid payloadBranch");
            require(isValidMerkleBranch(blockChain.blockHashBranch, blockChain.blockHash, blockChain.payloadHash, 12, 4), "invalid headerBranch");
            if (i != 0) {
                blockInfos[blockChain.blockHash][blockChain.receiptRoot] = firstBlockConfirmation + i;
                emit ImportBlock(blockChain.slot, blockChain.blockHash, blockChain.receiptRoot);
            }
        }
    }

    function _checkBlock(bytes32 _blockHash, bytes32 _receiptHash) internal view returns (bool, uint256) {
        uint256 blockConfirmation = blockInfos[_blockHash][_receiptHash];
        if (blockConfirmation > 0) {
            return (true, blockConfirmation);
        }
        return (false, blockConfirmation);
    }

    function _toLittleEndian64(uint64 value) internal pure returns (bytes8) {
        return ScaleCodec.encode64(value);
    }

    function _parseInput(uint256[3] memory _inputs) internal pure returns (SyncCommitteeInput memory) {
        SyncCommitteeInput memory result;
        result.syncCommitteeRoot = bytes32(_inputs[0]);
        result.nextSyncCommitteeRoot = bytes32(_inputs[1]);
        result.period = uint64(_inputs[2]);
        return result;
    }

    function _parseInput(uint256[7] memory _inputs) internal pure returns (BlockInput memory) {
        BlockInput memory result;
        result.slot = uint64(_inputs[0]);
        result.syncCommitteeRoot = bytes32(_inputs[1]);
        result.receiptHash = bytes32((_inputs[2] << 128) | _inputs[3]);
        result.blockHash = bytes32((_inputs[4] << 128) | _inputs[5]);
        result.blockConfirmation = _inputs[6];
        return result;
    }

    function _hashInput(uint256[3] memory _inputs) internal pure returns (uint256) {
        uint256 computedHash = uint256(keccak256(abi.encodePacked(_inputs[0], _inputs[1], _inputs[2])));
        return computedHash / 256;
    }

    function _hashInput(uint256[7] memory _inputs) internal pure returns (uint256) {
        uint256 computedHash = uint256(keccak256(abi.encodePacked(_inputs[0], _inputs[1], _inputs[2], _inputs[3], _inputs[4], _inputs[5], _inputs[6])));
        return computedHash / 256;
    }

    function _computeSyncCommitteePeriod(uint64 slot) internal pure returns (uint64) {
        return slot / 32 / 256;
    }

    //----------------------------------------------------------------------------------
    // onlyOwner
    function setBlockConfirmation(uint256 _minBlockConfirmation) external onlyOwner {
        emit ModBlockConfirmation(minBlockConfirmation, _minBlockConfirmation);
        minBlockConfirmation = _minBlockConfirmation;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBlockUpdater {
    event ImportBlock(uint256 identifier, bytes32 blockHash, bytes32 receiptHash);

    function importBlock(bytes calldata _proof) external;

    function checkBlock(bytes32 _blockHash, bytes32 _receiptsRoot) external view returns (bool, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ScaleCodec {
    // Decodes a SCALE encoded uint256 by converting bytes (bid endian) to little endian format
    function decodeUint256(bytes memory data) internal pure returns (uint256) {
        uint256 number;
        for (uint256 i = data.length; i > 0; i--) {
            number = number + uint256(uint8(data[i - 1])) * (2**(8 * (i - 1)));
        }
        return number;
    }

    // Decodes a SCALE encoded compact unsigned integer
    function decodeUintCompact(bytes memory data)
        internal
        pure
        returns (uint256 v)
    {
        uint8 b = readByteAtIndex(data, 0); // read the first byte
        uint8 mode = b & 3; // bitwise operation

        if (mode == 0) {
            // [0, 63]
            return b >> 2; // right shift to remove mode bits
        } else if (mode == 1) {
            // [64, 16383]
            uint8 bb = readByteAtIndex(data, 1); // read the second byte
            uint64 r = bb; // convert to uint64
            r <<= 6; // multiply by * 2^6
            r += b >> 2; // right shift to remove mode bits
            return r;
        } else if (mode == 2) {
            // [16384, 1073741823]
            uint8 b2 = readByteAtIndex(data, 1); // read the next 3 bytes
            uint8 b3 = readByteAtIndex(data, 2);
            uint8 b4 = readByteAtIndex(data, 3);

            uint32 x1 = uint32(b) | (uint32(b2) << 8); // convert to little endian
            uint32 x2 = x1 | (uint32(b3) << 16);
            uint32 x3 = x2 | (uint32(b4) << 24);

            x3 >>= 2; // remove the last 2 mode bits
            return uint256(x3);
        } else if (mode == 3) {
            // [1073741824, 4503599627370496]
            // solhint-disable-next-line
            uint8 l = b >> 2; // remove mode bits
            require(
                l > 32,
                "Not supported: number cannot be greater than 32 bytes"
            );
        } else {
            revert("Code should be unreachable");
        }
    }

    // Read a byte at a specific index and return it as type uint8
    function readByteAtIndex(bytes memory data, uint8 index)
        internal
        pure
        returns (uint8)
    {
        return uint8(data[index]);
    }

    // Sources:
    //   * https://ethereum.stackexchange.com/questions/15350/how-to-convert-an-bytes-to-address-in-solidity/50528
    //   * https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel

    function reverse256(uint256 input) internal pure returns (uint256 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64) |
            ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    function reverse128(uint128 input) internal pure returns (uint128 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = (v >> 64) | (v << 64);
    }

    function reverse64(uint64 input) internal pure returns (uint64 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = (v >> 32) | (v << 32);
    }

    function reverse32(uint32 input) internal pure returns (uint32 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00) >> 8) |
            ((v & 0x00FF00FF) << 8);

        // swap 2-byte long pairs
        v = (v >> 16) | (v << 16);
    }

    function reverse16(uint16 input) internal pure returns (uint16 v) {
        v = input;

        // swap bytes
        v = (v >> 8) | (v << 8);
    }

    function encode256(uint256 input) internal pure returns (bytes32) {
        return bytes32(reverse256(input));
    }

    function encode128(uint128 input) internal pure returns (bytes16) {
        return bytes16(reverse128(input));
    }

    function encode64(uint64 input) internal pure returns (bytes8) {
        return bytes8(reverse64(input));
    }

    function encode32(uint32 input) internal pure returns (bytes4) {
        return bytes4(reverse32(input));
    }

    function encode16(uint16 input) internal pure returns (bytes2) {
        return bytes2(reverse16(input));
    }

    function encode8(uint8 input) internal pure returns (bytes1) {
        return bytes1(input);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Math.sol";

contract MerkleProof is Math {
    // Check if ``leaf`` at ``index`` verifies against the Merkle ``root`` and ``branch``.
    function isValidMerkleBranch(
        bytes32[] memory branch,
        bytes32 leaf,
        bytes32 root,
        uint64 index,
        uint64 depth
    ) internal pure returns (bool) {
        bytes32 value = leaf;
        for (uint i = 0; i < depth; ++i) {
            if ((index / (2 ** i)) % 2 == 1) {
                value = hashNode(branch[i], value);
            } else {
                value = hashNode(value, branch[i]);
            }
        }
        return value == root;
    }

    function merkleRoot(bytes32[] memory leaves) internal pure returns (bytes32) {
        uint len = leaves.length;
        if (len == 0) return bytes32(0);
        else if (len == 1) return hash(abi.encodePacked(leaves[0]));
        else if (len == 2) return hashNode(leaves[0], leaves[1]);
        uint bottomLength = getPowerOfTwoCeil(len);
        bytes32[] memory o = new bytes32[](bottomLength * 2);
        for (uint i = 0; i < len; ++i) {
            o[bottomLength + i] = leaves[i];
        }
        for (uint i = bottomLength - 1; i > 0; --i) {
            o[i] = hashNode(o[i * 2], o[i * 2 + 1]);
        }
        return o[1];
    }


    function hashNode(bytes32 left, bytes32 right)
    internal
    pure
    returns (bytes32)
    {
        return hash(abi.encodePacked(left, right));
    }

    function hash(bytes memory value) internal pure returns (bytes32) {
        return sha256(value);
    }
}

// SPDX-License-Identifier: AML
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.0;

library PairingBlock {

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero.
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {

        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {

        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"PairingBlock-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {

        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"PairingBlock-mul-failed");
    }

    /* @return The result of computing the PairingBlock check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         PairingBlock([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {

        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];
        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"PairingBlock-opcode-failed");

        return out[0] != 0;
    }
}

contract EthBlockVerifier {

    using PairingBlock for *;

    uint256 constant SNARK_SCALAR_FIELD_BLOCK = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q_BLOCK = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKeyBlock {
        PairingBlock.G1Point alfa1;
        PairingBlock.G2Point beta2;
        PairingBlock.G2Point gamma2;
        PairingBlock.G2Point delta2;
        PairingBlock.G1Point[2] IC;
    }

    struct ProofBlock {
        PairingBlock.G1Point A;
        PairingBlock.G2Point B;
        PairingBlock.G1Point C;
    }

    function verifyingKeyBlock() internal pure returns (VerifyingKeyBlock memory vk) {
        vk.alfa1 = PairingBlock.G1Point(uint256(9203827759237709837504348430969254793097319949490781316685693218000021515609), uint256(14838442095521260060063775578530501769365150072379826577062312392099055915721));
        vk.beta2 = PairingBlock.G2Point([uint256(20093897186524078957578732406620989714372821949530021443888649999073583250493), uint256(1468192255581517853429108242180218700333128179000447111224938634038423978460)], [uint256(8745697471965331856304571523806891502658464493254273252965316588478107543689), uint256(2793462043703674474293882576721390533690878584928338506997812641530036378296)]);
        vk.gamma2 = PairingBlock.G2Point([uint256(21483205105891783423923170134278477845007608469102381673100416991195679193296), uint256(14189108572657090839857698231369677419722348741367439083429111761456907977673)], [uint256(14702346437311888352509868747545495717384256895487783841820428467119464542856), uint256(12055242067001869380424630948300150586935711562141326018199318341187870520268)]);
        vk.delta2 = PairingBlock.G2Point([uint256(8189919533831622029932570119213392706955894328616275380203188495554639555208), uint256(11693038529992975312953734755867791182236402311828433156590672744647116664561)], [uint256(13705044355488049104066743300561400649939514497001976527314327794409859715279), uint256(18228406805298889657334595749635564854254769449339335098473445877656179021135)]);
        vk.IC[0] = PairingBlock.G1Point(uint256(10862127412363470457322898985350774035943564160752466534897612693615782831025), uint256(14931756350147888434191511616151397683393667417895512366207609246278638789856));
        vk.IC[1] = PairingBlock.G1Point(uint256(5848672271106328841646664047597567968918239527483322431796475140317106593752), uint256(4520251936779133103686192102076318598907645996050810237451510370329890281152));
    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyBlockProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool r) {

        ProofBlock memory proof;
        proof.A = PairingBlock.G1Point(a[0], a[1]);
        proof.B = PairingBlock.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = PairingBlock.G1Point(c[0], c[1]);

        VerifyingKeyBlock memory vk = verifyingKeyBlock();

        // Compute the linear combination vk_x
        PairingBlock.G1Point memory vk_x = PairingBlock.G1Point(0, 0);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q_BLOCK, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q_BLOCK, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q_BLOCK, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q_BLOCK, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q_BLOCK, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q_BLOCK, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q_BLOCK, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q_BLOCK, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < SNARK_SCALAR_FIELD_BLOCK,"verifier-gte-snark-scalar-field");
            vk_x = PairingBlock.plus(vk_x, PairingBlock.scalar_mul(vk.IC[i + 1], input[i]));
        }

        vk_x = PairingBlock.plus(vk_x, vk.IC[0]);

        return PairingBlock.pairing(
            PairingBlock.negate(proof.A),
            proof.B,
            vk.alfa1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.C,
            vk.delta2
        );
    }
}

// SPDX-License-Identifier: AML
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.0;

library PairingCommittee {

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero.
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {

        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {

        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"PairingCommittee-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {

        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"PairingCommittee-mul-failed");
    }

    /* @return The result of computing the PairingCommittee check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         PairingCommittee([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {

        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];
        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"PairingCommittee-opcode-failed");

        return out[0] != 0;
    }
}

contract EthSyncCommitteeVerifier {

    using PairingCommittee for *;

    uint256 constant SNARK_SCALAR_FIELD_COMMITTEE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q_COMMITTEE = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKeyCommittee {
        PairingCommittee.G1Point alfa1;
        PairingCommittee.G2Point beta2;
        PairingCommittee.G2Point gamma2;
        PairingCommittee.G2Point delta2;
        PairingCommittee.G1Point[2] IC;
    }

    struct ProofCommittee {
        PairingCommittee.G1Point A;
        PairingCommittee.G2Point B;
        PairingCommittee.G1Point C;
    }

    function verifyingKeyCommittee() internal pure returns (VerifyingKeyCommittee memory vk) {
        vk.alfa1 = PairingCommittee.G1Point(uint256(16770822989613243612556678452097920003791065734773780470911883491045296706464), uint256(9278274023252642565211108150204809067069134712176200969578457796464943023993));
        vk.beta2 = PairingCommittee.G2Point([uint256(21146232862327838034852692501995081508517531381640405302853712165917422513928), uint256(1154541083326552036890572343530497537115121104169503471771463045892312309591)], [uint256(3432336658042147786047755837833344751717187604208891326066394962520253262505), uint256(10406218874226626163881392044901309629671483075002242578077019661807610146878)]);
        vk.gamma2 = PairingCommittee.G2Point([uint256(11237838809589982162878007505980226553339950016190125401669606228222177098772), uint256(5413805097140396971066633678671711086351226422393899705915114673085994505158)], [uint256(20121850307689690331913655600705520477874904543839088536879943872107353456152), uint256(13107751940696848319506482679301259064584477463621108734033141694534103949379)]);
        vk.delta2 = PairingCommittee.G2Point([uint256(9693655807265603202225851666074248614856983956605554475081987566471161283254), uint256(12842734534330813428027241830925970511201428067580416953129589500297200928107)], [uint256(7233920512440312039278287119517924553611137465973442374998712525382535892447), uint256(5715535092531098163617015099905835329031050606143308823823632161979761221058)]);
        vk.IC[0] = PairingCommittee.G1Point(uint256(9904810469860053014652392146958490925296446687315072543596979809341788717666), uint256(3175225030945461626916491640326059274132035698388686877527012637596301107574));
        vk.IC[1] = PairingCommittee.G1Point(uint256(17588115401267752078322916980043057036091806744812723134675970392349154139933), uint256(5062909511833349775663155847312015376991629050836625647104672708307704070337));
    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyCommitteeProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool r) {

        ProofCommittee memory proof;
        proof.A = PairingCommittee.G1Point(a[0], a[1]);
        proof.B = PairingCommittee.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = PairingCommittee.G1Point(c[0], c[1]);

        VerifyingKeyCommittee memory vk = verifyingKeyCommittee();

        // Compute the linear combination vk_x
        PairingCommittee.G1Point memory vk_x = PairingCommittee.G1Point(0, 0);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q_COMMITTEE, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q_COMMITTEE, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q_COMMITTEE, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q_COMMITTEE, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q_COMMITTEE, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q_COMMITTEE, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q_COMMITTEE, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q_COMMITTEE, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < SNARK_SCALAR_FIELD_COMMITTEE,"verifier-gte-snark-scalar-field");
            vk_x = PairingCommittee.plus(vk_x, PairingCommittee.scalar_mul(vk.IC[i + 1], input[i]));
        }

        vk_x = PairingCommittee.plus(vk_x, vk.IC[0]);

        return PairingCommittee.pairing(
            PairingCommittee.negate(proof.A),
            proof.B,
            vk.alfa1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.C,
            vk.delta2
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Math {
    /// Get the power of 2 for given input, or the closest higher power of 2 if the input is not a power of 2.
    /// Commonly used for "how many nodes do I need for a bottom tree layer fitting x elements?"
    /// Example: 0->1, 1->1, 2->2, 3->4, 4->4, 5->8, 6->8, 7->8, 8->8, 9->16.
    function getPowerOfTwoCeil(uint256 x) internal pure returns (uint256) {
        if (x <= 1) return 1;
        else if (x == 2) return 2;
        else return 2 * getPowerOfTwoCeil((x + 1) >> 1);
    }

    function log_2(uint256 x) internal pure returns (uint256 pow) {
        require(0 < x && x < 0x8000000000000000000000000000000000000000000000000000000000000001, "invalid");
        uint256 a = 1;
        while (a < x) {
            a <<= 1;
            pow++;
        }
    }

    function _max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
}