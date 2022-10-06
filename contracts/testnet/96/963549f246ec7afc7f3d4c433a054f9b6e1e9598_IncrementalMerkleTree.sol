// SPDX-License-Identifier: MIT

/*
 * Semaphore - Zero-knowledge signaling on Ethereum
 * Copyright (C) 2020 Barry WhiteHat <[email protected]>, Kobi
 * Gurkan <[email protected]> and Koh Wei Jie ([email protected])
 *
 * This file is part of Semaphore.
 *
 * Semaphore is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Semaphore is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Semaphore.  If not, see <http://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.12;

import { SnarkConstants } from "./SnarkConstants.sol";
import { Hasher } from "./Hasher.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleZeros } from "./MerkleBinaryMaci.sol";

contract IncrementalMerkleTree is Ownable, Hasher, MerkleZeros {
    // The maximum tree depth
    uint8 internal constant MAX_DEPTH = 32;

    // The tree depth
    uint8 internal treeLevels;

    // The number of inserted leaves
    uint256 internal nextLeafIndex = 0;

    // The Merkle root
    uint256 public root;

    // Allows you to compute the path to the element (but it's not the path to
    // the elements). Caching these values is essential to efficient appends.
    uint256[MAX_DEPTH] internal filledSubtrees;

    // Whether the contract has already seen a particular Merkle tree root
    mapping (uint256 => bool) public rootHistory;

    event LeafInsertion(uint256 indexed leaf, uint256 indexed leafIndex);

    string constant ERROR_LEAF_TOO_LARGE = "E01";
    string constant ERROR_TREE_FULL = "E02";
    string constant ERROR_INVALID_LEVELS = "E03";
    string constant ERROR_INVALID_ZERO = "E04";

    constructor(uint8 _treeLevels, uint256 _zeroValue, bool _isPreCalc) public {
        // Limit the Merkle tree to MAX_DEPTH levels
        require(
            _treeLevels > 0 && _treeLevels <= MAX_DEPTH,
            ERROR_INVALID_LEVELS
        );
        
        if (_isPreCalc) {
            // Use pre-calculated zero values (see MerkleZeros.sol.template)
            populateZeros();
            require(_zeroValue == zeros[0], ERROR_INVALID_ZERO);
            treeLevels = _treeLevels;

            root = zeros[_treeLevels];
        } else {
            /*
               To initialise the Merkle tree, we need to calculate the Merkle root
               assuming that each leaf is the zero value.

                H(H(a,b), H(c,d))
                 /             \
                H(a,b)        H(c,d)
                 /   \        /    \
                a     b      c      d

               `zeros` and `filledSubtrees` will come in handy later when we do
               inserts or updates. e.g when we insert a value in index 1, we will
               need to look up values from those arrays to recalculate the Merkle
               root.
             */
            treeLevels = _treeLevels;

            zeros[0] = _zeroValue;

            uint256 currentZero = _zeroValue;
            for (uint8 i = 1; i < _treeLevels; i++) {
                uint256 hashed = hashLeftRight(currentZero, currentZero);
                zeros[i] = hashed;
                currentZero = hashed;
            }

            root = hashLeftRight(currentZero, currentZero);
        }
    }

    /*
     * Inserts a leaf into the Merkle tree and updates the root and filled
     * subtrees.
     * @param _leaf The value to insert. It must be less than the snark scalar
     *              field or this function will throw.
     * @return The leaf index.
     */
    function insertLeaf(uint256 _leaf) public onlyOwner returns (uint256) {
        require(_leaf < SNARK_SCALAR_FIELD, ERROR_LEAF_TOO_LARGE);

        uint256 currentIndex = nextLeafIndex;

        uint256 depth = uint256(treeLevels);
        require(currentIndex < uint256(2) ** depth, ERROR_TREE_FULL);

        uint256 currentLevelHash = _leaf;
        uint256 left;
        uint256 right;

        for (uint8 i = 0; i < treeLevels; i++) {
            // if current_index is 5, for instance, over the iterations it will
            // look like this: 5, 2, 1, 0, 0, 0 ...

            if (currentIndex % 2 == 0) {
                // For later values of `i`, use the previous hash as `left`, and
                // the (hashed) zero value for `right`
                left = currentLevelHash;
                right = zeros[i];

                filledSubtrees[i] = currentLevelHash;
            } else {
                left = filledSubtrees[i];
                right = currentLevelHash;
            }

            currentLevelHash = hashLeftRight(left, right);

            // equivalent to currentIndex /= 2;
            currentIndex >>= 1;
        }

        root = currentLevelHash;
        rootHistory[root] = true;

        uint256 n = nextLeafIndex;
        nextLeafIndex += 1;

        emit LeafInsertion(_leaf, n);

        return currentIndex;
    }
}

// SPDX-License-Identifier: MIT

/*
 * Semaphore - Zero-knowledge signaling on Ethereum
 * Copyright (C) 2020 Barry WhiteHat <[email protected]>, Kobi
 * Gurkan <[email protected]> and Koh Wei Jie ([email protected])
 *
 * This file is part of Semaphore.
 *
 * Semaphore is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Semaphore is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Semaphore.  If not, see <http://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.12;

contract SnarkConstants {
    // The scalar field
    uint256 internal constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import {PoseidonT3, PoseidonT6} from "./Poseidon.sol";

import {SnarkConstants} from "./SnarkConstants.sol";

/*
 * Poseidon hash functions for 2, 5, and 11 input elements.
 */
