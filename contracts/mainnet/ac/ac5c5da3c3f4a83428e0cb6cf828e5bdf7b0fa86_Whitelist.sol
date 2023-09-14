// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Owned} from "solmate/auth/Owned.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";

contract Whitelist is Owned {
    mapping(address => bool) public isWhitelisted;

    bytes32 public merkleRoot;

    event Whitelisted(address indexed account, bool whitelisted);

    error InvalidProof();
    error MisMatchArrayLength();

    constructor() Owned(msg.sender) {}

    function verify(bytes32[] calldata proof, address user) public view returns (bool) {
        return MerkleProofLib.verify(proof, merkleRoot, keccak256(abi.encodePacked(user)));
    }

    function whitelistAddress(bytes32[] calldata proof, address user) external {
        if (!verify(proof, user)) revert InvalidProof();
        isWhitelisted[user] = true;
        emit Whitelisted(user, true);
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setDirectWhitelist(address account, bool whitelisted) external onlyOwner {
        isWhitelisted[account] = whitelisted;
        emit Whitelisted(account, whitelisted);
    }

    function setDirectWhitelists(address[] calldata accounts, bool[] calldata whitelisted) external onlyOwner {
        if (accounts.length != whitelisted.length) revert MisMatchArrayLength();
        for (uint256 i = 0; i < accounts.length; i++) {
            isWhitelisted[accounts[i]] = whitelisted[i];
            emit Whitelisted(accounts[i], whitelisted[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Gas optimized merkle proof verification library.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/MerkleProofLib.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        assembly {
            let computedHash := leaf // The hash starts as the leaf hash.

            // Initialize data to the offset of the proof in the calldata.
            let data := proof.offset

            // Iterate over proof elements to compute root hash.
            for {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(data, shl(5, proof.length))
            } lt(data, end) {
                data := add(data, 32) // Shift 1 word per cycle.
            } {
                // Load the current proof element.
                let loadedData := calldataload(data)

                // Slot where computedHash should be put in scratch space.
                // If computedHash > loadedData: slot 32, otherwise: slot 0.
                let computedHashSlot := shl(5, gt(computedHash, loadedData))

                // Store elements to hash contiguously in scratch space.
                // The xor puts loadedData in whichever slot computedHash is
                // not occupying, so 0 if computedHashSlot is 32, 32 otherwise.
                mstore(computedHashSlot, computedHash)
                mstore(xor(computedHashSlot, 32), loadedData)

                computedHash := keccak256(0, 64) // Hash both slots of scratch space.
            }

            isValid := eq(computedHash, root) // The proof is valid if the roots match.
        }
    }
}