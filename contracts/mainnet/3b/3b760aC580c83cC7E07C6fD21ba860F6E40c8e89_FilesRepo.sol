// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.8;

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
            }

            delete set._values[lastIndex];
            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    //======== Bytes32Set ========

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value)
        public
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value)
        public
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value)
        public
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) public view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index)
        public
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function values(Bytes32Set storage set)
        public
        view
        returns (bytes32[] memory)
    {
        return _values(set._inner);
    }

    //======== AddressSet ========

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        public
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
        public
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
        public
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) public view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        public
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set)
        public
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    //======== UintSet ========

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) public returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value)
        public
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        public
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) public view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index)
        public
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function values(UintSet storage set)
        public
        view
        returns (uint256[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
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

import "./EnumerableSet.sol";
import "./RulesParser.sol";

library FilesRepo {
    using EnumerableSet for EnumerableSet.AddressSet;

    enum StateOfFile {
        ZeroPoint,  // 0
        Created,    // 1
        Circulated, // 2
        Proposed,   // 3
        Approved,   // 4
        Rejected,   // 5
        Closed,     // 6
        Revoked     // 7
    }

    struct Head {
        uint48 circulateDate;
        uint8 signingDays;
        uint8 closingDays;
        uint16 seqOfVR;
        uint8 frExecDays;
        uint8 dtExecDays;
        uint8 dtConfirmDays;
        uint48 proposeDate;
        uint8 invExitDays;
        uint8 votePrepareDays;
        uint8 votingDays;
        uint8 execDaysForPutOpt;
        uint64 seqOfMotion;
        uint8 state;
    }

    struct Ref {
        bytes32 docUrl;
        bytes32 docHash;
    }

    struct File {
        bytes32 snOfDoc;
        Head head;
        Ref ref;
    }

    struct Repo {
        mapping(address => File) files;
        EnumerableSet.AddressSet filesList;
    }

    //####################
    //##    modifier    ##
    //####################

    modifier onlyRegistered(Repo storage repo, address body) {
        require(repo.filesList.contains(body),
            "FR.md.OR: doc NOT registered");
        _;
    }

    //##################
    //##  Write I/O   ##
    //##################

    function regFile(Repo storage repo, bytes32 snOfDoc, address body) 
        public returns (bool flag)
    {
        if (repo.filesList.add(body)) {

            File storage file = repo.files[body];
            
            file.snOfDoc = snOfDoc;
            file.head.state = uint8(StateOfFile.Created);
            flag = true;
        }
    }

    function circulateFile(
        Repo storage repo,
        address body,
        uint16 signingDays,
        uint16 closingDays,
        RulesParser.VotingRule memory vr,
        bytes32 docUrl,
        bytes32 docHash
    ) public onlyRegistered(repo, body) returns (Head memory head){

        require(
            repo.files[body].head.state == uint8(StateOfFile.Created),
            "FR.CF: Doc not pending"
        );

        head = Head({
            circulateDate: uint48(block.timestamp),
            signingDays: uint8(signingDays),
            closingDays: uint8(closingDays),
            seqOfVR: vr.seqOfRule,
            frExecDays: vr.frExecDays,
            dtExecDays: vr.dtExecDays,
            dtConfirmDays: vr.dtConfirmDays,
            proposeDate: 0,
            invExitDays: vr.invExitDays,
            votePrepareDays: vr.votePrepareDays,
            votingDays: vr.votingDays,
            execDaysForPutOpt: vr.execDaysForPutOpt,
            seqOfMotion: 0,
            state: uint8(StateOfFile.Circulated)
        });

        require(head.signingDays > 0, "FR.CF: zero signingDays");

        require(head.closingDays >= signingDays + vr.frExecDays + vr.dtExecDays + vr.dtConfirmDays + 
                vr.invExitDays + vr.votePrepareDays + vr.votingDays,
            "FR.CF: insufficient closingDays");

        File storage file = repo.files[body];

        file.head = head;

        if (docUrl != bytes32(0) || docHash != bytes32(0)){
            file.ref = Ref({
                docUrl: docUrl,
                docHash: docHash
            });   
        }
        return file.head;
    }

    function proposeFile(
        Repo storage repo,
        address body,
        uint64 seqOfMotion
    ) public onlyRegistered(repo, body) returns(Head memory){

        require(repo.files[body].head.state == uint8(StateOfFile.Circulated),
            "FR.PF: Doc not circulated");

        uint48 timestamp = uint48(block.timestamp);

        require(timestamp >= dtExecDeadline(repo, body), 
            "FR.proposeFile: still in dtExecPeriod");

        File storage file = repo.files[body];

        require(timestamp < terminateStartpoint(repo, body) || (file.head.frExecDays
             + file.head.dtExecDays + file.head.dtConfirmDays) == 0, 
            "FR.proposeFile: missed proposeDeadline");

        file.head.proposeDate = timestamp;
        file.head.seqOfMotion = seqOfMotion;
        file.head.state = uint8(StateOfFile.Proposed);

        return file.head;
    }

    function voteCountingForFile(
        Repo storage repo,
        address body,
        bool approved
    ) public onlyRegistered(repo, body) {

        require(repo.files[body].head.state == uint8(StateOfFile.Proposed),
            "FR.VCFF: Doc not proposed");

        uint48 timestamp = uint48(block.timestamp);

        require(timestamp >= votingDeadline(repo, body), 
            "FR.voteCounting: still in votingPeriod");

        File storage file = repo.files[body];

        file.head.state = approved ? 
            uint8(StateOfFile.Approved) : uint8(StateOfFile.Rejected);
    }

    function execFile(
        Repo storage repo,
        address body
    ) public onlyRegistered(repo, body) {

        File storage file = repo.files[body];

        require(file.head.state == uint8(StateOfFile.Approved),
            "FR.EF: Doc not approved");

        uint48 timestamp = uint48(block.timestamp);

        require(timestamp < closingDeadline(repo, body), 
            "FR.EF: missed closingDeadline");

        file.head.state = uint8(StateOfFile.Closed);
    }

    function terminateFile(
        Repo storage repo,
        address body
    ) public onlyRegistered(repo, body) {

        File storage file = repo.files[body];

        require(file.head.state != uint8(StateOfFile.Closed),
            "FR.terminateFile: Doc is closed");

        file.head.state = uint8(StateOfFile.Revoked);
    }

    function setStateOfFile(Repo storage repo, address body, uint state) 
        public onlyRegistered(repo, body)
    {
        repo.files[body].head.state = uint8(state);
    }

    //##################
    //##   read I/O   ##
    //##################

    function signingDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + uint48(file.head.signingDays) * 86400;
    }

    function closingDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + uint48(file.head.closingDays) * 86400;
    }

    function frExecDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + uint48(file.head.signingDays + 
            file.head.frExecDays) * 86400;
    }

    function dtExecDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + uint48(file.head.signingDays + 
            file.head.frExecDays + file.head.dtExecDays) * 86400;
    }

    function terminateStartpoint(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + (uint48(file.head.signingDays + 
            file.head.frExecDays + file.head.dtExecDays + file.head.dtConfirmDays)) * 86400;
    }

    function votingDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.proposeDate + (uint48(file.head.invExitDays + 
            file.head.votePrepareDays + file.head.votingDays)) * 86400;
    }    

    function isRegistered(Repo storage repo, address body) public view returns (bool) {
        return repo.filesList.contains(body);
    }

    function qtyOfFiles(Repo storage repo) public view returns (uint256) {
        return repo.filesList.length();
    }

    function getFilesList(Repo storage repo) public view returns (address[] memory) {
        return repo.filesList.values();
    }

    function getFile(Repo storage repo, address body) public view returns (File memory) {
        return repo.files[body];
    }

    function getHeadOfFile(Repo storage repo, address body)
        public view onlyRegistered(repo, body) returns (Head memory)
    {
        return repo.files[body].head;
    }

}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
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
        uint32 maxTotalPar;
        uint16 titleOfVerifier;
        uint16 maxQtyOfInvestors;
        uint32 ceilingPrice;
        uint32 floorPrice;
        uint16 lockupDays;
        uint16 offPrice;
        uint16 votingWeight;
        uint16 distrWeight;
        uint16 para;
    }

    function listingRuleParser(bytes32 sn) public pure returns(ListingRule memory rule) {
        uint _sn = uint(sn);
        
        rule = ListingRule({
            seqOfRule: uint16(_sn >> 240),
            titleOfIssuer: uint16(_sn >> 224),
            classOfShare: uint16(_sn >> 208),
            maxTotalPar: uint32(_sn >> 176),
            titleOfVerifier: uint16(_sn >> 160), 
            maxQtyOfInvestors: uint16(_sn >> 144),
            ceilingPrice: uint32(_sn >> 112),
            floorPrice: uint32(_sn >> 80),
            lockupDays: uint16(_sn >> 64),
            offPrice: uint16(_sn >> 48),
            votingWeight: uint16(_sn >> 32),
            distrWeight: uint16(_sn >> 16),
            para: uint16(_sn)
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