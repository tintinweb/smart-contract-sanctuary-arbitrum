// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

pragma solidity ^0.8.10;

library Pairing {

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 x;
        uint256 y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] x;
        uint256[2] y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero. 
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {

        // The prime q in the base field F_q for G1
        if (p.x == 0 && p.y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.x, PRIME_Q - (p.y % PRIME_Q));
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
        input[0] = p1.x;
        input[1] = p1.y;
        input[2] = p2.x;
        input[3] = p2.y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"pairing-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {

        uint256[3] memory input;
        input[0] = p.x;
        input[1] = p.y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }

    /* @return The result of computing the pairing check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
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
            input[j + 0] = p1[i].x;
            input[j + 1] = p1[i].y;
            input[j + 2] = p2[i].x[0];
            input[j + 3] = p2[i].x[1];
            input[j + 4] = p2[i].y[0];
            input[j + 5] = p2[i].y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success, "pairing-opcode-failed");

        return out[0] != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import { Pairing } from "./Pairing.sol";

contract SnarkCommon {
    struct VerifyingKey {
        Pairing.G1Point alpha1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] ic;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { SnarkCommon } from "./crypto/SnarkCommon.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * Stores verifying keys for the circuits.
 * Each circuit has a signature which is its compile-time constants represented
 * as a uint256.
 */
