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

library RulesParser {

    // ======== GovernanceRule ========

    // bytes32 public constant SHA_INIT_GR = 
    //     bytes32(uint(0x0000000000000000010000000000000000000000000000000000000000000000));

    struct GovernanceRule {
        uint32 fundApprovalThreshold; 
        bool basedOnPar;
        uint16 proposeWeightRatioOfGM; 
        uint16 proposeHeadRatioOfMembers; 
        uint16 proposeHeadRatioOfDirectorsInGM;
        uint16 proposeHeadRatioOfDirectorsInBoard;
        uint16 maxQtyOfMembers;
        uint16 quorumOfGM;  
        uint8 maxNumOfDirectors;
        uint16 tenureMonOfBoard;
        uint16 quorumOfBoardMeeting;
        uint48 establishedDate;    
        uint8 businessTermInYears;
        uint8 typeOfComp;
        uint16 minVoteRatioOnChain;
    }

    function governanceRuleParser(bytes32 sn) public pure returns (GovernanceRule memory rule) {
        uint _sn = uint(sn);

        rule = GovernanceRule({
            fundApprovalThreshold: uint32(_sn >> 224),
            basedOnPar: uint8(_sn >> 216) == 1,
            proposeWeightRatioOfGM: uint16(_sn >> 200),
            proposeHeadRatioOfMembers: uint16(_sn >> 184),
            proposeHeadRatioOfDirectorsInGM: uint16(_sn >> 168),
            proposeHeadRatioOfDirectorsInBoard: uint16(_sn >> 152),
            maxQtyOfMembers: uint16(_sn >> 136),
            quorumOfGM: uint16(_sn >> 120),
            maxNumOfDirectors: uint8(_sn >> 112),
            tenureMonOfBoard: uint16(_sn >> 96),
            quorumOfBoardMeeting: uint16(_sn >> 80),
            establishedDate: uint48(_sn >> 32),
            businessTermInYears: uint8(_sn >> 24),
            typeOfComp: uint8(_sn >> 16),
            minVoteRatioOnChain: uint16(_sn)
        });
    }

    // ---- VotingRule ----

    // bytes32 public constant SHA_INIT_VR = 
    //     bytes32(uint(0x00080c080100001a0b0000010000000000000100000000000000000000000000));

    struct VotingRule{
        uint16 seqOfRule;
        uint8 qtyOfSubRule;
        uint8 seqOfSubRule;
        uint8 authority;
        uint16 headRatio;
        uint16 amountRatio;
        bool onlyAttendance;
        bool impliedConsent;
        bool partyAsConsent;
        bool againstShallBuy;
        uint8 frExecDays;
        uint8 dtExecDays;
        uint8 dtConfirmDays;
        uint8 invExitDays;
        uint8 votePrepareDays;
        uint8 votingDays;
        uint8 execDaysForPutOpt;
        uint40[2] vetoers;
        uint16 para;
    }

    function votingRuleParser(bytes32 sn) public pure returns (VotingRule memory rule) {
        uint _sn = uint(sn);

        rule = VotingRule({
            seqOfRule: uint16(_sn >> 240),
            qtyOfSubRule: uint8(_sn >> 232),
            seqOfSubRule: uint8(_sn >> 224),
            authority: uint8(_sn >> 216),
            headRatio: uint16(_sn >> 200),
            amountRatio: uint16(_sn >> 184),
            onlyAttendance: uint8(_sn >> 176) == 1,
            impliedConsent: uint8(_sn >> 168) == 1,
            partyAsConsent: uint8(_sn >> 160) == 1,
            againstShallBuy: uint8(_sn >> 152) == 1,
            frExecDays: uint8(_sn >> 144),
            dtExecDays: uint8(_sn >> 136),
            dtConfirmDays: uint8(_sn >> 128),
            invExitDays: uint8(_sn >> 120),
            votePrepareDays: uint8(_sn >> 112),
            votingDays: uint8(_sn >> 104),
            execDaysForPutOpt: uint8(_sn >> 96),
            vetoers: [uint40(_sn >> 56), uint40(_sn >> 16)],
            para: uint16(_sn)            
        });
    }

    // ---- BoardSeatsRule ----

/*
    1: Chairman;
    2: ViceChairman;
    3: Director;
    ...
*/

    struct PositionAllocateRule {
        uint16 seqOfRule;
        uint8 qtyOfSubRule;
        uint8 seqOfSubRule; 
        bool removePos; 
        uint16 seqOfPos;
        uint16 titleOfPos;  
        uint40 nominator;   
        uint16 titleOfNominator;    
        uint16 seqOfVR; 
        uint48 endDate;
        uint16 para;    
        uint16 argu;
        uint32 data;
    }

    function positionAllocateRuleParser(bytes32 sn) public pure returns(PositionAllocateRule memory rule) {
        uint _sn = uint(sn);

        rule = PositionAllocateRule({
            seqOfRule: uint16(_sn >> 240), 
            qtyOfSubRule: uint8(_sn >> 232),
            seqOfSubRule: uint8(_sn >> 224), 
            removePos: uint8(_sn >> 216) == 1,
            seqOfPos: uint16(_sn >> 200),
            titleOfPos: uint16(_sn >> 184),  
            nominator: uint40(_sn >> 144),   
            titleOfNominator: uint16(_sn >> 128),    
            seqOfVR: uint16(_sn >> 112), 
            endDate: uint48(_sn >> 64),
            para: uint16(_sn >> 48),    
            argu: uint16(_sn >> 32),
            data: uint32(_sn)
        });

    }

    // ---- FirstRefusal Rule ----

    struct FirstRefusalRule {
        uint16 seqOfRule;
        uint8 qtyOfSubRule;
        uint8 seqOfSubRule;
        uint8 typeOfDeal;
        bool membersEqual;
        bool proRata;
        bool basedOnPar;
        uint40[4] rightholders;
        uint16 para;
        uint16 argu;        
    }

    function firstRefusalRuleParser(bytes32 sn) public pure returns(FirstRefusalRule memory rule) {
        uint _sn = uint(sn);

        rule = FirstRefusalRule({
            seqOfRule: uint16(_sn >> 240),
            qtyOfSubRule: uint8(_sn >> 232),
            seqOfSubRule: uint8(_sn >> 224),
            typeOfDeal: uint8(_sn >> 216),
            membersEqual: uint8(_sn >> 208) == 1,
            proRata: uint8(_sn >> 200) == 1,
            basedOnPar: uint8(_sn >> 192) == 1,
            rightholders: [uint40(_sn >> 152), uint40(_sn >> 112), uint40(_sn >> 72), uint40(_sn >> 32)],
            para: uint16(_sn >> 16),
            argu: uint16(_sn)                    
        });
    }

    // ---- GroupUpdateOrder ----

    struct GroupUpdateOrder {
        uint16 seqOfRule;
        uint8 qtyOfSubRule;
        uint8 seqOfSubRule;
        bool addMember;
        uint40 groupRep;
        uint40[4] members;
        uint16 para;        
    }

    function groupUpdateOrderParser(bytes32 sn) public pure returns(GroupUpdateOrder memory order) {
        uint _sn = uint(sn);
        
        order = GroupUpdateOrder({
            seqOfRule: uint16(_sn >> 240),
            qtyOfSubRule: uint8(_sn >> 232),
            seqOfSubRule: uint8(_sn >> 224),
            addMember: uint8(_sn >> 216) == 1,
            groupRep: uint40(_sn >> 176),
            members: [
                uint40(_sn >> 136),
                uint40(_sn >> 96),
                uint40(_sn >> 56),
                uint40(_sn >> 16)
            ],
            para: uint16(_sn)
        });
    }    

    // ---- ListingRule ----

    struct ListingRule {
        uint16 seqOfRule;
        uint16 titleOfIssuer;
        uint16 classOfShare;
        uint64 maxTotalPar;
        uint16 titleOfVerifier;
        uint16 maxQtyOfInvestors;
        uint32 ceilingPrice;
        uint32 floorPrice;
        uint16 lockupDays;
        uint16 offPrice;
        uint16 votingWeight;
    }

    function listingRuleParser(bytes32 sn) public pure returns(ListingRule memory rule) {
        uint _sn = uint(sn);
        
        rule = ListingRule({
            seqOfRule: uint16(_sn >> 240),
            titleOfIssuer: uint16(_sn >> 224),
            classOfShare: uint16(_sn >> 208),
            maxTotalPar: uint64(_sn >> 144),
            titleOfVerifier: uint16(_sn >> 128), 
            maxQtyOfInvestors: uint16(_sn >> 112),
            ceilingPrice: uint32(_sn >> 80),
            floorPrice: uint32(_sn >> 48),
            lockupDays: uint16(_sn >> 32),
            offPrice: uint16(_sn >> 16),
            votingWeight: uint16(_sn)
        });
    }    

    // ======== LinkRule ========

    struct LinkRule {
        uint48 triggerDate;
        uint16 effectiveDays;
        uint8 triggerType;  
        uint16 shareRatioThreshold;
        uint32 rate;
        bool proRata;
        uint16 seq;
        uint16 para;
        uint16 argu;
        uint16 ref;
        uint64 data;
    }

    function linkRuleParser(bytes32 sn) public pure returns (LinkRule memory rule) {
        uint _sn = uint(sn);

        rule = LinkRule({
            triggerDate: uint48(_sn >> 208),
            effectiveDays: uint16(_sn >> 192),
            triggerType: uint8(_sn >> 184),  
            shareRatioThreshold: uint16(_sn >> 168),
            rate: uint32(_sn >> 136),
            proRata: uint8(_sn >> 128) == 1,
            seq: uint16(_sn >> 112),
            para: uint16(_sn >> 96),
            argu: uint16(_sn >> 80),
            ref: uint16(_sn >> 64),
            data: uint64(_sn)
        });
    }

}