contract Hasher is SnarkConstants {
    function hash5(uint256[5] memory array) public pure returns (uint256) {
        return PoseidonT6.poseidon(array);
    }

    function hash11(uint256[] memory array) public pure returns (uint256) {
        uint256[] memory input11 = new uint256[](11);
        uint256[5] memory first5;
        uint256[5] memory second5;
        for (uint256 i = 0; i < array.length; i++) {
            input11[i] = array[i];
        }

        for (uint256 i = array.length; i < 11; i++) {
            input11[i] = 0;
        }

        for (uint256 i = 0; i < 5; i++) {
            first5[i] = input11[i];
            second5[i] = input11[i + 5];
        }

        uint256[2] memory first2;
        first2[0] = PoseidonT6.poseidon(first5);
        first2[1] = PoseidonT6.poseidon(second5);
        uint256[2] memory second2;
        second2[0] = PoseidonT3.poseidon(first2);
        second2[1] = input11[10];
        return PoseidonT3.poseidon(second2);
    }

    function hashLeftRight(uint256 _left, uint256 _right)
        public
        pure
        returns (uint256)
    {
        uint256[2] memory input;
        input[0] = _left;
        input[1] = _right;
        return PoseidonT3.poseidon(input);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract MerkleZeros {
    uint256[33] internal zeros;

    // Binary tree zeros (Keccack hash of 'Maci')
    function populateZeros() internal {
        zeros[0] = uint256(8370432830353022751713833565135785980866757267633941821328460903436894336785);
        zeros[1] = uint256(13883108378505681706501741077199723943829197421795883447299356576923144768890);
        zeros[2] = uint256(15419121528227002346615807695865368688447806543310218580451656713665933966440);
        zeros[3] = uint256(6318262337906428951291657677634338300639543013249211096760913778778957055324);
        zeros[4] = uint256(17768974272065709481357540291486641669761745417382244600494648537227290564775);
        zeros[5] = uint256(1030673773521289386438564854581137730704523062376261329171486101180288653537);
        zeros[6] = uint256(2456832313683926177308273721786391957119973242153180895324076357329047000368);
        zeros[7] = uint256(8719489529991410281576768848178751308798998844697260960510058606396118487868);
        zeros[8] = uint256(1562826620410077272445821684229580081819470607145780146992088471567204924361);
        zeros[9] = uint256(2594027261737512958249111386518678417918764295906952540494120924791242533396);
        zeros[10] = uint256(7454652670930646290900416353463196053308124896106736687630886047764171239135);
        zeros[11] = uint256(5636576387316613237724264020484439958003062686927585603917058282562092206685);
        zeros[12] = uint256(6668187911340361678685285736007075111202281125695563765600491898900267193410);
        zeros[13] = uint256(11734657993452490720698582048616543923742816272311967755126326688155661525563);
        zeros[14] = uint256(13463263143201754346725031241082259239721783038365287587742190796879610964010);
        zeros[15] = uint256(7428603293293611296009716236093531014060986236553797730743998024965500409844);
        zeros[16] = uint256(3220236805148173410173179641641444848417275827082321553459407052920864882112);
        zeros[17] = uint256(5702296734156546101402281555025360809782656712426280862196339683480526959100);
        zeros[18] = uint256(18054517726590450486276822815339944904333304893252063892146748222745553261079);
        zeros[19] = uint256(15845875411090302918698896692858436856780638250734551924718281082237259235021);
        zeros[20] = uint256(15856603049544947491266127020967880429380981635456797667765381929897773527801);
        zeros[21] = uint256(16947753390809968528626765677597268982507786090032633631001054889144749318212);
        zeros[22] = uint256(4409871880435963944009375001829093050579733540305802511310772748245088379588);
        zeros[23] = uint256(3999924973235726549616800282209401324088787314476870617570702819461808743202);
        zeros[24] = uint256(5910085476731597359542102744346894725393370185329725031545263392891885548800);
        zeros[25] = uint256(8329789525184689042321668445575725185257025982565085347238469712583602374435);
        zeros[26] = uint256(21731745958669991600655184668442493750937309130671773804712887133863507145115);
        zeros[27] = uint256(13908786229946466860099145463206281117295829828306413881947857340025780878375);
        zeros[28] = uint256(2746378384965515118858350021060497341885459652705230422460541446030288889144);
        zeros[29] = uint256(4024247518003740702537513711866227003187955635058512298109553363285388770811);
        zeros[30] = uint256(13465368596069181921705381841358161201578991047593533252870698635661853557810);
        zeros[31] = uint256(1901585547727445451328488557530824986692473576054582208711800336656801352314);
        zeros[32] = uint256(3444131905730490180878137209421656122704458854785641062326389124060978485990);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library PoseidonT3 {
    function poseidon(uint256[2] memory input) public pure returns (uint256) {}
}


library PoseidonT6 {
    function poseidon(uint256[5] memory input) public pure returns (uint256) {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}