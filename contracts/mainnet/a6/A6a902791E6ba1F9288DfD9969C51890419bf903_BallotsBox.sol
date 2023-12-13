// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.8;

library BallotsBox {

    enum AttitudeOfVote {
        All,
        Support,
        Against,
        Abstain
    }

    struct Ballot {
        uint40 acct;
        uint8 attitude;
        uint32 head;
        uint64 weight;
        uint48 sigDate;
        uint64 blocknumber;
        bytes32 sigHash;
        uint[] principals;
    }

    struct Case {
        uint32 sumOfHead;
        uint64 sumOfWeight;
        uint256[] voters;
        uint256[] principals;
    }

    struct Box {
        mapping(uint256 => Case) cases;
        mapping(uint256 => Ballot) ballots;
    }

    // #################
    // ##    Write    ##
    // #################

    function castVote(
        Box storage box,
        uint acct,
        uint attitude,
        uint head,
        uint weight,
        bytes32 sigHash,
        uint[] memory principals
    ) public returns (bool flag) {

        require(
            attitude == uint8(AttitudeOfVote.Support) ||
                attitude == uint8(AttitudeOfVote.Against) ||
                attitude == uint8(AttitudeOfVote.Abstain),
            "BB.CV: attitude overflow"
        );

        Ballot storage b = box.ballots[acct];

        if (b.sigDate == 0) {
            box.ballots[acct] = Ballot({
                acct: uint40(acct),
                attitude: uint8(attitude),
                head: uint32(head),
                weight: uint64(weight),
                sigDate: uint48(block.timestamp),
                blocknumber: uint64(block.number),
                sigHash: sigHash,
                principals: principals
            });

            _pushToCase(box.cases[attitude], b);
            _pushToCase(box.cases[uint8(AttitudeOfVote.All)], b);

            flag = true;
        }
    }

    function _pushToCase(Case storage c, Ballot memory b) private {
            c.sumOfHead += b.head;
            c.sumOfWeight += b.weight;
            c.voters.push(b.acct);
            
            uint len = b.principals.length;
            while (len > 0) {
                c.principals.push(b.principals[len - 1]);
                len--;
            }
    }


    // #################
    // ##    Read     ##
    // #################

    function isVoted(Box storage box, uint256 acct) 
        public view returns (bool) 
    {
        return box.ballots[acct].sigDate > 0;
    }

    function isVotedFor(
        Box storage box,
        uint256 acct,
        uint256 atti
    ) public view returns (bool) {
        return box.ballots[acct].attitude == atti;
    }

    function getCaseOfAttitude(Box storage box, uint256 atti)
        public view returns (Case memory )
    {
        return box.cases[atti];
    }

    function getBallot(Box storage box, uint256 acct)
        public view returns (Ballot memory)
    {
        return box.ballots[acct];
    }

}