contract VkRegistry is Ownable, SnarkCommon {

    mapping (uint256 => VerifyingKey) internal processVks; 
    mapping (uint256 => bool) internal processVkSet; 

    mapping (uint256 => VerifyingKey) internal tallyVks; 
    mapping (uint256 => bool) internal tallyVkSet; 

    mapping (uint256 => VerifyingKey) internal subsidyVks; 
    mapping (uint256 => bool) internal subsidyVkSet; 

    event ProcessVkSet(uint256 _sig);
    event TallyVkSet(uint256 _sig);
    event SubsidyVkSet(uint256 _sig);

    function isProcessVkSet(uint256 _sig) public view returns (bool) {
        return processVkSet[_sig];
    }

    function isTallyVkSet(uint256 _sig) public view returns (bool) {
        return tallyVkSet[_sig];
    }

    function isSubsidyVkSet(uint256 _sig) public view returns (bool) {
        return subsidyVkSet[_sig];
    }

    function genProcessVkSig(
        uint256 _stateTreeDepth,
        uint256 _messageTreeDepth,
        uint256 _voteOptionTreeDepth,
        uint256 _messageBatchSize
    ) public pure returns (uint256) {
        return 
            (_messageBatchSize << 192) +
            (_stateTreeDepth << 128) +
            (_messageTreeDepth << 64) +
            _voteOptionTreeDepth;
    }

    function genTallyVkSig(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _voteOptionTreeDepth
    ) public pure returns (uint256) {
        return 
            (_stateTreeDepth << 128) +
            (_intStateTreeDepth << 64) +
            _voteOptionTreeDepth;
    }

    function genSubsidyVkSig(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _voteOptionTreeDepth
    ) public pure returns (uint256) {
        return 
            (_stateTreeDepth << 128) +
            (_intStateTreeDepth << 64) +
            _voteOptionTreeDepth;
    }

    function setVerifyingKeys(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _messageTreeDepth,
        uint256 _voteOptionTreeDepth,
        uint256 _messageBatchSize,
        VerifyingKey memory _processVk,
        VerifyingKey memory _tallyVk
    ) public onlyOwner {

        uint256 processVkSig = genProcessVkSig(
            _stateTreeDepth,
            _messageTreeDepth,
            _voteOptionTreeDepth,
            _messageBatchSize
        );

        require(!processVkSet[processVkSig], "VkRegistry: process vk already set");

        uint256 tallyVkSig = genTallyVkSig(
            _stateTreeDepth,
            _intStateTreeDepth,
            _voteOptionTreeDepth
        );

        require(!tallyVkSet[tallyVkSig], "VkRegistry: tally vk already set");

        VerifyingKey storage processVk = processVks[processVkSig];
        processVk.alpha1 = _processVk.alpha1;
        processVk.beta2 = _processVk.beta2;
        processVk.gamma2 = _processVk.gamma2;
        processVk.delta2 = _processVk.delta2;
        for (uint8 i = 0; i < _processVk.ic.length; i ++) {
            processVk.ic.push(_processVk.ic[i]);
        }

        processVkSet[processVkSig] = true;

        VerifyingKey storage tallyVk = tallyVks[tallyVkSig];
        tallyVk.alpha1 = _tallyVk.alpha1;
        tallyVk.beta2 = _tallyVk.beta2;
        tallyVk.gamma2 = _tallyVk.gamma2;
        tallyVk.delta2 = _tallyVk.delta2;
        for (uint8 i = 0; i < _tallyVk.ic.length; i ++) {
            tallyVk.ic.push(_tallyVk.ic[i]);
        }
        tallyVkSet[tallyVkSig] = true;

        emit TallyVkSet(tallyVkSig);
        emit ProcessVkSet(processVkSig);
    }

    function setSubsidyKeys(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _voteOptionTreeDepth,
        VerifyingKey memory _subsidyVk
    ) public onlyOwner {

        uint256 subsidyVkSig = genSubsidyVkSig(
            _stateTreeDepth,
            _intStateTreeDepth,
            _voteOptionTreeDepth
        );

        require(!subsidyVkSet[subsidyVkSig], "VkRegistry: subsidy vk already set");

        VerifyingKey storage subsidyVk = subsidyVks[subsidyVkSig];
        subsidyVk.alpha1 = _subsidyVk.alpha1;
        subsidyVk.beta2 = _subsidyVk.beta2;
        subsidyVk.gamma2 = _subsidyVk.gamma2;
        subsidyVk.delta2 = _subsidyVk.delta2;
        for (uint8 i = 0; i < _subsidyVk.ic.length; i ++) {
            subsidyVk.ic.push(_subsidyVk.ic[i]);
        }
        subsidyVkSet[subsidyVkSig] = true;

        emit SubsidyVkSet(subsidyVkSig);
    }

    function hasProcessVk(
        uint256 _stateTreeDepth,
        uint256 _messageTreeDepth,
        uint256 _voteOptionTreeDepth,
        uint256 _messageBatchSize
    ) public view returns (bool) {
        uint256 sig = genProcessVkSig(
            _stateTreeDepth,
            _messageTreeDepth,
            _voteOptionTreeDepth,
            _messageBatchSize
        );
        return processVkSet[sig];
    }

    function getProcessVkBySig(
        uint256 _sig
    ) public view returns (VerifyingKey memory) {
        require(processVkSet[_sig], "VkRegistry: process verifying key not set");

        return processVks[_sig];
    }

    function getProcessVk(
        uint256 _stateTreeDepth,
        uint256 _messageTreeDepth,
        uint256 _voteOptionTreeDepth,
        uint256 _messageBatchSize
    ) public view returns (VerifyingKey memory) {
        uint256 sig = genProcessVkSig(
            _stateTreeDepth,
            _messageTreeDepth,
            _voteOptionTreeDepth,
            _messageBatchSize
        );

        return getProcessVkBySig(sig);
    }

    function hasTallyVk(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _voteOptionTreeDepth
    ) public view returns (bool) {
        uint256 sig = genTallyVkSig(
            _stateTreeDepth,
            _intStateTreeDepth,
            _voteOptionTreeDepth
        );

        return tallyVkSet[sig];
    }

    function getTallyVkBySig(
        uint256 _sig
    ) public view returns (VerifyingKey memory) {
        require(tallyVkSet[_sig], "VkRegistry: tally verifying key not set");

        return tallyVks[_sig];
    }

    function getTallyVk(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _voteOptionTreeDepth
    ) public view returns (VerifyingKey memory) {
        uint256 sig = genTallyVkSig(
            _stateTreeDepth,
            _intStateTreeDepth,
            _voteOptionTreeDepth
        );

        return getTallyVkBySig(sig);
    }

    function hasSubsidyVk(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _voteOptionTreeDepth
    ) public view returns (bool) {
        uint256 sig = genSubsidyVkSig(
            _stateTreeDepth,
            _intStateTreeDepth,
            _voteOptionTreeDepth
        );

        return subsidyVkSet[sig];
    }

    function getSubsidyVkBySig(
        uint256 _sig
    ) public view returns (VerifyingKey memory) {
        require(subsidyVkSet[_sig], "VkRegistry: subsidy verifying key not set");

        return subsidyVks[_sig];
    }

    function getSubsidyVk(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _voteOptionTreeDepth
    ) public view returns (VerifyingKey memory) {
        uint256 sig = genSubsidyVkSig(
            _stateTreeDepth,
            _intStateTreeDepth,
            _voteOptionTreeDepth
        );

        return getSubsidyVkBySig(sig);
    }
}