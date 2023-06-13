// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./types/IPoseidon2.sol";
import "./types/IMerkle.sol";

contract Merkle is Ownable, IMerkle {
    mapping(uint256 => uint256) public tree;
    uint256 public immutable LEVELS; // deepness of tree
    uint256 public m_index; // current index of the tree

    mapping(uint256 => uint256) roots;
    uint256 public rootIndex = 0;
    uint256 public constant MAX_ROOT_NUMBER = 25;

    IPoseidon2 immutable poseidon; // hashing

    // please see deployment scripts to understand how to create and instance of Poseidon contract
    constructor(uint256 _levels, address _poseidon) {
        LEVELS = _levels;
        m_index = 2**(LEVELS - 1);
        poseidon = IPoseidon2(_poseidon);
    }

    function hash(uint256 a, uint256 b)
        public
        view
        returns (uint256 poseidonHash)
    {
        poseidonHash = poseidon.poseidon([a, b]);
    }

    function insert(uint256 leaf) public onlyOwner returns (uint256) {
        tree[m_index] = leaf;
        m_index++;
        require(m_index != uint256(2)**LEVELS, "Tree is full.");

        uint256 fullCount = m_index - 2**(LEVELS - 1); // number of inserted leaves
        uint256 twoPower = logarithm2(fullCount); // number of tree levels to be updated, (e.g. if 9 => 4 levels should be updated)

        uint256 currentNodeIndex = m_index - 1;
        for (uint256 i = 1; i <= twoPower; i++) {
            currentNodeIndex /= 2;
            tree[currentNodeIndex] = hash(
                tree[currentNodeIndex * 2],
                tree[currentNodeIndex * 2 + 1]
            );
        }

        roots[rootIndex] = tree[currentNodeIndex]; // adding root to roots mapping
        rootIndex = (rootIndex + 1) % MAX_ROOT_NUMBER;

        return m_index - 1;
    }

    function getRootHash() public view returns (uint256) {
        for (uint256 i = 1; i < 2**LEVELS; i *= 2) {
            if (tree[i] != 0) {
                return tree[i];
            }
        }
        return 0;
    }

    function rootHashExists(uint256 _root) public view returns (bool) {
        uint256 i = rootIndex; // latest root hash
        do {
            if (i == 0) {
                i = MAX_ROOT_NUMBER;
            }
            i--;
            if (_root == roots[i]) {
                return true;
            }
        } while (i != rootIndex);
        return false;
    }

    function getSiblingIndex(uint256 index) public pure returns (uint256) {
        if (index == 1) {
            return 1;
        }
        return index % 2 == 1 ? index - 1 : index + 1;
    }

    function findAndRemove(uint256 dataToRemove, uint256 index)
        public
        onlyOwner
    {
        require(
            index >= 2**(LEVELS - 1) && index < m_index,
            "index out of range"
        );
        require(tree[index] == dataToRemove, "leaf doesn't match dataToRemove");

        tree[index] = 0;

        uint256 fullCount = m_index - 2**(LEVELS - 1); // number of inserted leaves
        uint256 twoPower = logarithm2(fullCount);

        uint256 currentNodeIndex = index;
        for (uint256 j = 1; j <= twoPower; j++) {
            currentNodeIndex /= 2;
            tree[currentNodeIndex] = hash(
                tree[currentNodeIndex * 2],
                tree[currentNodeIndex * 2 + 1]
            );
        }
        roots[rootIndex] = tree[currentNodeIndex]; // adding root to roots mapping
        rootIndex = (rootIndex + 1) % MAX_ROOT_NUMBER;
    }

    // this is logarithm of x with base 2.
    // instead of rounding down, this function rounds up, online other logarithm2 implementations
    function logarithm2(uint256 x) public pure returns (uint256 y) {
        assembly {
            let arg := x
            x := sub(x, 1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(
                m,
                0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd
            )
            mstore(
                add(m, 0x20),
                0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe
            )
            mstore(
                add(m, 0x40),
                0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616
            )
            mstore(
                add(m, 0x60),
                0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff
            )
            mstore(
                add(m, 0x80),
                0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e
            )
            mstore(
                add(m, 0xa0),
                0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707
            )
            mstore(
                add(m, 0xc0),
                0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606
            )
            mstore(
                add(m, 0xe0),
                0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100
            )
            mstore(0x40, add(m, 0x100))
            let
                magic
            := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let
                shift
            := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m, sub(255, a))), shift)
            y := add(
                y,
                mul(
                    256,
                    gt(
                        arg,
                        0x8000000000000000000000000000000000000000000000000000000000000000
                    )
                )
            )
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IMerkle {
    function hash(uint256 a, uint256 b) external view returns (uint256);

    function insert(uint256 leaf) external returns (uint256);

    function getRootHash() external view returns (uint256);

    function rootHashExists(uint256 _root) external view returns (bool);

    // every node in the merkle tree is assigned an index, this is what's being referred to here
    function getSiblingIndex(uint256 index) external pure returns (uint256);

    function findAndRemove(uint256 dataToRemove, uint256 index) external;

    function logarithm2(uint256 x) external pure returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IPoseidon2 {
    function poseidon(uint256[2] memory input) external pure returns (uint256);

    function poseidon(bytes32[2] memory input) external pure returns (bytes32);
}