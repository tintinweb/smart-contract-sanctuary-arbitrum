// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../verifiers/zk-verifiers/common/IVerifier.sol";

interface ISMT {
    struct SmtUpdate {
        bytes32 newSmtRoot;
        uint64 endBlockNum;
        bytes32 endBlockHash;
        bytes32 nextChunkMerkleRoot;
        IVerifier.Proof proof;
        bytes32 commitPub;
    }

    function updateRoot(uint64 chainId, SmtUpdate memory u) external;

    function isSmtRootValid(uint64 chainId, bytes32 smtRoot) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IAnchorBlocks {
    function blocks(uint256 blockNum) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../light-client-eth/interfaces/IAnchorBlocks.sol";
import "../interfaces/ISMT.sol";

contract SMT is ISMT, Ownable {
    event SmtRootUpdated(bytes32 smtRoot, uint64 endBlockNum, uint8 bufferIndex);
    event AnchorProviderUpdated(uint64 chainId, address anchorProvider);
    event VerifierUpdated(uint64 chainId, address verifier);

    uint8 public constant BUFFER_SIZE = 16;

    mapping(uint64 => IAnchorBlocks) public anchorProviders;
    mapping(uint64 => IVerifier) public verifiers;

    mapping(uint64 => bytes32[BUFFER_SIZE]) public smtRoots;
    mapping(uint64 => uint8) public curBufferIndices;

    constructor(
        uint64[] memory _chainIds,
        address[] memory _anchorProviders,
        address[] memory _verifiers,
        bytes32[] memory _initRoots
    ) {
        require(_chainIds.length == _anchorProviders.length, "len mismatch");
        require(_chainIds.length == _verifiers.length, "len mismatch");
        require(_chainIds.length == _initRoots.length, "len mismatch");
        for (uint256 i = 0; i < _chainIds.length; i++) {
            uint64 chid = _chainIds[i];
            anchorProviders[chid] = IAnchorBlocks(_anchorProviders[i]);
            verifiers[chid] = IVerifier(_verifiers[i]);
            smtRoots[chid][0] = _initRoots[i];
        }
    }

    function getLatestRoot(uint64 chainId) public view returns (bytes32 root, uint8 bufferIndex) {
        bytes32[BUFFER_SIZE] memory roots = smtRoots[chainId];
        uint8 index = curBufferIndices[chainId];
        return (roots[index], index);
    }

    function getRoot(uint64 chainId, uint8 bufferIndex) public view returns (bytes32 root) {
        return smtRoots[chainId][bufferIndex];
    }

    function isSmtRootValid(uint64 chainId, bytes32 smtRoot) public view returns (bool) {
        bytes32[BUFFER_SIZE] memory roots = smtRoots[chainId];
        for (uint256 i = 0; i < roots.length; i++) {
            if (roots[i] == smtRoot) {
                return true;
            }
        }
        return false;
    }

    function updateRoot(uint64 chainId, SmtUpdate memory u) external {
        // If nextChunkMerkleRoot is empty, it means the zk proof bypasses checking if the updated chunk anchors to a known chunk.
        // Instead, the responsibility of checking the validity of endBlockHash is deferred to this contract.
        if (u.nextChunkMerkleRoot == 0) {
            IAnchorBlocks anchorProvider = anchorProviders[chainId];
            require(address(anchorProvider) != address(0), "unknown anchor provider");
            bytes32 anchorHash = anchorProvider.blocks(u.endBlockNum);
            require(anchorHash == u.endBlockHash, "anchor check failed");
        }
        uint8 curIndex = curBufferIndices[chainId];
        bytes32 root = smtRoots[chainId][curIndex];
        bool success = verifyProof(chainId, root, u);
        require(success, "invalid zk proof");

        curIndex = (curIndex + 1) % BUFFER_SIZE;
        smtRoots[chainId][curIndex] = u.newSmtRoot;
        curBufferIndices[chainId] = curIndex;
        emit SmtRootUpdated(u.newSmtRoot, u.endBlockNum, curIndex);
    }

    function verifyProof(uint64 chainId, bytes32 oldSmtRoot, SmtUpdate memory u) private view returns (bool) {
        IVerifier verifier = verifiers[chainId];
        require(address(verifier) != address(0), "no verifier for chainId");

        uint256[10] memory input;
        uint256 m = 1 << 128;
        input[0] = uint256(oldSmtRoot) >> 128;
        input[1] = uint256(oldSmtRoot) % m;
        input[2] = uint256(u.newSmtRoot) >> 128;
        input[3] = uint256(u.newSmtRoot) % m;
        input[4] = uint256(u.endBlockHash) >> 128;
        input[5] = uint256(u.endBlockHash) % m;
        input[6] = u.endBlockNum;
        input[7] = uint256(u.nextChunkMerkleRoot) >> 128;
        input[8] = uint256(u.nextChunkMerkleRoot) % m;
        input[9] = uint256(u.commitPub);

        return verifier.verifyProof(u.proof.a, u.proof.b, u.proof.c, u.proof.commitment, input);
    }

    function setAnchorProvider(uint64 chainId, address anchorProvider) external onlyOwner {
        anchorProviders[chainId] = IAnchorBlocks(anchorProvider);
        emit AnchorProviderUpdated(chainId, anchorProvider);
    }

    function setVerifier(uint64 chainId, address verifier) external onlyOwner {
        verifiers[chainId] = IVerifier(verifier);
        emit VerifierUpdated(chainId, verifier);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../light-client-eth/interfaces/IAnchorBlocks.sol";
import "../interfaces/ISMT.sol";
import "./SMT.sol";

contract TestSMT is SMT {
    constructor(
        uint64[] memory _chainIds,
        address[] memory _anchorProviders,
        address[] memory _verifiers,
        bytes32[] memory _initRoots
    ) SMT(_chainIds, _anchorProviders, _verifiers, _initRoots) {}

    // function for testing convenience
    function addRootForTesting(uint64 chainId, bytes32 newRoot, uint64 endBlockNum) external onlyOwner {
        uint8 curIndex = curBufferIndices[chainId];
        curIndex = (curIndex + 1) % BUFFER_SIZE;
        smtRoots[chainId][curIndex] = newRoot;
        curBufferIndices[chainId] = curIndex;
        emit SmtRootUpdated(newRoot, endBlockNum, curIndex);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IVerifier {
    struct Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[2] commitment;
    }

    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory commit,
        uint256[10] calldata input
    ) external view returns (bool r);
}