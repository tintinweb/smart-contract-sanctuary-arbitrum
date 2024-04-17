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

import "../../../lib/SwapsRepo.sol";
import "../../../lib/DealsRepo.sol";

import "../../common/components/ISigPage.sol";

interface IInvestmentAgreement is ISigPage {

    //##################
    //##    Event     ##
    //##################

    event RegDeal(uint indexed seqOfDeal);

    event ClearDealCP(
        uint256 indexed seq,
        bytes32 indexed hashLock,
        uint indexed closingDeadline
    );

    event CloseDeal(uint256 indexed seq, string indexed hashKey);

    event TerminateDeal(uint256 indexed seq);
    
    event CreateSwap(uint seqOfDeal, bytes32 snOfSwap);

    event PayOffSwap(uint seqOfDeal, uint seqOfSwap, uint msgValue);

    event TerminateSwap(uint seqOfDeal, uint seqOfSwap);

    event PayOffApprovedDeal(uint seqOfDeal, uint msgValue);

    //##################
    //##  Write I/O  ##
    //##################

    // ======== InvestmentAgreement ========

    function addDeal(
        bytes32 sn,
        uint buyer,
        uint groupOfBuyer,
        uint paid,
        uint par,
        uint distrWeight
    ) external;

    function regDeal(DealsRepo.Deal memory deal) external returns(uint16 seqOfDeal);

    function delDeal(uint256 seq) external;

    function lockDealSubject(uint256 seq) external returns (bool flag);

    function releaseDealSubject(uint256 seq) external returns (bool flag);

    function clearDealCP( uint256 seq, bytes32 hashLock, uint closingDeadline) external;

    function closeDeal(uint256 seq, string memory hashKey)
        external returns (bool flag);

    function directCloseDeal(uint256 seq) external returns (bool flag);

    function terminateDeal(uint256 seqOfDeal) external returns(bool);

    function takeGift(uint256 seq) external returns(bool);

    function finalizeIA() external;

    // ==== Swap ====

    function createSwap (
        uint seqOfMotion,
        uint seqOfDeal,
        uint paidOfTarget,
        uint seqOfPledge,
        uint caller
    ) external returns(SwapsRepo.Swap memory swap);

    function payOffSwap(
        uint seqOfMotion,
        uint seqOfDeal,
        uint seqOfSwap,
        uint msgValue,
        uint centPrice
    ) external returns(SwapsRepo.Swap memory swap);

    function terminateSwap(
        uint seqOfMotion,
        uint seqOfDeal,
        uint seqOfSwap
    ) external returns (SwapsRepo.Swap memory swap);

    function payOffApprovedDeal(
        uint seqOfDeal,
        uint msgValue,
        uint caller
    ) external returns (bool flag);

    function requestPriceDiff(
        uint seqOfDeal,
        uint seqOfShare
    ) external;

    //  #####################
    //  ##     Read I/O    ##
    //  #####################

    // ======== InvestmentAgreement ========
    function getTypeOfIA() external view returns (uint8);

    function getDeal(uint256 seq) external view returns (DealsRepo.Deal memory);

    function getSeqList() external view returns (uint[] memory);

    // ==== Swap ====

    function getSwap(uint seqOfDeal, uint256 seqOfSwap)
        external view returns (SwapsRepo.Swap memory);

    function getAllSwaps(uint seqOfDeal)
        external view returns (SwapsRepo.Swap[] memory);

    function allSwapsClosed(uint seqOfDeal)
        external view returns (bool);

    function checkValueOfSwap(uint seqOfDeal, uint seqOfSwap)
        external view returns(uint);

    function checkValueOfDeal(uint seqOfDeal)
        external view returns (uint);

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

import "../../common/components/ISigPage.sol";
import "../../../lib/EnumerableSet.sol";
import "../../../lib/DocsRepo.sol";

interface IShareholdersAgreement is ISigPage {

    enum TitleOfTerm {
        ZeroPoint,
        AntiDilution,   // 1
        LockUp,         // 2
        DragAlong,      // 3
        TagAlong,       // 4
        Options         // 5
    }

    // ==== Rules ========

/*
    |  Seq  |        Type       |    Abb       |            Description                     |       
    |    0  |  GovernanceRule   |     GR       | Board Constitution and General Rules of GM | 
    |    1  |  VotingRuleOfGM   |     CI       | VR for Capital Increase                    |
    |    2  |                   |   SText      | VR for External Share Transfer             |
    |    3  |                   |   STint      | VR for Internal Share Transfer             |
    |    4  |                   |    1+3       | VR for CI & STint                          |
    |    5  |                   |    2+3       | VR for SText & STint                       |
    |    6  |                   |   1+2+3      | VR for CI & SText & STint                  |
    |    7  |                   |    1+2       | VR for CI & SText                          |
    |    8  |                   |   SHA        | VR for Update SHA                          |
    |    9  |                   |  O-Issue-GM  | VR for Ordinary Issues of GeneralMeeting   |
    |   10  |                   |  S-Issue-GM  | VR for Special Issues Of GeneralMeeting    |
    |   11  | VotingRuleOfBoard |     CI       | VR for Capital Increase                    |
    |   12  |                   |   SText      | VR for External Share Transfer             |
    |   13  |                   |   STint      | VR for Internal Share Transfer             |
    |   14  |                   |    1+3       | VR for CI & STint                          |
    |   15  |                   |    2+3       | VR for SText & STint                       |
    |   16  |                   |   1+2+3      | VR for CI & SText & STint                  |
    |   17  |                   |    1+2       | VR for CI & SText                          |
    |   18  |                   |   SHA        | VR for Update SHA                          |
    |   19  |                   |  O-Issue-B   | VR for Ordinary Issues Of Board            |
    |   20  |                   |  S-Issue-B   | VR for Special Issues Of Board             |
    |   21  | UnilateralDecision| UniDecPower  | UnilateralDicisionPowerWithoutVoting       |
    ...

    |  256  | PositionAllocateRule |   PA Rule   | Management Positions' Allocation Rules    |
    ...

    |  512  | FirstRefusalRule  |  FR for CI...| FR rule for Investment Deal                |
    ...

    |  768  | GroupUpdateOrder  |  GroupUpdate | Grouping Members as per their relationship |
    ...

    |  1024 | ListingRule       |  ListingRule | Listing Rule for Share Issue & Transfer    |
    ...

*/

    struct TermsRepo {
        // title => body
        mapping(uint256 => address) terms;
        EnumerableSet.UintSet seqList;
    }

    struct RulesRepo {
        // seq => rule
        mapping(uint256 => bytes32) rules;
        EnumerableSet.UintSet seqList;
    }

    //##################
    //##     Write    ##
    //##################

    /**
     * @dev Create a clone contract as per the template type number (`typeOfDoc`) 
     * and its version number (`version`).
     * Note `typeOfDoc` and `version` shall be bigger than zero.
     */
    function createTerm(uint typeOfDoc, uint version) external;

    /**
     * @dev Remove tracking of a clone contract from mapping as per its template 
     * type number (`typeOfDoc`). 
     */
    function removeTerm(uint typeOfDoc) external;

    /**
     * @dev Add a pre-defined `rule` into the Rules Mapping (seqNumber => rule)
     * Note a sequence number (`seqNumber`) of the `rule` SHALL be able to be parsed by 
     * RuleParser library, and such `seqNumber` shall be used as the search key to 
     * retrieve the rule from the Rules Mapping.
     */
    function addRule(bytes32 rule) external;

    /**
     * @dev Remove tracking of a rule from the Rules Mapping as per its sequence 
     * number (`seq`). 
     */
    function removeRule(uint256 seq) external;

    /**
     * @dev Initiate the Shareholders Agreement with predefined default rules. 
     */
    function initDefaultRules() external;

    /**
     * @dev Transfer special Roles having write authorities to address "Zero",
     * so as to fix the contents of the Shareholders Agreement avoiding any further 
     * revision by any EOA. 
     */
    function finalizeSHA() external;

    //################
    //##    Read    ##
    //################

    // ==== Terms ====
 
    /**
     * @dev Returns whether a specific Term numbered as `title` exist  
     * in the current Shareholders Agreemnt.
     */
    function hasTitle(uint256 title) external view returns (bool);

    /**
     * @dev Returns total quantities of Terms in the current 
     * Shareholders Agreemnt.
     */
    function qtyOfTerms() external view returns (uint256);

    /**
     * @dev Returns total quantities of Terms stiputed in the current 
     * Shareholders Agreemnt.
     */
    function getTitles() external view returns (uint256[] memory);

    /**
     * @dev Returns the contract address of the specific Term  
     * numbered as `title` from the Terms Mapping of the Shareholders Agreemnt.
     */
    function getTerm(uint256 title) external view returns (address);

    // ==== Rules ====

    /**
     * @dev Returns whether a specific Rule numbered as `seq` exist  
     * in the current Shareholders Agreemnt.
     */    
    function hasRule(uint256 seq) external view returns (bool);

    /**
     * @dev Returns total quantities of Rules in the current 
     * Shareholders Agreemnt.
     */
    function qtyOfRules() external view returns (uint256);

    /**
     * @dev Returns total quantities of Rules stiputed in the current 
     * Shareholders Agreemnt.
     */
    function getRules() external view returns (uint256[] memory);

    /**
     * @dev Returns the specific Rule numbered as `seq` from the Rules Mapping
     * of the Shareholders Agreemnt.
     */
    function getRule(uint256 seq) external view returns (bytes32);
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

import "../../common/components/IMeetingMinutes.sol";

import "../../../lib/OfficersRepo.sol";

interface IRegisterOfDirectors {

    //###################
    //##    events    ##
    //##################

    event AddPosition(bytes32 indexed snOfPos);

    event RemovePosition(uint256 indexed seqOfPos);

    event TakePosition(uint256 indexed seqOfPos, uint256 indexed caller);

    event QuitPosition(uint256 indexed seqOfPos, uint256 indexed caller);

    event RemoveOfficer(uint256 indexed seqOfPos);

    //#################
    //##  Write I/O  ##
    //#################

    function createPosition(bytes32 snOfPos) external;

    function updatePosition(OfficersRepo.Position memory pos) external;

    function removePosition(uint256 seqOfPos) external;

    function takePosition (uint256 seqOfPos, uint caller) external;

    function quitPosition (uint256 seqOfPos, uint caller) external; 

    function removeOfficer (uint256 seqOfPos) external;

    //################
    //##    Read    ##
    //################
    
    // ==== Positions ====

    function posExist(uint256 seqOfPos) external view returns (bool);

    function isOccupied(uint256 seqOfPos) external view returns (bool);

    function getPosition(uint256 seqOfPos) external view 
        returns (OfficersRepo.Position memory);

    // ==== Managers ====

    function isManager(uint256 acct) external view returns (bool);

    function getNumOfManagers() external view returns (uint256);    

    function getManagersList() external view returns (uint256[] memory);

    function getManagersPosList() external view returns(uint[] memory);

    // ==== Directors ====

    function isDirector(uint256 acct) external view returns (bool);

    function getNumOfDirectors() external view returns (uint256);

    function getDirectorsList() external view 
        returns (uint256[] memory);

    function getDirectorsPosList() external view 
        returns (uint256[] memory);

    // ==== Executives ====
    
    function hasPosition(uint256 acct, uint256 seqOfPos)
        external view returns(bool);

    function getPosInHand(uint256 acct) 
        external view returns (uint256[] memory);

    function getFullPosInfoInHand(uint acct) 
        external view returns (OfficersRepo.Position[] memory);

    function hasTitle(uint acct, uint title) 
        external returns (bool flag);

    function hasNominationRight(uint seqOfPos, uint acct) 
        external view returns (bool);

    // ==== seatsCalculator ====

    function getBoardSeatsOccupied(uint acct) external view 
        returns (uint256);

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

import "../../../lib/Checkpoints.sol";
import "../../../lib/MembersRepo.sol";
import "../../../lib/SharesRepo.sol";
import "../../../lib/TopChain.sol";

interface IRegisterOfMembers {
    //##################
    //##    Event     ##
    //##################

    event SetVoteBase(bool indexed basedOnPar);

    event CapIncrease(uint indexed votingWeight, uint indexed paid, uint indexed par, uint distrWeight);

    event CapDecrease(uint indexed votingWeight, uint indexed paid, uint indexed par, uint distrWeight);

    event SetMaxQtyOfMembers(uint indexed max);

    event SetMinVoteRatioOnChain(uint indexed min);

    event SetAmtBase(bool indexed basedOnPar);

    event AddMember(uint256 indexed acct, uint indexed qtyOfMembers);

    event AddShareToMember(uint indexed seqOfShare, uint indexed acct);

    event RemoveShareFromMember(uint indexed seqOfShare, uint indexed acct);

    event ChangeAmtOfMember(
        uint indexed acct,
        uint indexed paid,
        uint indexed par,
        bool increase
    );

    event AddMemberToGroup(uint indexed acct, uint indexed root);

    event RemoveMemberFromGroup(uint256 indexed acct, uint256 indexed root);

    event ChangeGroupRep(uint256 indexed orgRep, uint256 indexed newRep);

    //#################
    //##  Write I/O  ##
    //#################

    function setMaxQtyOfMembers(uint max) external;

    function setMinVoteRatioOnChain(uint min) external;

    function setVoteBase(bool _basedOnPar) external;

    function capIncrease(
        uint votingWeight, 
        uint distrWeight,
        uint paid, 
        uint par, 
        bool isIncrease
    ) external;

    function addMember(uint256 acct) external;

    function addShareToMember(
        SharesRepo.Share memory share
    ) external;

    function removeShareFromMember(
        SharesRepo.Share memory share
    ) external;

    function increaseAmtOfMember(
        uint acct,
        uint votingWeight,
        uint distrWeight,
        uint deltaPaid,
        uint deltaPar,
        bool isIncrease
    ) external ;

    function addMemberToGroup(uint acct, uint root) external;

    function removeMemberFromGroup(uint256 acct) external;

    // ##############
    // ##   Read   ##
    // ##############

    function isMember(uint256 acct) external view returns (bool);

    function qtyOfMembers() external view returns (uint);

    function membersList() external view returns (uint256[] memory);

    function sortedMembersList() external view returns (uint256[] memory);

    function qtyOfTopMembers() external view returns (uint);

    function topMembersList() external view returns (uint[] memory);

    // ---- Cap & Equity ----

    function ownersEquity() external view 
        returns(Checkpoints.Checkpoint memory);

    function ownersPoints() external view 
        returns(Checkpoints.Checkpoint memory);

    function capAtDate(uint date) external view
        returns (Checkpoints.Checkpoint memory);

   function equityOfMember(uint256 acct) external view
        returns (Checkpoints.Checkpoint memory);

   function pointsOfMember(uint256 acct) external view
        returns (Checkpoints.Checkpoint memory);

    function equityAtDate(uint acct, uint date) 
        external view returns(Checkpoints.Checkpoint memory);

    function votesInHand(uint256 acct)
        external view returns (uint64);

    function votesAtDate(uint256 acct, uint date)
        external view
        returns (uint64);

    function votesHistory(uint acct)
        external view 
        returns (Checkpoints.Checkpoint[] memory);

    // ---- ShareNum ----

    function qtyOfSharesInHand(uint acct)
        external view returns(uint);
    
    function sharesInHand(uint256 acct)
        external view
        returns (uint[] memory);

    // ---- Class ---- 

    function qtyOfSharesInClass(uint acct, uint class)
        external view returns(uint);

    function sharesInClass(uint256 acct, uint class)
        external view returns (uint[] memory);

    function isClassMember(uint256 acct, uint class)
        external view returns(bool);

    function classesBelonged(uint acct)
        external view returns(uint[] memory);

    function qtyOfClassMember(uint class)
        external view returns(uint);

    function getMembersOfClass(uint class)
        external view returns(uint256[] memory);
 
    // ---- TopChain ----

    function basedOnPar() external view returns (bool);

    function maxQtyOfMembers() external view returns (uint32);

    function minVoteRatioOnChain() external view returns (uint32);

    function totalVotes() external view returns (uint64);

    function controllor() external view returns (uint40);

    function tailOfChain() external view returns (uint40);

    function headOfQueue() external view returns (uint40);

    function tailOfQueue() external view returns (uint40);

    // ==== group ====

    function groupRep(uint256 acct) external view returns (uint40);

    function votesOfGroup(uint256 acct) external view returns (uint64);

    function deepOfGroup(uint256 acct) external view returns (uint256);

    function membersOfGroup(uint256 acct)
        external view
        returns (uint256[] memory);

    function qtyOfGroupsOnChain() external view returns (uint32);

    function qtyOfGroups() external view returns (uint256);

    function affiliated(uint256 acct1, uint256 acct2)
        external view
        returns (bool);

    // ==== snapshot ====

    function getSnapshot() external view returns (TopChain.Node[] memory, TopChain.Para memory);
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

import "../../../lib/SharesRepo.sol";
import "../../../lib/LockersRepo.sol";

import "../rom/IRegisterOfMembers.sol";

interface IRegisterOfShares {

    //##################
    //##    Event     ##
    //##################

    event IssueShare(bytes32 indexed shareNumber, uint indexed paid, uint indexed par);

    event PayInCapital(uint256 indexed seqOfShare, uint indexed amount);

    event SubAmountFromShare(uint256 indexed seqOfShare, uint indexed paid, uint indexed par);

    event DeregisterShare(uint256 indexed seqOfShare);

    event UpdatePriceOfPaid(uint indexed seqOfShare, uint indexed newPrice);

    event UpdatePaidInDeadline(uint256 indexed seqOfShare, uint indexed paidInDeadline);

    event DecreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid);

    event IncreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid);

    event SetPayInAmt(bytes32 indexed headSn, bytes32 indexed hashLock);

    event WithdrawPayInAmt(uint indexed seqOfShare, uint indexed amount);

    event IncreaseEquityOfClass(bool indexed isIncrease, uint indexed class, uint indexed amt);

    //##################
    //##  Write I/O   ##
    //##################

    function issueShare(
        bytes32 shareNumber, 
        uint payInDeadline, 
        uint paid, 
        uint par, 
        uint distrWeight
    ) external;

    function addShare(SharesRepo.Share memory share) external;

    function setPayInAmt(uint seqOfShare, uint amt, uint expireDate, bytes32 hashLock) external;

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey) external;

    function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external;

    function payInCapital(uint seqOfShare, uint amt) external;

    function transferShare(
        uint256 seqOfShare,
        uint paid,
        uint par,
        uint to,
        uint priceOfPaid,
        uint priceOfPar
    ) external;

    function decreaseCapital(uint256 seqOfShare, uint paid, uint par) external;

    // ==== CleanPaid ====

    function decreaseCleanPaid(uint256 seqOfShare, uint paid) external;

    function increaseCleanPaid(uint256 seqOfShare, uint paid) external;

    // ==== State & PaidInDeadline ====

    function updatePriceOfPaid(uint seqOfShare, uint newPrice) external;

    function updatePaidInDeadline(uint256 seqOfShare, uint paidInDeadline) external;

    // ==== EquityOfClass ====

    function increaseEquityOfClass(
        bool isIncrease,
        uint classOfShare,
        uint deltaPaid,
        uint deltaPar,
        uint deltaCleanPaid
    ) external;

    // ##################
    // ##   Read I/O   ##
    // ##################

    function counterOfShares() external view returns (uint32);

    function counterOfClasses() external view returns (uint16);

    // ==== SharesRepo ====

    function isShare(
        uint256 seqOfShare
    ) external view returns (bool);

    function getShare(
        uint256 seqOfShare
    ) external view returns (
        SharesRepo.Share memory
    );

    function getQtyOfShares() external view returns (uint);

    function getSeqListOfShares() external view returns (uint[] memory);

    function getSharesList() external view returns (SharesRepo.Share[] memory);

    // ---- Class ----    

    function getQtyOfSharesInClass(
        uint classOfShare
    ) external view returns (uint);

    function getSeqListOfClass(
        uint classOfShare
    ) external view returns (uint[] memory);

    function getInfoOfClass(
        uint classOfShare
    ) external view returns (SharesRepo.Share memory);

    function getSharesOfClass(
        uint classOfShare
    ) external view returns (SharesRepo.Share[] memory);

    // ==== PayInCapital ====

    function getLocker(
        bytes32 hashLock
    ) external view returns (LockersRepo.Locker memory);

    function getLocksList() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.4
 *
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

import "../../../lib/BallotsBox.sol";
import "../../../lib/MotionsRepo.sol";
import "../../../lib/RulesParser.sol";
import "../../../lib/DelegateMap.sol";

interface IMeetingMinutes {

    //##################
    //##    events    ##
    //##################

    event CreateMotion(bytes32 indexed snOfMotion, uint256 indexed contents);

    event ProposeMotionToGeneralMeeting(uint256 indexed seqOfMotion, uint256 indexed proposer);

    event ProposeMotionToBoard(uint256 indexed seqOfMotion, uint256 indexed proposer);

    event EntrustDelegate(uint256 indexed seqOfMotion, uint256 indexed delegate, uint256 indexed principal);

    event CastVoteInGeneralMeeting(uint256 indexed seqOfMotion, uint256 indexed caller, uint indexed attitude, bytes32 sigHash);    

    event CastVoteInBoardMeeting(uint256 indexed seqOfMotion, uint256 indexed caller, uint indexed attitude, bytes32 sigHash);    

    event VoteCounting(uint256 indexed seqOfMotion, uint8 indexed result);            

    event ExecResolution(uint256 indexed seqOfMotion, uint256 indexed caller);

    //#################
    //##  Write I/O  ##
    //#################

    function nominateOfficer(
        uint256 seqOfPos,
        uint seqOfVR,
        uint canidate,
        uint nominator
    ) external returns(uint64);

    function createMotionToRemoveOfficer(
        uint256 seqOfPos,
        uint seqOfVR,
        uint nominator    
    ) external returns(uint64);

    function createMotionToApproveDoc(
        uint doc,
        uint seqOfVR,
        uint executor,
        uint proposer    
    ) external returns(uint64);

    function createMotionToDistributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external returns (uint64);

    function createMotionToTransferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external returns (uint64);

    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor,
        uint proposer
    ) external returns(uint64);

    function createMotionToDeprecateGK(address receiver,uint proposer) external returns(uint64);

    function proposeMotionToGeneralMeeting(
        uint256 seqOfMotion,
        uint proposer
    ) external;

    function proposeMotionToBoard (
        uint seqOfMotion,
        uint caller
    ) external;

    function entrustDelegate(
        uint256 seqOfMotion,
        uint delegate, 
        uint principal
    ) external;

    // ==== Vote ====

    function castVoteInGeneralMeeting(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external;

    function castVoteInBoardMeeting(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external;

    // ==== UpdateVoteResult ====

    function voteCounting(bool flag0, uint256 seqOfMotion, MotionsRepo.VoteCalBase memory base) 
        external returns(uint8);

    // ==== ExecResolution ====

    function execResolution(uint256 seqOfMotion, uint256 contents, uint caller)
        external;

    function distributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfMotion,
        uint caller
    ) external;

    function transferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion,
        uint caller
    ) external;

    function execAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        uint caller
    ) external returns(uint contents);

    function deprecateGK(address receiver, uint seqOfMotion, uint executor) external;

    //################
    //##    Read    ##
    //################


    // ==== Motions ====

    function isProposed(uint256 seqOfMotion) external view returns (bool);

    function voteStarted(uint256 seqOfMotion) external view returns (bool);

    function voteEnded(uint256 seqOfMotion) external view returns (bool);

    // ==== Delegate ====

    function getVoterOfDelegateMap(uint256 seqOfMotion, uint256 acct)
        external view returns (DelegateMap.Voter memory);

    function getDelegateOf(uint256 seqOfMotion, uint acct)
        external view returns (uint);

    // ==== motion ====

    function getMotion(uint256 seqOfMotion)
        external view returns (MotionsRepo.Motion memory motion);

    // ==== voting ====

    function isVoted(uint256 seqOfMotion, uint256 acct) external view returns (bool);

    function isVotedFor(
        uint256 seqOfMotion,
        uint256 acct,
        uint atti
    ) external view returns (bool);

    function getCaseOfAttitude(uint256 seqOfMotion, uint atti)
        external view returns (BallotsBox.Case memory );

    function getBallot(uint256 seqOfMotion, uint256 acct)
        external view returns (BallotsBox.Ballot memory);

    function isPassed(uint256 seqOfMotion) external view returns (bool);

    function getSeqList() external view returns (uint[] memory);

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

import "../../../lib/ArrayUtils.sol";
import "../../../lib/EnumerableSet.sol";
import "../../../lib/SigsRepo.sol";

interface ISigPage {

    event CirculateDoc();

    //##################
    //##   Write I/O  ##
    //##################

    function circulateDoc() external;

    function setTiming(bool initPage, uint signingDays, uint closingDays) external;

    function addBlank(bool initPage, bool beBuyer, uint256 seqOfDeal, uint256 acct)
        external;

    function removeBlank(bool initPage, uint256 seqOfDeal, uint256 acct)
        external;

    function signDoc(bool initPage, uint256 caller, bytes32 sigHash) 
        external;    

    function regSig(uint256 signer, uint sigDate, bytes32 sigHash)
        external returns(bool flag);

    //##################
    //##   read I/O   ##
    //##################

    function getParasOfPage(bool initPage) external view 
        returns (SigsRepo.Signature memory);

    function circulated() external view returns(bool);

    function established() external view
        returns (bool flag);

    function getCirculateDate() external view returns(uint48);

    function getSigningDays() external view returns(uint16);

    function getClosingDays() external view returns(uint16);

    function getSigDeadline() external view returns(uint48);

    function getClosingDeadline() external view returns(uint48);

    function isBuyer(bool initPage, uint256 acct)
        external view returns(bool flag);

    function isSeller(bool initPage, uint256 acct)
        external view returns(bool flag);

    function isParty(uint256 acct)
        external view returns(bool flag);

    function isInitSigner(uint256 acct)
        external view returns (bool flag);


    function isSigner(uint256 acct)
        external view returns (bool flag);

    function getBuyers(bool initPage)
        external view returns (uint256[] memory buyers);

    function getSellers(bool initPage)
        external view returns (uint256[] memory sellers);

    function getParties() external view
        returns (uint256[] memory parties);

    function getSigOfParty(bool initParty, uint256 acct) external view
        returns (
            uint256[] memory seqOfDeals, 
            SigsRepo.Signature memory sig,
            bytes32 sigHash
        );

    function getSigsOfPage(bool initPage) external view
        returns (
            SigsRepo.Signature[] memory sigsOfBuyer, 
            SigsRepo.Signature[] memory sigsOfSeller
        );
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

library ArrayUtils {

    function merge(uint256[] memory arrA, uint256[] memory arrB)
        public pure returns(uint256[] memory)
    {
        uint256[] memory arrC = new uint256[](arrA.length + arrB.length);
        uint256 lenC;

        (arrC, lenC) = filter(arrA, arrC, 0);
        (arrC, lenC) = filter(arrB, arrC, lenC);

        return resize(arrC, lenC);
    }

    function filter(uint256[] memory arrA, uint256[] memory arrC, uint256 lenC) 
        public pure returns(uint256[] memory, uint256)
    {
        uint256 lenA = arrA.length;
        uint256 i;
        
        while (i < lenA) {
        
            uint256 j;
            while (j < lenC){
                if (arrA[i] == arrC[j]) break;
                j++;
            }

            if (j == lenC) {
                arrC[lenC] = arrA[i];
                lenC++;
            }

            i++;
        }

        return (arrC, lenC);
    }

    function refine(uint256[] memory arrA) 
        public pure returns(uint256[] memory)
    {
        uint256[] memory arrB = new uint256[](arrA.length);        
        uint256 lenB;
        (arrB, lenB) = filter(arrA, arrB, 0);

        return resize(arrB, lenB);
    }

    function resize(uint256[] memory arrA, uint256 len)
        public pure returns(uint256[] memory)
    {
        uint256[] memory output = new uint256[](len);

        while (len > 0) {
            output[len - 1] = arrA[len - 1];
            len--;
        }

        return output;
    }


    function combine(uint256[] memory arrA, uint256[] memory arrB)
        public pure returns (uint256[] memory)
    {
        uint256 lenA = arrA.length;
        uint256 lenB = arrB.length;
        uint256 i;

        uint256[] memory arrC = new uint256[](lenA + lenB);

        for (i = 0; i < lenA; i++) arrC[i] = arrA[i];
        for (i = 0; i < lenB; i++) arrC[lenA + i] = arrB[i];

        return arrC;
    }

    function minus(uint256[] memory arrA, uint256[] memory arrB)
        public pure returns (uint256[] memory)
    {
        uint256 lenA = arrA.length;
        uint256 lenB = arrB.length;

        uint256[] memory arrC = new uint256[](lenA);

        uint256 pointer;

        while (lenA > 0) {
            bool flag = false;
            lenB = arrB.length;
            
            while (lenB > 0) {
                if (arrB[lenB - 1] == arrA[lenA - 1]) {
                    flag = true;
                    break;
                }
                lenB--;
            }

            if (!flag) {
                arrC[pointer] = arrA[lenA - 1];
                pointer++;
            }

            lenA--;
        }

        return resize(arrC, pointer);
    }

    function fullyCoveredBy(uint256[] memory arrA, uint256[] memory arrB)
        public pure returns (bool)
    {
        uint256[] memory arrAr = refine(arrA);
        uint256[] memory arrBr = refine(arrB);

        uint256 lenA = arrAr.length;
        uint256 lenB = arrBr.length;

        while (lenA > 0) {
            uint256 i;
            while (i < lenB) {
                if (arrBr[i] == arrAr[lenA-1]) break;
                i++;
            }
            if (i==lenB) return false;
            lenA--;
        }

        return true;
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

// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
 *
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

library Checkpoints {

    struct Checkpoint {
        uint48 timestamp;
        uint16 rate;
        uint64 paid;
        uint64 par;
        uint64 points;
    }

    // checkpoints[0] {
    //     timestamp: counter;
    //     rate: distrWeight;
    //     paid;
    //     par;
    //     points: distrPoints;
    // }

    struct History {
        mapping (uint256 => Checkpoint) checkpoints;
    }

    //##################
    //##  Write I/O  ##
    //##################

    function push(
        History storage self,
        uint rate,
        uint paid,
        uint par,
        uint points
    ) public {

        uint256 pos = counterOfPoints(self);

        Checkpoint memory point = Checkpoint({
            timestamp: uint48(block.timestamp),
            rate: uint16(rate),
            paid: uint64(paid),
            par: uint64(par),
            points: uint64(points)
        });
        
        if (self.checkpoints[pos].timestamp == point.timestamp) {
            self.checkpoints[pos] = point;
        } else {
            self.checkpoints[pos+1] = point;
            _increaseCounter(self);
        }
    }

    function _increaseCounter(History storage self)
        public
    {
        self.checkpoints[0].timestamp++;
    }

    function updateDistrPoints(
        History storage self,
        uint rate,
        uint paid,
        uint par,
        uint points
    ) public {
        Checkpoint storage c = self.checkpoints[0];
        c.rate = uint16(rate);
        c.paid = uint64(paid);
        c.par = uint64(par);
        c.points = uint64(points);
    }

    //################
    //##    Read    ##
    //################

    function counterOfPoints(History storage self)
        public view returns (uint256)
    {
        return self.checkpoints[0].timestamp;
    }

    function latest(History storage self)
        public view returns (Checkpoint memory point)
    {
        point = self.checkpoints[counterOfPoints(self)];
    }

    function _average(uint256 a, uint256 b) private pure returns (uint256) {
        return (a & b) + ((a ^ b) >> 1);
    }

    function getAtDate(History storage self, uint256 timestamp)
        public view returns (Checkpoint memory point)
    {
        require(
            timestamp <= block.timestamp,
            "Checkpoints: block not yet mined"
        );

        uint256 high = counterOfPoints(self) + 1;
        uint256 low = 1;
        while (low < high) {
            uint256 mid = _average(low, high);
            if (self.checkpoints[mid].timestamp > timestamp) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        if (high > 1) point = self.checkpoints[high - 1];
    }

    function pointsOfHistory(History storage self)
        public view returns (Checkpoint[] memory) 
    {
        uint256 len = counterOfPoints(self);

        Checkpoint[] memory output = new Checkpoint[](len);

        while (len > 0) {
            output[len-1] = self.checkpoints[len];
            len--;
        }

        return output;
    }

    function getDistrPoints(History storage self)
        public view returns (Checkpoint memory) 
    {
        return self.checkpoints[0];
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
import "./MotionsRepo.sol";
import "./SwapsRepo.sol";
import "./SharesRepo.sol";

import "../comps/common/components/IMeetingMinutes.sol";
import "../comps/books/ros/IRegisterOfShares.sol";


library DealsRepo {
    using EnumerableSet for EnumerableSet.UintSet;
    using SwapsRepo for SwapsRepo.Repo;

    // _deals[0].head {
    //     seqOfDeal: counterOfClosedDeal;
    //     preSeq: counterOfDeal;
    //     typeOfDeal: typeOfIA;
    // }    

    enum TypeOfDeal {
        ZeroPoint,
        CapitalIncrease,
        ShareTransferExt,
        ShareTransferInt,
        PreEmptive,
        TagAlong,
        DragAlong,
        FirstRefusal,
        FreeGift
    }

    enum TypeOfIA {
        ZeroPoint,
        CapitalIncrease,
        ShareTransferExt,
        ShareTransferInt,
        CI_STint,
        SText_STint,
        CI_SText_STint,
        CI_SText
    }

    enum StateOfDeal {
        Drafting,
        Locked,
        Cleared,
        Closed,
        Terminated
    }

    struct Head {
        uint8 typeOfDeal;
        uint16 seqOfDeal;
        uint16 preSeq;
        uint16 classOfShare;
        uint32 seqOfShare;
        uint40 seller;
        uint32 priceOfPaid;
        uint32 priceOfPar;
        uint48 closingDeadline;
        uint16 votingWeight;
    }

    struct Body {
        uint40 buyer;
        uint40 groupOfBuyer;
        uint64 paid;
        uint64 par;
        uint8 state;
        uint16 para;
        uint16 distrWeight;
        bool flag;
    }

    struct Deal {
        Head head;
        Body body;
        bytes32 hashLock;
    }

    struct Repo {
        mapping(uint256 => Deal) deals;
        mapping(uint256 => SwapsRepo.Repo) swaps;
        //seqOfDeal => seqOfShare => bool
        mapping(uint => mapping(uint => bool)) priceDiffRequested;
        EnumerableSet.UintSet seqList;
    }

    //##################
    //##   Modifier   ##
    //##################

    modifier onlyCleared(Repo storage repo, uint256 seqOfDeal) {
        require(
            repo.deals[seqOfDeal].body.state == uint8(StateOfDeal.Cleared),
            "DR.mf.OC: wrong stateOfDeal"
        );
        _;
    }

    modifier dealExist(Repo storage repo, uint seqOfDeal) {
        require(isDeal(repo, seqOfDeal), "DR.mf.dealExist: not");
        _;
    }

    //#################
    //##  Write I/O  ##
    //#################

    function snParser(bytes32 sn) public pure returns(Head memory head) {
        uint _sn = uint(sn);

        head = Head({
            typeOfDeal: uint8(_sn >> 248),
            seqOfDeal: uint16(_sn >> 232),
            preSeq: uint16(_sn >> 216),
            classOfShare: uint16(_sn >> 200),
            seqOfShare: uint32(_sn >> 168),
            seller: uint40(_sn >> 128),
            priceOfPaid: uint32(_sn >> 96),
            priceOfPar: uint32(_sn >> 64),
            closingDeadline: uint48(_sn >> 16),
            votingWeight: uint16(_sn) 
        });

    } 

    function codifyHead(Head memory head) public pure returns(bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            head.typeOfDeal,
                            head.seqOfDeal,
                            head.preSeq,
                            head.classOfShare,
                            head.seqOfShare,
                            head.seller,
                            head.priceOfPaid,
                            head.priceOfPaid,
                            head.closingDeadline,
                            head.votingWeight);        
        assembly {
            sn := mload(add(_sn, 0x20))
        }
    }

    function addDeal(
        Repo storage repo,
        bytes32 sn,
        uint buyer,
        uint groupOfBuyer,
        uint paid,
        uint par,
        uint distrWeight
    ) public returns (uint16 seqOfDeal)  {

        Deal memory deal;

        deal.head = snParser(sn);

        deal.body.buyer = uint40(buyer);
        deal.body.groupOfBuyer = uint40(groupOfBuyer);
        deal.body.paid = uint64(paid);
        deal.body.par = uint64(par);
        deal.body.distrWeight = uint16(distrWeight);

        seqOfDeal = regDeal(repo, deal);
    }

    function regDeal(Repo storage repo, Deal memory deal) 
        public returns(uint16 seqOfDeal) 
    {
        require(deal.body.par > 0, "DR.RD: zero par");
        require(deal.body.par >= deal.body.paid, "DR.RD: paid overflow");

        deal.head.seqOfDeal = _increaseCounterOfDeal(repo);
        repo.seqList.add(deal.head.seqOfDeal);

        repo.deals[deal.head.seqOfDeal] = Deal({
            head: deal.head,
            body: deal.body,
            hashLock: bytes32(0)
        });
        seqOfDeal = deal.head.seqOfDeal;
    }

    function _increaseCounterOfDeal(Repo storage repo) private returns(uint16 seqOfDeal){
        repo.deals[0].head.preSeq++;
        seqOfDeal = repo.deals[0].head.preSeq;
    }

    function delDeal(Repo storage repo, uint256 seqOfDeal) public returns (bool flag) {
        if (repo.seqList.remove(seqOfDeal)) {
            delete repo.deals[seqOfDeal];
            repo.deals[0].head.preSeq--;
            flag = true;
        }
    }

    function lockDealSubject(Repo storage repo, uint256 seqOfDeal) public returns (bool flag) {
        if (repo.deals[seqOfDeal].body.state == uint8(StateOfDeal.Drafting)) {
            repo.deals[seqOfDeal].body.state = uint8(StateOfDeal.Locked);
            flag = true;
        }
    }

    function releaseDealSubject(Repo storage repo, uint256 seqOfDeal) public returns (bool flag)
    {
        uint8 state = repo.deals[seqOfDeal].body.state;

        if ( state < uint8(StateOfDeal.Closed) ) {

            repo.deals[seqOfDeal].body.state = uint8(StateOfDeal.Drafting);
            flag = true;

        } else if (state == uint8(StateOfDeal.Terminated)) {

            flag = true;            
        }
    }

    function clearDealCP(
        Repo storage repo,
        uint256 seqOfDeal,
        bytes32 hashLock,
        uint closingDeadline
    ) public {
        Deal storage deal = repo.deals[seqOfDeal];

        require(deal.body.state == uint8(StateOfDeal.Locked), 
            "IA.CDCP: wrong Deal state");

        deal.body.state = uint8(StateOfDeal.Cleared);
        deal.hashLock = hashLock;

        if (closingDeadline > 0) {
            if (block.timestamp < closingDeadline) 
                deal.head.closingDeadline = uint48(closingDeadline);
            else revert ("IA.clearDealCP: updated closingDeadline not FUTURE time");
        }
    }

    function closeDeal(Repo storage repo, uint256 seqOfDeal, string memory hashKey)
        public onlyCleared(repo, seqOfDeal) returns (bool flag)
    {
        require(
            repo.deals[seqOfDeal].hashLock == keccak256(bytes(hashKey)),
            "IA.closeDeal: hashKey NOT correct"
        );

        return _closeDeal(repo, seqOfDeal);
    }

    function directCloseDeal(Repo storage repo, uint seqOfDeal) 
        public returns (bool flag) 
    {
        require(repo.deals[seqOfDeal].body.state == uint8(StateOfDeal.Locked), 
            "IA.directCloseDeal: wrong state of deal");
        
        return _closeDeal(repo, seqOfDeal);
    }

    function _closeDeal(Repo storage repo, uint seqOfDeal)
        private returns(bool flag) 
    {
    
        Deal storage deal = repo.deals[seqOfDeal];

        require(
            block.timestamp < deal.head.closingDeadline,
            "IA.closeDeal: MISSED closing date"
        );

        deal.body.state = uint8(StateOfDeal.Closed);

        _increaseCounterOfClosedDeal(repo);

        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    function terminateDeal(Repo storage repo, uint256 seqOfDeal) public returns(bool flag){
        Body storage body = repo.deals[seqOfDeal].body;

        require(body.state == uint8(StateOfDeal.Locked) ||
            body.state == uint8(StateOfDeal.Cleared)
            , "DR.TD: wrong stateOfDeal");

        body.state = uint8(StateOfDeal.Terminated);

        _increaseCounterOfClosedDeal(repo);
        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    function takeGift(Repo storage repo, uint256 seqOfDeal)
        public returns (bool flag)
    {
        Deal storage deal = repo.deals[seqOfDeal];

        require(
            deal.head.typeOfDeal == uint8(TypeOfDeal.FreeGift),
            "not a gift deal"
        );

        require(
            repo.deals[deal.head.preSeq].body.state == uint8(StateOfDeal.Closed),
            "Capital Increase not closed"
        );

        require(deal.body.state == uint8(StateOfDeal.Locked), "wrong state");

        deal.body.state = uint8(StateOfDeal.Closed);

        _increaseCounterOfClosedDeal(repo);
        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    function _increaseCounterOfClosedDeal(Repo storage repo) private {
        repo.deals[0].head.seqOfDeal++;
    }

    function calTypeOfIA(Repo storage repo) public {
        uint[3] memory types;

        uint[] memory seqList = repo.seqList.values();
        uint len = seqList.length;
        
        while (len > 0) {
            uint typeOfDeal = repo.deals[seqList[len-1]].head.typeOfDeal;
            len--;

            if (typeOfDeal == 1) {
                if (types[0] == 0) types[0] = 1;
                continue;
            } else if (typeOfDeal == 2) {
                if (types[1] == 0) types[1] = 2;
                continue;
            } else if (typeOfDeal == 3) {
                if (types[2] == 0) types[2] = 3;
                continue;
            }
        }

        uint8 sum = uint8(types[0] + types[1] + types[2]);
        repo.deals[0].head.typeOfDeal = (sum == 3)
                ? (types[2] == 0)
                    ? 7
                    : 3
                : sum;
    }

    // ==== Swap ====

    function createSwap(
        Repo storage repo,
        uint seqOfMotion,
        uint seqOfDeal,
        uint paidOfTarget,
        uint seqOfPledge,
        uint caller,
        IRegisterOfShares _ros,
        IMeetingMinutes _gmm
    ) public returns(SwapsRepo.Swap memory swap) {
        Deal storage deal = repo.deals[seqOfDeal];

        require(caller == deal.head.seller, 
            "DR.createSwap: not seller");

        require(deal.body.state == uint8(StateOfDeal.Terminated),
            "DR.createSwap: wrong state");

        MotionsRepo.Motion memory motion = 
            _gmm.getMotion(seqOfMotion);

        require(
            motion.body.state == uint8(MotionsRepo.StateOfMotion.Rejected_ToBuy),
            "DR.createSwap: NO need to buy"
        );

        require(block.timestamp < motion.body.voteEndDate + 
            uint48(motion.votingRule.execDaysForPutOpt) * 86400, 
            "DR.createSwap: missed deadline");


        swap = SwapsRepo.Swap({
            seqOfSwap: 0,
            seqOfPledge: uint32(seqOfPledge),
            paidOfPledge: 0,
            seqOfTarget: deal.head.seqOfShare,
            paidOfTarget: uint64(paidOfTarget),
            priceOfDeal: deal.head.priceOfPaid,
            isPutOpt: true,
            state: uint8(SwapsRepo.StateOfSwap.Issued)
        });

        SharesRepo.Head memory headOfPledge = _ros.getShare(swap.seqOfPledge).head;

        require(_gmm.getBallot(seqOfMotion, _gmm.getDelegateOf(seqOfMotion, 
            headOfPledge.shareholder)).attitude == 2,
            "DR.createSwap: not vetoer");

        require (deal.body.paid >= repo.swaps[seqOfDeal].sumPaidOfTarget() +
            swap.paidOfTarget, "DR.createSwap: paidOfTarget overflow");

        swap.paidOfPledge = (swap.priceOfDeal - _ros.getShare(swap.seqOfTarget).head.priceOfPaid) * 
            swap.paidOfTarget / headOfPledge.priceOfPaid;

        return repo.swaps[seqOfDeal].regSwap(swap);
    }

    function payOffSwap(
        Repo storage repo,
        uint seqOfMotion,
        uint seqOfDeal,
        uint seqOfSwap,
        uint msgValue,
        uint centPrice,
        IMeetingMinutes _gmm
    ) public returns(SwapsRepo.Swap memory){

        MotionsRepo.Motion memory motion = _gmm.getMotion(seqOfMotion);

        require(block.timestamp < motion.body.voteEndDate + 
            uint48(motion.votingRule.execDaysForPutOpt) * 86400, 
            "DR.payOffSwap: missed deadline");
 
        return repo.swaps[seqOfDeal].payOffSwap(seqOfSwap, msgValue, centPrice);
    }

    function terminateSwap(
        Repo storage repo,
        uint seqOfMotion,
        uint seqOfDeal,
        uint seqOfSwap,
        IMeetingMinutes _gmm
    ) public returns (SwapsRepo.Swap memory){

        MotionsRepo.Motion memory motion = _gmm.getMotion(seqOfMotion);

        require(block.timestamp >= motion.body.voteEndDate + 
            uint48(motion.votingRule.execDaysForPutOpt) * 86400, 
            "DR.terminateSwap: still in exec period");

        return repo.swaps[seqOfDeal].terminateSwap(seqOfSwap);
    }

    function payOffApprovedDeal(
        Repo storage repo,
        uint seqOfDeal,
        uint caller
    ) public returns (bool flag){

        Deal storage deal = repo.deals[seqOfDeal];

        require(deal.head.typeOfDeal != uint8(TypeOfDeal.FreeGift),
            "DR.payApprDeal: free gift");

        require(caller == deal.body.buyer,
            "DR.payApprDeal: not buyer");

        require(deal.body.state == uint8(StateOfDeal.Locked) ||
            deal.body.state == uint8(StateOfDeal.Cleared) , 
            "DR.payApprDeal: wrong state");

        require(block.timestamp < deal.head.closingDeadline,
            "DR.payApprDeal: missed closingDeadline");

        deal.body.state = uint8(StateOfDeal.Closed);

        _increaseCounterOfClosedDeal(repo);

        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    function requestPriceDiff(
        Repo storage repo,
        uint seqOfDeal,
        uint seqOfShare
    ) public dealExist(repo, seqOfDeal) {
        require(!repo.priceDiffRequested[seqOfDeal][seqOfShare],
            "DR.requestPriceDiff: already requested");
        repo.priceDiffRequested[seqOfDeal][seqOfShare] = true;      
    }


    //  ##########################
    //  ##       Read I/O       ##
    //  ##########################

    function getTypeOfIA(Repo storage repo) external view returns (uint8) {
        return repo.deals[0].head.typeOfDeal;
    }

    function counterOfDeal(Repo storage repo) public view returns (uint16) {
        return repo.deals[0].head.preSeq;
    }

    function counterOfClosedDeal(Repo storage repo) public view returns (uint16) {
        return repo.deals[0].head.seqOfDeal;
    }

    function isDeal(Repo storage repo, uint256 seqOfDeal) public view returns (bool) {
        return repo.seqList.contains(seqOfDeal);
    }
    
    function getDeal(Repo storage repo, uint256 seq) 
        external view dealExist(repo, seq) returns (Deal memory)
    {
        return repo.deals[seq];
    }

    function getSeqList(Repo storage repo) external view returns (uint[] memory) {
        return repo.seqList.values();
    }
    
    // ==== Swap ====

    function counterOfSwaps(Repo storage repo, uint seqOfDeal)
        public view returns (uint16)
    {
        return repo.swaps[seqOfDeal].counterOfSwaps();
    }

    function sumPaidOfTarget(Repo storage repo, uint seqOfDeal)
        public view returns (uint64)
    {
        return repo.swaps[seqOfDeal].sumPaidOfTarget();
    }

    function isSwap(Repo storage repo, uint seqOfDeal, uint256 seqOfSwap)
        public view returns (bool)
    {
        return repo.swaps[seqOfDeal].isSwap(seqOfSwap);
    }

    function getSwap(Repo storage repo, uint seqOfDeal, uint256 seqOfSwap)
        public view returns (SwapsRepo.Swap memory)
    {
        return repo.swaps[seqOfDeal].getSwap(seqOfSwap);
    }

    function getAllSwaps(Repo storage repo, uint seqOfDeal)
        public view returns (SwapsRepo.Swap[] memory )
    {
        return repo.swaps[seqOfDeal].getAllSwaps();
    }

    function allSwapsClosed(Repo storage repo, uint seqOfDeal)
        public view returns (bool)
    {
        return repo.swaps[seqOfDeal].allSwapsClosed();
    }

    // ==== Value Calculation ==== 

    function checkValueOfSwap(
        Repo storage repo,
        uint seqOfDeal,
        uint seqOfSwap,
        uint centPrice
    ) public view dealExist(repo, seqOfDeal) returns (uint) {
        return repo.swaps[seqOfDeal].checkValueOfSwap(seqOfSwap, centPrice);
    }

    function checkValueOfDeal(
        Repo storage repo, 
        uint seqOfDeal, 
        uint centPrice
    ) public view returns (uint) {
        Deal memory deal = repo.deals[seqOfDeal];

        return (uint(deal.body.paid * deal.head.priceOfPaid) + 
            uint((deal.body.par - deal.body.paid) * deal.head.priceOfPar)) / 10 ** 4 *
            centPrice / 100;
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

import "../comps/books/rom/IRegisterOfMembers.sol";
import "../comps/books/rod/IRegisterOfDirectors.sol";

library DelegateMap {

    struct LeavesInfo {
        uint64 weight;
        uint32 emptyHead;
    }

    struct Voter {
        uint40 delegate;
        uint64 weight;
        uint64 repWeight;
        uint32 repHead;
        uint[] principals;
    }

    struct Map {
        mapping(uint256 => Voter) voters;
    }

    // #################
    // ##    Write    ##
    // #################

    function entrustDelegate(
        Map storage map,
        uint principal,
        uint delegate,
        uint weight
    ) public returns (bool flag) {
        require(principal != 0, "DM.ED: zero principal");
        require(delegate != 0, "DM.ED: zero delegate");
        require(principal != delegate,"DM.ED: self delegate");

        if (map.voters[principal].delegate == 0 && 
            map.voters[delegate].delegate == 0) 
        {
            Voter storage p = map.voters[principal];
            Voter storage d = map.voters[delegate];

            p.delegate = uint40(delegate);
            p.weight = uint64(weight);

            d.repHead += (p.repHead + 1);
            d.repWeight += (p.repWeight + p.weight);

            d.principals.push(uint40(principal));
            _consolidatePrincipals(p.principals, d);

            flag = true;
        }
    }

    function _consolidatePrincipals(uint[] memory principals, Voter storage d) private {
        uint len = principals.length;

        while (len > 0) {
            d.principals.push(principals[len-1]);
            len--;
        }        
    }

    // #################
    // ##    Read     ##
    // #################

    function getDelegateOf(Map storage map, uint acct)
        public
        view
        returns (uint d)
    {
        while (acct > 0) {
            d = acct;
            acct = map.voters[d].delegate;
        }
    }

    function updateLeavesWeightAtDate(Map storage map, uint256 acct, uint baseDate, IRegisterOfMembers _rom)
        public
    {
        LeavesInfo memory info;
        Voter storage voter = map.voters[acct];

        uint[] memory leaves = voter.principals;
        uint256 len = leaves.length;

        while (len > 0) {
            uint64 w = _rom.votesAtDate(leaves[len-1], baseDate);
            if (w > 0) {
                info.weight += w;
            } else {
                info.emptyHead++;
            }
            len--;
        }
        
        voter.weight = _rom.votesAtDate(acct, baseDate);
        voter.repWeight = info.weight;
        voter.repHead = uint32(leaves.length) - info.emptyHead;
    }

    function updateLeavesHeadcountOfDirectors(Map storage map, uint256 acct, IRegisterOfDirectors _rod) 
        public 
    {
        uint[] memory leaves = map.voters[acct].principals;
        uint256 len = leaves.length;

        uint32 repHead;
        while (len > 0) {
            if (_rod.isDirector(leaves[len-1])) repHead++;
            len--;
        }

        map.voters[acct].repHead = repHead;
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

library DocsRepo {
    
    struct Head {
        uint32 typeOfDoc;
        uint32 version;
        uint64 seqOfDoc;
        uint40 author;
        uint40 creator;
        uint48 createDate;
    }
 
    struct Body {
        uint64 seq;
        address addr;
    }

    struct Doc {
        Head head;
        address body;
    }

    struct Repo {
        // typeOfDoc => version => seqOfDoc => Body
        mapping(uint256 => mapping(uint256 => mapping(uint256 => Body))) bodies;
        mapping(address => Head) heads;
    }

    //##################
    //##  Write I/O   ##
    //##################

    function snParser(bytes32 sn) public pure returns(Head memory head) {
        uint _sn = uint(sn);

        head.typeOfDoc = uint32(_sn >> 224);
        head.version = uint32(_sn >> 192);
        head.seqOfDoc = uint64(_sn >> 128);
        head.author = uint40(_sn >> 88);
    }

    function codifyHead(Head memory head) public pure returns(bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            head.typeOfDoc,
                            head.version,
                            head.seqOfDoc,
                            head.author,
                            head.creator,
                            head.createDate);  
        assembly {
            sn := mload(add(_sn, 0x20))
        }
    }

    function setTemplate(
        Repo storage repo,
        uint typeOfDoc, 
        address body,
        uint author,
        uint caller
    ) public returns (Head memory head) {
        head.typeOfDoc = uint32(typeOfDoc);
        head.author = uint40(author);
        head.creator = uint40(caller);

        require(body != address(0), "DR.setTemplate: zero address");
        require(head.typeOfDoc > 0, "DR.setTemplate: zero typeOfDoc");
        if (head.typeOfDoc > counterOfTypes(repo))
            head.typeOfDoc = _increaseCounterOfTypes(repo);

        require(head.author > 0, "DR.setTemplate: zero author");
        require(head.creator > 0, "DR.setTemplate: zero creator");

        head.version = _increaseCounterOfVersions(repo, head.typeOfDoc);
        head.createDate = uint48(block.timestamp);

        repo.bodies[head.typeOfDoc][head.version][0].addr = body;
        repo.heads[body] = head;
    }

    function createDoc(
        Repo storage repo, 
        bytes32 snOfDoc,
        address creator
    ) public returns (Doc memory doc)
    {
        doc.head = snParser(snOfDoc);
        doc.head.creator = uint40(uint160(creator));

        require(doc.head.typeOfDoc > 0, "DR.createDoc: zero typeOfDoc");
        require(doc.head.version > 0, "DR.createDoc: zero version");
        // require(doc.head.creator > 0, "DR.createDoc: zero creator");

        address temp = repo.bodies[doc.head.typeOfDoc][doc.head.version][0].addr;
        require(temp != address(0), "DR.createDoc: template not ready");

        doc.head.author = repo.heads[temp].author;
        doc.head.seqOfDoc = _increaseCounterOfDocs(repo, doc.head.typeOfDoc, doc.head.version);            
        doc.head.createDate = uint48(block.timestamp);

        doc.body = _createClone(temp);

        repo.bodies[doc.head.typeOfDoc][doc.head.version][doc.head.seqOfDoc].addr = doc.body;
        repo.heads[doc.body] = doc.head;

    }

    function transferIPR(
        Repo storage repo,
        uint typeOfDoc,
        uint version,
        uint transferee,
        uint caller 
    ) public {
        require (caller == getAuthor(repo, typeOfDoc, version),
            "DR.transferIPR: not author");
        repo.heads[repo.bodies[typeOfDoc][version][0].addr].author = uint40(transferee);
    }

    function _increaseCounterOfTypes(Repo storage repo) 
        private returns(uint32) 
    {
        repo.bodies[0][0][0].seq++;
        return uint32(repo.bodies[0][0][0].seq);
    }

    function _increaseCounterOfVersions(
        Repo storage repo, 
        uint256 typeOfDoc
    ) private returns(uint32) {
        repo.bodies[typeOfDoc][0][0].seq++;
        return uint32(repo.bodies[typeOfDoc][0][0].seq);
    }

    function _increaseCounterOfDocs(
        Repo storage repo, 
        uint256 typeOfDoc, 
        uint256 version
    ) private returns(uint64) {
        repo.bodies[typeOfDoc][version][0].seq++;
        return repo.bodies[typeOfDoc][version][0].seq;
    }

    // ==== CloneFactory ====

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly


    function _createClone(address temp) private returns (address result) {
        bytes20 tempBytes = bytes20(temp);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), tempBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }

    function _isClone(address temp, address query)
        private view returns (bool result)
    {
        bytes20 tempBytes = bytes20(temp);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), tempBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }

    //##################
    //##   read I/O   ##
    //##################


    function counterOfTypes(Repo storage repo) public view returns(uint32) {
        return uint32(repo.bodies[0][0][0].seq);
    }

    function counterOfVersions(Repo storage repo, uint typeOfDoc) public view returns(uint32) {
        return uint32(repo.bodies[uint32(typeOfDoc)][0][0].seq);
    }

    function counterOfDocs(Repo storage repo, uint typeOfDoc, uint version) public view returns(uint64) {
        return repo.bodies[uint32(typeOfDoc)][uint32(version)][0].seq;
    }

    function getAuthor(
        Repo storage repo,
        uint typeOfDoc,
        uint version
    ) public view returns(uint40) {
        address temp = repo.bodies[typeOfDoc][version][0].addr;
        require(temp != address(0), "getAuthor: temp not exist");

        return repo.heads[temp].author;
    }

    function getAuthorByBody(
        Repo storage repo,
        address body
    ) public view returns(uint40) {
        Head memory head = getHeadByBody(repo, body);
        return getAuthor(repo, head.typeOfDoc, head.version);
    }

    function docExist(Repo storage repo, address body) public view returns(bool) {
        Head memory head = repo.heads[body];
        if (   body == address(0) 
            || head.typeOfDoc == 0 
            || head.version == 0 
            || head.seqOfDoc == 0
        ) return false;
   
        return repo.bodies[head.typeOfDoc][head.version][head.seqOfDoc].addr == body;
    }

    function getHeadByBody(
        Repo storage repo,
        address body
    ) public view returns (Head memory ) {
        return repo.heads[body];
    }


    function getDoc(
        Repo storage repo,
        bytes32 snOfDoc
    ) public view returns(Doc memory doc) {
        doc.head = snParser(snOfDoc);

        doc.body = repo.bodies[doc.head.typeOfDoc][doc.head.version][doc.head.seqOfDoc].addr;
        doc.head = repo.heads[doc.body];
    }

    function getVersionsList(
        Repo storage repo,
        uint typeOfDoc
    ) public view returns(Doc[] memory)
    {
        uint32 len = counterOfVersions(repo, typeOfDoc);
        Doc[] memory out = new Doc[](len);

        while (len > 0) {
            Head memory head;
            head.typeOfDoc = uint32(typeOfDoc);
            head.version = len;

            out[len - 1] = getDoc(repo, codifyHead(head));
            len--;
        }

        return out;
    }

    function getDocsList(
        Repo storage repo,
        bytes32 snOfDoc
    ) public view returns(Doc[] memory) {
        Head memory head = snParser(snOfDoc);
                
        uint64 len = counterOfDocs(repo, head.typeOfDoc, head.version);
        Doc[] memory out = new Doc[](len);

        while (len > 0) {
            head.seqOfDoc = len;
            out[len - 1] = getDoc(repo, codifyHead(head));
            len--;
        }

        return out;
    }

    function verifyDoc(
        Repo storage repo, 
        bytes32 snOfDoc
    ) public view returns(bool) {
        Head memory head = snParser(snOfDoc);

        address temp = repo.bodies[head.typeOfDoc][head.version][0].addr;
        address target = repo.bodies[head.typeOfDoc][head.version][head.seqOfDoc].addr;

        return _isClone(temp, target);
    }

}

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

import "../comps/books/rom/IRegisterOfMembers.sol";
import "../comps/books/ros/IRegisterOfShares.sol";

import "./DealsRepo.sol";
import "./RulesParser.sol";
import "./SharesRepo.sol";

library LinksRepo {
    using EnumerableSet for EnumerableSet.UintSet;
    using RulesParser for bytes32;

    enum TriggerTypeOfAlongs {
        NoConditions,
        ControlChanged,
        ControlChangedWithHigherPrice,
        ControlChangedWithHigherROE
    }

    struct Link {
        RulesParser.LinkRule linkRule;
        EnumerableSet.UintSet followersList;
    }

    struct Repo {
        // dragger => Link
        mapping(uint256 => Link) links;
        EnumerableSet.UintSet  draggersList;
    }

    modifier draggerExist(Repo storage repo, uint dragger, IRegisterOfMembers _rom) {
        require(isDragger(repo, dragger, _rom), "LR.mf.draggerExist: not");
        _;
    }

    // ###############
    // ## Write I/O ##
    // ###############

    function addDragger(Repo storage repo, bytes32 rule, uint256 dragger, IRegisterOfMembers _rom) public {
        uint40 groupRep = _rom.groupRep(dragger);
        if (repo.draggersList.add(groupRep))
            repo.links[groupRep].linkRule = rule.linkRuleParser();
    }

    function removeDragger(Repo storage repo, uint256 dragger) public {
        if (repo.draggersList.remove(dragger))
            delete repo.links[dragger];
    }

    function addFollower(Repo storage repo, uint256 dragger, uint256 follower) public {
        repo.links[dragger].followersList.add(uint40(follower));
    }

    function removeFollower(Repo storage repo, uint256 dragger, uint256 follower) public {
        repo.links[dragger].followersList.remove(follower);
    }

    // ################
    // ##  Read I/O  ##
    // ################

    function isDragger(Repo storage repo, uint256 dragger, IRegisterOfMembers _rom) 
        public view returns (bool) 
    {
        uint40 groupRep = _rom.groupRep(dragger);
        return repo.draggersList.contains(groupRep);
    }

    function getLinkRule(Repo storage repo, uint256 dragger, IRegisterOfMembers _rom) 
        public view draggerExist(repo, dragger, _rom)
        returns (RulesParser.LinkRule memory) 
    {
        uint40 groupRep = _rom.groupRep(dragger);
        return repo.links[groupRep].linkRule;
    }

    function isFollower(
        Repo storage repo, 
        uint256 dragger, 
        uint256 follower,
        IRegisterOfMembers _rom
    ) public view draggerExist(repo, dragger, _rom) 
        returns (bool) 
    {
        uint40 groupRep = _rom.groupRep(dragger);
        return repo.links[groupRep].followersList.contains(uint40(follower));
    }

    function getDraggers(Repo storage repo) public view returns (uint256[] memory) {
        return repo.draggersList.values();
    }

    function getFollowers(Repo storage repo, uint256 dragger, IRegisterOfMembers _rom) 
        public view draggerExist(repo, dragger, _rom) returns (uint256[] memory) 
    {
        uint40 groupRep = _rom.groupRep(dragger);
        return repo.links[groupRep].followersList.values();
    }

    function priceCheck(
        Repo storage repo,
        DealsRepo.Deal memory deal,
        IRegisterOfShares _ros,
        IRegisterOfMembers _rom
    ) public view returns (bool) {

        RulesParser.LinkRule memory lr = 
            getLinkRule(repo, deal.head.seller, _rom);

        if (lr.triggerType == uint8(TriggerTypeOfAlongs.ControlChangedWithHigherPrice)) 
            return (deal.head.priceOfPaid >= lr.rate);

        SharesRepo.Share memory share = 
            _ros.getShare(deal.head.seqOfShare);

        if (lr.triggerType == uint8(TriggerTypeOfAlongs.ControlChangedWithHigherROE))
            return (_roeOfDeal(
                deal.head.priceOfPaid, 
                share.head.priceOfPaid, 
                deal.head.closingDeadline, 
                share.head.issueDate) >= lr.rate);

        return true;
    }

    function _roeOfDeal(
        uint dealPrice,
        uint issuePrice,
        uint closingDeadline,
        uint issueDateOfShare
    ) private pure returns (uint roe) {
        require(dealPrice > issuePrice, "ROE: NEGATIVE selling price");
        require(closingDeadline > issueDateOfShare, "ROE: NEGATIVE holding period");

        roe = (dealPrice - issuePrice) * 10000 / issuePrice * 31536000 / (closingDeadline - issueDateOfShare);
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

library LockersRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Head {
        uint40 from;
        uint40 to;
        uint48 expireDate;
        uint128 value;
    }
    struct Body {
        address counterLocker;
        bytes payload;
    }
    struct Locker {
        Head head;
        Body body;
    }

    struct Repo {
        // hashLock => locker
        mapping (bytes32 => Locker) lockers;
        EnumerableSet.Bytes32Set snList;
    }

    //#################
    //##    Write    ##
    //#################

    function headSnParser(bytes32 sn) public pure returns (Head memory head) {
        uint _sn = uint(sn);
        
        head = Head({
            from: uint40(_sn >> 216),
            to: uint40(_sn >> 176),
            expireDate: uint48(_sn >> 128),
            value: uint128(_sn)
        });
    }

    function codifyHead(Head memory head) public pure returns (bytes32 headSn) {
        bytes memory _sn = abi.encodePacked(
                            head.from,
                            head.to,
                            head.expireDate,
                            head.value);
        assembly {
            headSn := mload(add(_sn, 0x20))
        }
    }

    function lockPoints(
        Repo storage repo,
        Head memory head,
        bytes32 hashLock
    ) public {
        Body memory body;
        lockConsideration(repo, head, body, hashLock);        
    }

    function lockConsideration(
        Repo storage repo,
        Head memory head,
        Body memory body,
        bytes32 hashLock
    ) public {       
        if (repo.snList.add(hashLock)) {            
            Locker storage locker = repo.lockers[hashLock];      
            locker.head = head;
            locker.body = body;
        } else revert ("LR.lockConsideration: occupied");
    }

    function pickupPoints(
        Repo storage repo,
        bytes32 hashLock,
        string memory hashKey,
        uint caller
    ) public returns(Head memory head) {
        
        bytes memory key = bytes(hashKey);

        require(hashLock == keccak256(key),
            "LR.pickupPoints: wrong key");

        Locker storage locker = repo.lockers[hashLock];

        require(block.timestamp < locker.head.expireDate, 
            "LR.pickupPoints: locker expired");

        bool flag = true;

        if (locker.body.counterLocker != address(0)) {
            require(locker.head.to == caller, 
                "LR.pickupPoints: wrong caller");

            uint len = key.length;
            bytes memory zero = new bytes(32 - (len % 32));

            bytes memory payload = abi.encodePacked(locker.body.payload, len, key, zero);
            (flag, ) = locker.body.counterLocker.call(payload);
        }

        if (flag) {
            head = locker.head;
            delete repo.lockers[hashLock];
            repo.snList.remove(hashLock);
        }
    }

    function withdrawDeposit(
        Repo storage repo,
        bytes32 hashLock,
        uint256 caller
    ) public returns(Head memory head) {

        Locker memory locker = repo.lockers[hashLock];

        require(block.timestamp >= locker.head.expireDate, 
            "LR.withdrawDeposit: locker not expired");

        require(locker.head.from == caller, 
            "LR.withdrawDeposit: wrong caller");

        if (repo.snList.remove(hashLock)) {
            head = locker.head;
            delete repo.lockers[hashLock];
        } else revert ("LR.withdrawDeposit: locker not exist");
    }

    //#################
    //##    Read     ##
    //#################

    function getHeadOfLocker(
        Repo storage repo,
        bytes32 hashLock
    ) public view returns (Head memory head) {
        return repo.lockers[hashLock].head;
    }

    function getLocker(
        Repo storage repo,
        bytes32 hashLock
    ) public view returns (Locker memory) {
        return repo.lockers[hashLock];
    }

    function getSnList(
        Repo storage repo
    ) public view returns (bytes32[] memory ) {
        return repo.snList.values();
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

import "./Checkpoints.sol";
import "./EnumerableSet.sol";
import "./SharesRepo.sol";
import "./TopChain.sol";

import "../comps/books/ros/IRegisterOfShares.sol";

library MembersRepo {
    using Checkpoints for Checkpoints.History;
    using EnumerableSet for EnumerableSet.UintSet;
    using TopChain for TopChain.Chain;

    struct Member {
        Checkpoints.History votesInHand;
        // class => seqList
        mapping(uint => EnumerableSet.UintSet) sharesOfClass;
        EnumerableSet.UintSet classesBelonged;
    }

    /*
        members[0] {
            votesInHand: ownersEquity;
        }
    */

    /* Node[0] {
        prev: tail;
        next: head;
        ptr: pending;
        amt: pending;
        sum: totalVotes;
        cat: basedOnPar;
    } */

    struct Repo {
        TopChain.Chain chain;
        mapping(uint256 => Member) members;
        // class => membersList
        mapping(uint => EnumerableSet.UintSet) membersOfClass;
    }

    //###############
    //##  Modifer  ##
    //###############

    modifier memberExist(
        Repo storage repo,
        uint acct
    ) {
        require(isMember(repo, acct),
            "MR.memberExist: not");
        _;
    }

    //##################
    //##  Write I/O  ##
    //##################

    // ==== Zero Node Setting ====

    function setVoteBase(
        Repo storage repo,
        IRegisterOfShares ros,
        bool _basedOnPar
    ) public returns (bool flag) {

        if (repo.chain.basedOnPar() != _basedOnPar) {
            uint256[] memory members = 
                repo.membersOfClass[0].values();
            uint256 len = members.length;

            while (len > 0) {
                uint256 cur = members[len - 1];

                Member storage m = repo.members[cur];

                Checkpoints.Checkpoint memory cp = 
                    m.votesInHand.latest();

                if (cp.paid != cp.par) {

                    (uint sumOfVotes, uint sumOfDistrs) = _sortWeights(m, ros, _basedOnPar);

                    if (_basedOnPar) {
                        repo.chain.increaseAmt(cur, sumOfVotes - cp.points, true);
                    } else {
                        repo.chain.increaseAmt(cur, cp.points - sumOfVotes, false);
                    }

                    uint64 amt = _basedOnPar ? cp.par : cp.paid;

                    cp.rate = uint16(sumOfVotes * 100 / amt);
                    m.votesInHand.push(cp.rate, cp.paid, cp.par, cp.points);

                    cp.rate = uint16(sumOfDistrs * 100 / amt);
                    cp.points = uint64(sumOfDistrs);
                    m.votesInHand.updateDistrPoints(cp.rate, cp.paid, cp.par, cp.points);
                }

                len--;
            }

            repo.chain.setVoteBase(_basedOnPar);

            flag = true;
        }
    }

    function _sortWeights(
        Member storage m,
        IRegisterOfShares ros,
        bool basedOnPar
    ) private view returns(uint sumOfVotes, uint sumOfDistrs) { 

        uint[] memory ls = m.sharesOfClass[0].values();
        uint len = ls.length;

        while (len > 0) {
            SharesRepo.Share memory share = ros.getShare(ls[len-1]);

            uint amt = basedOnPar ? share.body.par : share.body.paid;

            sumOfVotes += amt * share.head.votingWeight / 100;
            sumOfDistrs += amt * share.body.distrWeight / 100;

            len--;            
        }
    }

    // ==== Member ====

    function addMember(
        Repo storage repo, 
        uint acct
    ) public returns (bool flag) {
        if (repo.membersOfClass[0].add(acct)) {
            repo.chain.addNode(acct);
            flag = true;
        }
    }

    function delMember(
        Repo storage repo, 
        uint acct
    ) public {
        if (repo.membersOfClass[0].remove(acct)) {
            repo.chain.delNode(acct);
            delete repo.members[acct];
        }
    }

    function addShareToMember(
        Repo storage repo,
        SharesRepo.Head memory head
    ) public {

        Member storage member = repo.members[head.shareholder];

        if (member.sharesOfClass[0].add(head.seqOfShare)
            && member.sharesOfClass[head.class].add(head.seqOfShare)
            && member.classesBelonged.add(head.class))
                repo.membersOfClass[head.class].add(head.shareholder);
    }

    function removeShareFromMember(
        Repo storage repo,
        SharesRepo.Head memory head
    ) public {

        Member storage member = 
            repo.members[head.shareholder];
        
        if (member.sharesOfClass[head.class].remove(head.seqOfShare)
            && member.sharesOfClass[0].remove(head.seqOfShare)) {

            if(member.sharesOfClass[head.class].length() == 0) {
                repo.membersOfClass[head.class].remove(head.shareholder);
                member.classesBelonged.remove(head.class);
            }
        }

    }

    function increaseAmtOfMember(
        Repo storage repo,
        uint acct,
        uint votingWeight,
        uint distrWeight,
        uint deltaPaid,
        uint deltaPar,
        bool isIncrease
    ) public {
        _increaseAmtOfMember(repo, acct, votingWeight, distrWeight, deltaPaid, deltaPar, isIncrease);
    }

    function _increaseAmtOfMember(
        Repo storage repo,
        uint acct,
        uint votingWeight,
        uint distrWeight,
        uint deltaPaid,
        uint deltaPar,
        bool isIncrease
    ) private {

        Member storage m = repo.members[acct];
        bool basedOnPar = repo.chain.basedOnPar();
        uint64 deltaAmt =  basedOnPar ? uint64(deltaPar) : uint64(deltaPaid);

        Checkpoints.Checkpoint memory delta = Checkpoints.Checkpoint({
            timestamp: 0,
            rate: 0,
            paid: uint64(deltaPaid),
            par: uint64(deltaPar),
            points: uint64(deltaAmt * votingWeight / 100)
        });

        if (acct > 0 && deltaAmt > 0) {
            repo.chain.increaseAmt(
                acct, 
                delta.points,
                isIncrease
            );
        }

        Checkpoints.Checkpoint memory cp = 
            m.votesInHand.latest();

        cp = _adjustCheckpoint(cp, delta, basedOnPar, isIncrease);

        m.votesInHand.push(cp.rate, cp.paid, cp.par, cp.points);

        Checkpoints.Checkpoint memory dp = 
            m.votesInHand.getDistrPoints();
        
        delta.points = deltaAmt * uint16(distrWeight) / 100;

        dp = _adjustCheckpoint(dp, delta, basedOnPar, isIncrease);

        m.votesInHand.updateDistrPoints(dp.rate, dp.paid, dp.par, dp.points);
    }

    function _adjustCheckpoint(
        Checkpoints.Checkpoint memory cp,
        Checkpoints.Checkpoint memory delta,
        bool basedOnPar,
        bool isIncrease
    ) private pure returns (Checkpoints.Checkpoint memory output) {

        if (isIncrease) {
            output.paid = cp.paid + delta.paid;
            output.par = cp.par + delta.par;
            output.points = cp.points + delta.points;
        } else {
            output.paid = cp.paid - delta.paid;
            output.par = cp.par - delta.par;
            output.points = cp.points - delta.points;
        }

        output.rate = basedOnPar
            ?  output.par > 0 ? uint16(output.points * 100 / output.par) : 0
            :  output.paid > 0 ? uint16(output.points * 100 / output.paid) : 0;
    }

    // function _calWeight(
    //     Checkpoints.Checkpoint memory cp,
    //     bool basedOnPar,
    //     Checkpoints.Checkpoint memory delta,
    //     bool isIncrease
    // ) private pure returns(uint16 output) {
        
    //     if (isIncrease) {
    //         output = basedOnPar
    //             ? uint16(((cp.votingWeight * cp.par + delta.votingWeight * delta.par) * 100 / (cp.par + delta.par) + 50) / 100)
    //             : uint16(((cp.votingWeight * cp.paid + delta.votingWeight * delta.paid) * 100 / (cp.paid + delta.paid) + 50) / 100);
    //     } else {
    //         output = basedOnPar
    //             ? uint16(((cp.votingWeight * cp.par - delta.votingWeight * delta.par) * 100 / (cp.par - delta.par) + 50) / 100)
    //             : uint16(((cp.votingWeight * cp.paid - delta.votingWeight * delta.paid) * 100 / (cp.paid - delta.paid) + 50) / 100);
    //     }
    // }

    function increaseAmtOfCap(
        Repo storage repo,
        uint votingWeight,
        uint distrWeight,
        uint deltaPaid,
        uint deltaPar,
        bool isIncrease
    ) public {

        _increaseAmtOfMember(repo, 0, votingWeight, distrWeight, deltaPaid, deltaPar, isIncrease);
        
        bool basedOnPar = repo.chain.basedOnPar();

        if (basedOnPar && deltaPar > 0) {
            repo.chain.increaseTotalVotes(deltaPar * votingWeight / 100, isIncrease);
        } else if (!basedOnPar && deltaPaid > 0) {
            repo.chain.increaseTotalVotes(deltaPaid * votingWeight / 100, isIncrease);
        }
    }

    //##################
    //##    Read      ##
    //##################

    // ==== member ====

    function isMember(
        Repo storage repo,
        uint acct
    ) public view returns(bool) {
        return repo.membersOfClass[0].contains(acct);
    }
    
    function qtyOfMembers(
        Repo storage repo
    ) public view returns(uint) {
        return repo.membersOfClass[0].length();
    }

    function membersList(
        Repo storage repo
    ) public view returns(uint[] memory) {
        return repo.membersOfClass[0].values();
    }

    // ---- Votes ----

    function ownersEquity(
        Repo storage repo
    ) public view returns(Checkpoints.Checkpoint memory) {
        return repo.members[0].votesInHand.latest();
    }

    function ownersPoints(
        Repo storage repo
    ) public view returns(Checkpoints.Checkpoint memory) {
        return repo.members[0].votesInHand.getDistrPoints();
    }

    function capAtDate(
        Repo storage repo,
        uint date
    ) public view returns(Checkpoints.Checkpoint memory) {
        return repo.members[0].votesInHand.getAtDate(date);
    }

    function equityOfMember(
        Repo storage repo,
        uint acct
    ) public view memberExist(repo, acct) returns(
        Checkpoints.Checkpoint memory
    ) {
        return repo.members[acct].votesInHand.latest();
    }

    function pointsOfMember(
        Repo storage repo,
        uint acct
    ) public view memberExist(repo, acct) returns(
        Checkpoints.Checkpoint memory
    ) {
        return repo.members[acct].votesInHand.getDistrPoints();
    }

    function equityAtDate(
        Repo storage repo,
        uint acct,
        uint date
    ) public view memberExist(repo, acct) returns(
        Checkpoints.Checkpoint memory
    ) {
        return repo.members[acct].votesInHand.getAtDate(date);
    }

    function votesAtDate(
        Repo storage repo,
        uint256 acct,
        uint date
    ) public view returns (uint64) { 
        return repo.members[acct].votesInHand.getAtDate(date).points;
    }

    function votesHistory(
        Repo storage repo,
        uint acct
    ) public view memberExist(repo, acct) 
        returns (Checkpoints.Checkpoint[] memory) 
    {
        return repo.members[acct].votesInHand.pointsOfHistory();
    }

    // ---- Class ----

    function isClassMember(
        Repo storage repo, 
        uint256 acct, 
        uint class
    ) public view memberExist(repo, acct) returns (bool flag) {
        return repo.members[acct].classesBelonged.contains(class);
    }

    function classesBelonged(
        Repo storage repo, 
        uint256 acct
    ) public view memberExist(repo, acct) returns (uint[] memory) {
        return repo.members[acct].classesBelonged.values();
    }

    function qtyOfClassMember(
        Repo storage repo, 
        uint class
    ) public view returns(uint256) {
        return repo.membersOfClass[class].length();
    }

    function getMembersOfClass(
        Repo storage repo, 
        uint class
    ) public view returns(uint256[] memory) {
        return repo.membersOfClass[class].values();
    }

    // ---- Share ----

    function qtyOfSharesInHand(
        Repo storage repo, 
        uint acct
    ) public view memberExist(repo, acct) returns(uint) {
        return repo.members[acct].sharesOfClass[0].length();
    }

    function sharesInHand(
        Repo storage repo, 
        uint acct
    ) public view memberExist(repo, acct) returns(uint[] memory) {
        return repo.members[acct].sharesOfClass[0].values();
    }

    function qtyOfSharesInClass(
        Repo storage repo, 
        uint acct,
        uint class
    ) public view memberExist(repo, acct) returns(uint) {
        require(isClassMember(repo, acct, class), 
            "MR.qtyOfSharesInClass: not class member");
        return repo.members[acct].sharesOfClass[class].length();
    }

    function sharesInClass(
        Repo storage repo, 
        uint acct,
        uint class
    ) public view memberExist(repo, acct) returns(uint[] memory) {
        require(isClassMember(repo, acct, class),
            "MR.sharesInClass: not class member");
        return repo.members[acct].sharesOfClass[class].values();
    }

}

// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.4
 *
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

import "./BallotsBox.sol";
import "./DelegateMap.sol";
import "./EnumerableSet.sol";
import "./RulesParser.sol";

import "../comps/books/roc/IShareholdersAgreement.sol";

library MotionsRepo {
    using BallotsBox for BallotsBox.Box;
    using DelegateMap for DelegateMap.Map;
    using EnumerableSet for EnumerableSet.UintSet;
    using RulesParser for bytes32;

    enum TypeOfMotion {
        ZeroPoint,
        ElectOfficer,
        RemoveOfficer,
        ApproveDoc,
        ApproveAction,
        TransferFund,
        DistributeProfits,
        DeprecateGK
    }

    enum StateOfMotion {
        ZeroPoint,          // 0
        Created,            // 1
        Proposed,           // 2
        Passed,             // 3
        Rejected,           // 4
        Rejected_NotToBuy,  // 5
        Rejected_ToBuy,     // 6
        Executed            // 7
    }

    struct Head {
        uint16 typeOfMotion;
        uint64 seqOfMotion;
        uint16 seqOfVR;
        uint40 creator;
        uint40 executor;
        uint48 createDate;        
        uint32 data;
    }

    struct Body {
        uint40 proposer;
        uint48 proposeDate;
        uint48 shareRegDate;
        uint48 voteStartDate;
        uint48 voteEndDate;
        uint16 para;
        uint8 state;
    }

    struct Motion {
        Head head;
        Body body;
        RulesParser.VotingRule votingRule;
        uint contents;
    }

    struct Record {
        DelegateMap.Map map;
        BallotsBox.Box box;        
    }

    struct VoteCalBase {
        uint32 totalHead;
        uint64 totalWeight;
        uint32 supportHead;
        uint64 supportWeight;
        uint16 attendHeadRatio;
        uint16 attendWeightRatio;
        uint16 para;
        uint8 state;            
        bool unaniConsent;
    }

    struct Repo {
        mapping(uint256 => Motion) motions;
        mapping(uint256 => Record) records;
        EnumerableSet.UintSet seqList;
    }

    //#################
    //##  Write I/O  ##
    //#################

    // ==== snParser ====

    function snParser (bytes32 sn) public pure returns(Head memory head) {
        uint _sn = uint(sn);

        head = Head({
            typeOfMotion: uint16(_sn >> 240),
            seqOfMotion: uint64(_sn >> 176),
            seqOfVR: uint16(_sn >> 160),
            creator: uint40(_sn >> 120),
            executor: uint40(_sn >> 80),
            createDate: uint48(_sn >> 32),
            data: uint32(_sn)
        });
    }

    function codifyHead(Head memory head) public pure returns(bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            head.typeOfMotion,
                            head.seqOfMotion,
                            head.seqOfVR,
                            head.creator,
                            head.executor,
                            head.createDate,
                            head.data);  
        assembly {
            sn := mload(add(_sn, 0x20))
        }
    } 
    
    // ==== addMotion ====

    function addMotion(
        Repo storage repo,
        Head memory head,
        uint256 contents
    ) public returns (Head memory) {

        require(head.typeOfMotion > 0, "MR.CM: zero typeOfMotion");
        require(head.seqOfVR > 0, "MR.CM: zero seqOfVR");
        require(head.creator > 0, "MR.CM: zero caller");

        if (!repo.seqList.contains(head.seqOfMotion)) {
            head.seqOfMotion = _increaseCounterOfMotion(repo);
            head.createDate = uint48(block.timestamp);
            repo.seqList.add(head.seqOfMotion);
        }
    
        Motion storage m = repo.motions[head.seqOfMotion];

        m.head = head;
        m.contents = contents;
        m.body.state = uint8(StateOfMotion.Created);

        return head;
    } 

    function _increaseCounterOfMotion (Repo storage repo) private returns (uint64 seq) {
        repo.motions[0].head.seqOfMotion++;
        seq = repo.motions[0].head.seqOfMotion;
    }

    // ==== entrustDelegate ====

    function entrustDelegate(
        Repo storage repo,
        uint256 seqOfMotion,
        uint delegate,
        uint principal,
        IRegisterOfMembers _rom,
        IRegisterOfDirectors _rod
    ) public returns (bool flag) {
        Motion storage m = repo.motions[seqOfMotion];

        require(m.body.state == uint8(StateOfMotion.Created) ||
            m.body.state == uint8(StateOfMotion.Proposed) , 
            "MR.EntrustDelegate: wrong state");

        if (m.head.seqOfVR < 11 && _rom.isMember(delegate) && _rom.isMember(principal)) {
            uint64 weight;
            if (m.body.shareRegDate > 0 && block.timestamp >= m.body.shareRegDate) 
                weight = _rom.votesAtDate(principal, m.body.shareRegDate);    
            return repo.records[seqOfMotion].map.entrustDelegate(principal, delegate, weight);
        } else if (_rod.isDirector(delegate) && _rod.isDirector(principal)) {
            return repo.records[seqOfMotion].map.entrustDelegate(principal, delegate, 0);
        } else revert ("MR.entrustDelegate: not both Members or Directors");        
    }

    // ==== propose ====

    function proposeMotionToGeneralMeeting(
        Repo storage repo,
        uint256 seqOfMotion,
        IShareholdersAgreement _sha,
        IRegisterOfMembers _rom,
        IRegisterOfDirectors _rod,
        uint caller
    ) public {

        RulesParser.GovernanceRule memory gr =
            _sha.getRule(0).governanceRuleParser();

        require(_memberProposalRightCheck(repo, seqOfMotion, gr, caller, _rom) ||
            _directorProposalRightCheck(repo, seqOfMotion, caller, gr.proposeHeadRatioOfDirectorsInGM, _rod),
            "MR.PMTGM: has no proposalRight");

        _proposeMotion(repo, seqOfMotion, _sha, caller);
    } 

    function _proposeMotion(
        Repo storage repo,
        uint seqOfMotion,
        IShareholdersAgreement _sha,
        uint caller
    ) private {

        require(caller > 0, "MR.PM: zero caller");

        require(repo.records[seqOfMotion].map.voters[caller].delegate == 0,
            "MR.PM: entrused delegate");

        Motion storage m = repo.motions[seqOfMotion];
        require(m.body.state == uint8(StateOfMotion.Created), 
            "MR.PM: wrong state");

        RulesParser.VotingRule memory vr = 
            _sha.getRule(m.head.seqOfVR).votingRuleParser();

        uint48 timestamp = uint48(block.timestamp);

        Body memory body = Body({
            proposer: uint40(caller),
            proposeDate: timestamp,
            shareRegDate: timestamp + uint48(vr.invExitDays) * 86400,
            voteStartDate: timestamp + uint48(vr.invExitDays + vr.votePrepareDays) * 86400,
            voteEndDate: timestamp + uint48(vr.invExitDays + vr.votePrepareDays + vr.votingDays) * 86400,
            para: 0,
            state: uint8(StateOfMotion.Proposed)
        });

        m.body = body;
        m.votingRule = vr;
    }

    function _memberProposalRightCheck(
        Repo storage repo,
        uint seqOfMotion,
        RulesParser.GovernanceRule memory gr,
        uint caller,
        IRegisterOfMembers _rom
    ) private returns(bool) {
        if (!_rom.isMember(caller)) return false;

        Motion memory motion = repo.motions[seqOfMotion];
        if (motion.head.typeOfMotion == uint8(TypeOfMotion.ApproveDoc) ||
            motion.head.typeOfMotion == uint8(TypeOfMotion.ElectOfficer))
            return true;

        uint totalVotes = _rom.totalVotes();

        if (gr.proposeWeightRatioOfGM > 0 &&
            _rom.votesInHand(caller) * 10000 / totalVotes >= gr.proposeWeightRatioOfGM)
                return true;

        Record storage r = repo.records[seqOfMotion];
        r.map.updateLeavesWeightAtDate(caller, uint48(block.timestamp), _rom);

        DelegateMap.Voter memory voter = r.map.voters[caller];


        if (gr.proposeWeightRatioOfGM > 0 && 
            (voter.weight + voter.repWeight) * 10000 / totalVotes >= gr.proposeWeightRatioOfGM)
                return true;

        if (gr.proposeHeadRatioOfMembers > 0 &&
            (voter.repHead + 1) * 10000 / _rom.qtyOfMembers() >= 
                gr.proposeHeadRatioOfMembers)
                    return true;
        
        return false;
    }

    function _directorProposalRightCheck(
        Repo storage repo,
        uint seqOfMotion,
        uint caller,
        uint16 proposalThreshold,
        IRegisterOfDirectors _rod
    ) private returns (bool) {
        if (!_rod.isDirector(caller)) return false;

        uint totalHead = _rod.getNumOfDirectors();
        repo.records[seqOfMotion].map.updateLeavesHeadcountOfDirectors(caller, _rod);

        if (proposalThreshold > 0 &&
            (repo.records[seqOfMotion].map.voters[caller].repHead + 1) * 10000 / totalHead >=
                proposalThreshold)
                    return true;

        return false;
    } 

    function proposeMotionToBoard(
        Repo storage repo,
        uint256 seqOfMotion,
        IShareholdersAgreement _sha,
        IRegisterOfDirectors _rod,
        uint caller
    ) public {

        RulesParser.GovernanceRule memory gr = 
            _sha.getRule(0).governanceRuleParser();

        require(
            _directorProposalRightCheck(
                repo, seqOfMotion, caller, 
                gr.proposeHeadRatioOfDirectorsInBoard, 
                _rod
            ),
            "MR.PMTB: has no proposalRight");

        _proposeMotion(repo, seqOfMotion, _sha, caller);
    } 

    // ==== vote ====

    function castVoteInGeneralMeeting(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 acct,
        uint attitude,
        bytes32 sigHash,
        IRegisterOfMembers _rom
    ) public {

        require(_rom.isMember(acct), "MR.castVoteInGM: not Member");

        Motion storage m = repo.motions[seqOfMotion];
        Record storage r = repo.records[seqOfMotion];
        DelegateMap.Voter storage voter = r.map.voters[acct];

        r.map.updateLeavesWeightAtDate(acct, m.body.shareRegDate, _rom);

        _castVote(repo, seqOfMotion, acct, attitude, voter.repHead + 1, voter.weight + voter.repWeight, sigHash);
    }

    function castVoteInBoardMeeting(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 acct,
        uint attitude,
        bytes32 sigHash,
        IRegisterOfDirectors _rod
    ) public {
        require(_rod.isDirector(acct), "MR.CVBM: not Director");

        Record storage r = repo.records[seqOfMotion];

        DelegateMap.Voter storage voter = r.map.voters[acct];

        r.map.updateLeavesHeadcountOfDirectors(acct, _rod);

        _castVote(repo, seqOfMotion, acct, attitude, voter.repHead + 1, 0, sigHash);
    }

    function _castVote(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 acct,
        uint attitude,
        uint headcount,
        uint weight,
        bytes32 sigHash
    ) private {
        require(seqOfMotion > 0, "MR.CV: zero seqOfMotion");
        require(voteStarted(repo, seqOfMotion), "MR.CV: vote not started");
        require(!voteEnded(repo, seqOfMotion), "MR.CV: vote is Ended");

        Record storage r = repo.records[seqOfMotion];
        DelegateMap.Voter storage voter = r.map.voters[acct];

        require(voter.delegate == 0, 
            "MR.CV: entrusted delegate");

        r.box.castVote(acct, attitude, headcount, weight, sigHash, voter.principals);
    }


    // ==== counting ====

    function voteCounting(
        Repo storage repo,
        bool flag0,
        uint256 seqOfMotion,
        VoteCalBase memory base
    ) public returns (uint8) {

        Motion storage m = repo.motions[seqOfMotion];
        Record storage r = repo.records[seqOfMotion];

        require (m.body.state == uint8(StateOfMotion.Proposed) , "MR.VT: wrong state");
        require (voteEnded(repo, seqOfMotion), "MR.VT: vote not ended yet");

        bool flag1 = m.votingRule.headRatio == 0;
        bool flag2 = m.votingRule.amountRatio == 0;

        bool flag = (flag1 && flag2);

        if (!flag && flag0 && !_isVetoed(r, m.votingRule.vetoers[0]) &&
            !_isVetoed(r, m.votingRule.vetoers[1])) {
            flag1 = flag1 ? true : base.totalHead > 0
                ? ((r.box.cases[uint8(BallotsBox.AttitudeOfVote.Support)]
                    .sumOfHead + base.supportHead) * 10000) /
                    base.totalHead >
                    m.votingRule.headRatio
                : base.unaniConsent 
                    ? true
                    : false;

            flag2 = flag2 ? true : base.totalWeight > 0
                ? ((r.box.cases[uint8(BallotsBox.AttitudeOfVote.Support)]
                    .sumOfWeight + base.supportWeight) * 10000) /
                    base.totalWeight >
                    m.votingRule.amountRatio
                : base.unaniConsent
                    ? true
                    : false;
        }

        m.body.state =  flag || (flag0 && flag1 && flag2) 
                ? uint8(MotionsRepo.StateOfMotion.Passed) 
                : m.votingRule.againstShallBuy 
                    ? uint8(MotionsRepo.StateOfMotion.Rejected_ToBuy)
                    : uint8(MotionsRepo.StateOfMotion.Rejected_NotToBuy);

        return m.body.state;
    }

    function _isVetoed(Record storage r, uint256 vetoer)
        private
        view
        returns (bool)
    {
        return vetoer > 0 && (r.box.ballots[vetoer].sigDate == 0 ||
            r.box.ballots[vetoer].attitude != uint8(BallotsBox.AttitudeOfVote.Support));
    }

    // ==== ExecResolution ====

    function execResolution(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 contents,
        uint executor
    ) public {
        Motion storage m = repo.motions[seqOfMotion];
        require (m.contents == contents, 
            "MR.execResolution: wrong contents");
        require (m.body.state == uint8(StateOfMotion.Passed), 
            "MR.execResolution: wrong state");
        require (m.head.executor == uint40(executor), "MR.ER: not executor");

        m.body.state = uint8(StateOfMotion.Executed);
    }
    
    //#################
    //##    Read     ##
    //#################

    // ==== VoteState ====

    function isProposed(Repo storage repo, uint256 seqOfMotion)
        public view returns (bool)
    {
        return repo.motions[seqOfMotion].body.state == uint8(StateOfMotion.Proposed);
    }

    function voteStarted(Repo storage repo, uint256 seqOfMotion)
        public view returns (bool)
    {
        return isProposed(repo, seqOfMotion) && 
            repo.motions[seqOfMotion].body.voteStartDate <= block.timestamp;
    }

    function voteEnded(Repo storage repo, uint256 seqOfMotion)
        public view returns (bool)
    {
        return isProposed(repo, seqOfMotion) && 
            repo.motions[seqOfMotion].body.voteEndDate <= block.timestamp;
    }

    // ==== Delegate ====

    function getVoterOfDelegateMap(Repo storage repo, uint256 seqOfMotion, uint256 acct)
        public view returns (DelegateMap.Voter memory)
    {
        return repo.records[seqOfMotion].map.voters[acct];
    }

    function getDelegateOf(Repo storage repo, uint256 seqOfMotion, uint acct)
        public view returns (uint)
    {
        return repo.records[seqOfMotion].map.getDelegateOf(acct);
    }

    // ==== motion ====

    function getMotion(Repo storage repo, uint256 seqOfMotion)
        public view returns (Motion memory motion)
    {
        motion = repo.motions[seqOfMotion];
    }

    // ==== voting ====

    function isVoted(Repo storage repo, uint256 seqOfMotion, uint256 acct) 
        public view returns (bool) 
    {
        return repo.records[seqOfMotion].box.isVoted(acct);
    }

    function isVotedFor(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 acct,
        uint256 atti
    ) public view returns (bool) {
        return repo.records[seqOfMotion].box.isVotedFor(acct, atti);
    }

    function getCaseOfAttitude(Repo storage repo, uint256 seqOfMotion, uint256 atti)
        public view returns (BallotsBox.Case memory )
    {
        return repo.records[seqOfMotion].box.getCaseOfAttitude(atti);
    }

    function getBallot(Repo storage repo, uint256 seqOfMotion, uint256 acct)
        public view returns (BallotsBox.Ballot memory)
    {
        return repo.records[seqOfMotion].box.getBallot(acct);
    }

    function isPassed(Repo storage repo, uint256 seqOfMotion) public view returns (bool) {
        return repo.motions[seqOfMotion].body.state == uint8(MotionsRepo.StateOfMotion.Passed);
    }

    // ==== snList ====

    function getSeqList(Repo storage repo) public view returns (uint[] memory) {
        return repo.seqList.values();
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
import "../comps/books/rom/IRegisterOfMembers.sol";

library OfficersRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;

    enum TitleOfOfficers {
        ZeroPoint,
        Shareholder,
        Chairman,
        ViceChairman,
        ManagingDirector,
        Director,
        CEO,
        CFO,
        COO,
        CTO,
        President,
        VicePresident,
        Supervisor,
        SeniorManager,
        Manager,
        ViceManager      
    }

    struct Position {
        uint16 title;
        uint16 seqOfPos;
        uint40 acct;
        uint40 nominator;
        uint48 startDate;
        uint48 endDate;
        uint16 seqOfVR;
        uint16 titleOfNominator;
        uint16 argu;
    }

    struct Group {
        // seqList
        EnumerableSet.UintSet posList;
        // acctList
        EnumerableSet.UintSet acctList;
    }

    struct Repo {
        //seqOfPos => Position
        mapping(uint => Position)  positions;
        // acct => seqOfPos
        mapping(uint => EnumerableSet.UintSet) posInHand;
        Group directors;
        Group managers;
    }

    //#################
    //##   Modifier  ##
    //#################

    modifier isVacant(Repo storage repo, uint256 seqOfPos) {
        require(!isOccupied(repo, seqOfPos), 
            "OR.mf.IV: position occupied");
        _;
    }

    //#################
    //##    Write    ##
    //#################

    // ==== snParser ====

    function snParser(bytes32 sn) public pure returns (Position memory position) {
        uint _sn = uint(sn);

        position = Position({
            title: uint16(_sn >> 240),
            seqOfPos: uint16(_sn >> 224),
            acct: uint40(_sn >> 184),
            nominator: uint40(_sn >> 144),
            startDate: uint48(_sn >> 96),
            endDate: uint48(_sn >> 48),
            seqOfVR: uint16(_sn >> 32),
            titleOfNominator: uint16(_sn >> 16),
            argu: uint16(_sn)
        });
    }

    function codifyPosition(Position memory position) public pure returns (bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            position.title,
                            position.seqOfPos,
                            position.acct,
                            position.nominator,
                            position.startDate,
                            position.endDate,
                            position.seqOfVR,
                            position.titleOfNominator,
                            position.argu);  
        assembly {
            sn := mload(add(_sn, 0x20))
        }                
    }

    // ======== Setting ========

    function createPosition (Repo storage repo, bytes32 snOfPos) 
        public 
    {
        Position memory pos = snParser(snOfPos);
        addPosition(repo, pos);
    }

    function addPosition(
        Repo storage repo,
        Position memory pos
    ) public {
        require (pos.title > uint8(TitleOfOfficers.Shareholder), "OR.addPosition: title overflow");
        require (pos.seqOfPos > 0, "OR.addPosition: zero seqOfPos");
        require (pos.titleOfNominator > 0, "OR.addPosition: zero titleOfNominator");
        require (pos.endDate > pos.startDate, "OR.addPosition: endDate <= startDate");
        require (pos.endDate > block.timestamp, "OR.addPosition: endDate not future");

        Position storage p = repo.positions[pos.seqOfPos];
        
        if (p.seqOfPos == 0) {
            if (pos.title <= uint8(TitleOfOfficers.Director)) 
                repo.directors.posList.add(pos.seqOfPos);
            else repo.managers.posList.add(pos.seqOfPos); 
        } else require (p.seqOfPos == pos.seqOfPos && p.title == pos.title,
            "OR.addPosition: remove pos first");

        repo.positions[pos.seqOfPos] = pos;
    }

    function removePosition(Repo storage repo, uint256 seqOfPos) 
        public isVacant(repo, seqOfPos) returns (bool flag)
    {
        if (repo.directors.posList.remove(seqOfPos) ||
            repo.managers.posList.remove(seqOfPos)) 
        {
            delete repo.positions[seqOfPos];
            flag = true;
        }
    }

    function takePosition (
        Repo storage repo,
        uint256 seqOfPos,
        uint acct
    ) public returns (bool flag) {
        require (seqOfPos > 0, "OR.takePosition: zero seqOfPos");
        require (acct > 0, "OR.takePosition: zero acct");
        
        Position storage pos = repo.positions[seqOfPos];

        if (repo.directors.posList.contains(seqOfPos))
            repo.directors.acctList.add(acct);
        else if (repo.managers.posList.contains(seqOfPos))
            repo.managers.acctList.add(acct);
        else revert("OR.takePosition: pos not exist");

        pos.acct = uint40(acct);
        pos.startDate = uint48(block.timestamp);

        repo.posInHand[acct].add(seqOfPos);

        flag = true;
    }

    function quitPosition(
        Repo storage repo, 
        uint256 seqOfPos,
        uint acct
    ) public returns (bool flag)
    {
        Position memory pos = repo.positions[seqOfPos];
        require(acct == pos.acct, 
            "OR.quitPosition: not the officer");
        flag = vacatePosition(repo, seqOfPos);
    }

    function vacatePosition (
        Repo storage repo,
        uint seqOfPos
    ) public returns (bool flag)
    {
        Position storage pos = repo.positions[seqOfPos];

        uint acct = pos.acct;
        require (acct > 0, "OR.vacatePosition: empty pos");

        if (repo.posInHand[acct].remove(seqOfPos)) {
            pos.acct = 0;

            if (pos.title <= uint8(TitleOfOfficers.Director))
                repo.directors.acctList.remove(acct);
            else if (repo.posInHand[acct].length() == 0) {
                repo.managers.acctList.remove(acct);
            }
                
            flag = true;
        }        
    }

    //################
    //##    Read    ##
    //################

    // ==== Positions ====

    function posExist(Repo storage repo, uint256 seqOfPos) public view returns (bool flag) {
        flag = repo.positions[seqOfPos].endDate > block.timestamp;
    } 

    function isOccupied(Repo storage repo, uint256 seqOfPos) public view returns (bool flag) {
        flag = repo.positions[seqOfPos].acct > 0;
    }

    function getPosition(Repo storage repo, uint256 seqOfPos) public view returns (Position memory pos) {
        pos = repo.positions[seqOfPos];
    }

    function getFullPosInfo(Repo storage repo, uint[] memory pl) 
        public view returns(Position[] memory) 
    {
        uint256 len = pl.length;
        Position[] memory ls = new Position[](len);

        while (len > 0) {
            ls[len-1] = repo.positions[pl[len-1]];
            len--;
        }

        return ls;        
    }

    // ==== Managers ====

    function isManager(Repo storage repo, uint256 acct) public view returns (bool flag) {
        flag = repo.managers.acctList.contains(acct);
    }

    function getNumOfManagers(Repo storage repo) public view returns (uint256 num) {
        num = repo.managers.acctList.length();
    }

    function getManagersList(Repo storage repo) public view returns (uint256[] memory ls) {
        ls = repo.managers.acctList.values();
    }

    function getManagersPosList(Repo storage repo) public view returns(uint[] memory list) {
        list = repo.managers.posList.values();
    }

    function getManagersFullPosInfo(Repo storage repo) public view 
        returns(Position[] memory output) 
    {
        uint[] memory pl = repo.managers.posList.values();
        output = getFullPosInfo(repo, pl);
    }

    // ==== Directors ====

    function isDirector(Repo storage repo, uint256 acct) 
        public view returns (bool flag) 
    {
        flag = repo.directors.acctList.contains(acct);
    }

    function getNumOfDirectors(Repo storage repo) public view 
        returns (uint256 num) 
    {
        num = repo.directors.acctList.length();
    }

    function getDirectorsList(Repo storage repo) public view 
        returns (uint256[] memory ls) 
    {
        ls = repo.directors.acctList.values();
    }

    function getDirectorsPosList(Repo storage repo) public view 
        returns (uint256[] memory ls) 
    {
        ls = repo.directors.posList.values();
    }

    function getDirectorsFullPosInfo(Repo storage repo) public view 
        returns(Position[] memory output) 
    {
        uint[] memory pl = repo.directors.posList.values();
        output = getFullPosInfo(repo, pl);
    }

    // ==== Executives ====

    function hasPosition(Repo storage repo, uint256 acct, uint256 seqOfPos) 
        public view returns (bool flag) 
    {
        flag = repo.posInHand[acct].contains(seqOfPos);
    }

    function getPosInHand(Repo storage repo, uint256 acct) 
        public view returns (uint256[] memory ls) 
    {
        ls = repo.posInHand[acct].values();
    }

    function getFullPosInfoInHand(Repo storage repo, uint acct) 
        public view returns (Position[] memory output) 
    {
        uint256[] memory pl = repo.posInHand[acct].values();
        output = getFullPosInfo(repo, pl);
    }

    function hasTitle(Repo storage repo, uint acct, uint title, IRegisterOfMembers _rom)
        public view returns (bool)
    {
        if (title == uint8(TitleOfOfficers.Shareholder))
            return _rom.isMember(acct);

        if (title == uint8(TitleOfOfficers.Director))
            return isDirector(repo, acct);
        
        Position[] memory list = getFullPosInfoInHand(repo, acct);
        uint len = list.length;
        while (len > 0) {
            if (list[len-1].title == uint16(title))
                return true;
            len --;
        }
        return false;
    }

    function hasNominationRight(Repo storage repo, uint seqOfPos, uint acct, IRegisterOfMembers _rom)
        public view returns (bool)
    {
        Position memory pos = repo.positions[seqOfPos];
        if (pos.endDate <= block.timestamp) return false;
        else if (pos.nominator == 0)
            return hasTitle(repo, acct, pos.titleOfNominator, _rom);
        else return (pos.nominator == acct);
    }

    // ==== seatsCalculator ====

    function getBoardSeatsQuota(Repo storage repo, uint256 acct) public view 
        returns (uint256 quota)
    {
        uint[] memory pl = repo.directors.posList.values();
        uint256 len = pl.length;
        while (len > 0) {
            Position memory pos = repo.positions[pl[len-1]];
            if (pos.nominator == acct) quota++;
            len--;
        }       
    }

    function getBoardSeatsOccupied(Repo storage repo, uint acct) public view 
        returns (uint256 num)
    {
        uint256[] memory dl = repo.directors.acctList.values();
        uint256 lenOfDL = dl.length;

        while (lenOfDL > 0) {
            uint256[] memory pl = repo.posInHand[dl[lenOfDL-1]].values();
            uint256 lenOfPL = pl.length;

            while(lenOfPL > 0) {
                Position memory pos = repo.positions[pl[lenOfPL-1]];
                if ( pos.title <= uint8(TitleOfOfficers.Director)) { 
                    if (pos.nominator == acct) num++;
                    break;
                }
                lenOfPL--;
            }

            lenOfDL--;
        }
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

library SharesRepo {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Head {
        uint16 class; 
        uint32 seqOfShare; 
        uint32 preSeq; 
        uint48 issueDate; 
        uint40 shareholder; 
        uint32 priceOfPaid; 
        uint32 priceOfPar; 
        uint16 votingWeight; 
        uint8 argu;
    }

    struct Body {
        uint48 payInDeadline; 
        uint64 paid;
        uint64 par; 
        uint64 cleanPaid; 
        uint16 distrWeight;
    }

    struct Share {
        Head head;
        Body body;
    }

    struct Class{
        Share info;
        EnumerableSet.UintSet seqList;
    }

    struct Repo {
        // seqOfClass => Class
        mapping(uint256 => Class) classes;
        // seqOfShare => Share
        mapping(uint => Share) shares;
    }

    //####################
    //##    Modifier    ##
    //####################

    modifier shareExist(
        Repo storage repo,
        uint seqOfShare
    ) {
        require(isShare(repo, seqOfShare),
            "SR.shareExist: not");
        _;
    }

    //#################
    //##    Write    ##
    //#################

    function snParser(bytes32 sn) public pure returns(Head memory head)
    {
        uint _sn = uint(sn);
        
        head = Head({
            class: uint16(_sn >> 240),
            seqOfShare: uint32(_sn >> 208),
            preSeq: uint32(_sn >> 176),
            issueDate: uint48(_sn >> 128),
            shareholder: uint40(_sn >> 88),
            priceOfPaid: uint32(_sn >> 56),
            priceOfPar: uint32(_sn >> 24),
            votingWeight: uint16(_sn >> 8),
            argu: uint8(_sn)
        });
    }

    function codifyHead(Head memory head) public pure returns (bytes32 sn)
    {
        bytes memory _sn = 
            abi.encodePacked(
                head.class, 
                head.seqOfShare, 
                head.preSeq, 
                head.issueDate, 
                head.shareholder, 
                head.priceOfPaid, 
                head.priceOfPar, 
                head.votingWeight, 
                head.argu
            );

        assembly {
            sn := mload(add(_sn, 0x20))
        }

    }

    // ==== issue/regist share ====

    function createShare(
        bytes32 sharenumber, 
        uint payInDeadline, 
        uint paid, 
        uint par,
        uint distrWeight
    ) public pure returns (Share memory share) {

        share.head = snParser(sharenumber);

        share.body = Body({
            payInDeadline: uint48(payInDeadline),
            paid: uint64(paid),
            par: uint64(par),
            cleanPaid: uint64(paid),
            distrWeight: uint16(distrWeight)
        });
    }

    function addShare(Repo storage repo, Share memory share)
        public returns(Share memory newShare) 
    {
        newShare = regShare(repo, share);

        Share storage info = repo.classes[newShare.head.class].info;

        if (info.head.issueDate == 0) 
            repo.classes[newShare.head.class].info.head = 
                newShare.head;
    }

    function regShare(Repo storage repo, Share memory share)
        public returns(Share memory)
    {
        require(share.head.class > 0, "SR.regShare: zero class");
        require(share.body.par > 0, "SR.regShare: zero par");
        require(share.body.par >= share.body.paid, "SR.regShare: paid overflow");
        require(share.head.issueDate <= block.timestamp, "SR.regShare: future issueDate");
        require(share.head.issueDate <= share.body.payInDeadline, "SR.regShare: issueDate later than payInDeadline");
        require(share.head.shareholder > 0, "SR.regShare: zero shareholder");
        require(share.head.votingWeight > 0, "SR.regShare: zero votingWeight");

        if (share.head.class > counterOfClasses(repo))
            share.head.class = _increaseCounterOfClasses(repo);

        Class storage class = repo.classes[share.head.class];

        if (!class.seqList.contains(share.head.seqOfShare)) {
            share.head.seqOfShare = _increaseCounterOfShares(repo);
                        
            if (share.head.issueDate == 0)
                share.head.issueDate = uint48(block.timestamp);

            class.seqList.add(share.head.seqOfShare);
            repo.classes[0].seqList.add(share.head.seqOfShare);
        }

        repo.shares[share.head.seqOfShare] = share;

        return share;
    }

    // ==== counters ====

    function _increaseCounterOfShares(
        Repo storage repo
    ) private returns(uint32) {

        Head storage h = repo.shares[0].head;

        do {
            unchecked {
                h.seqOfShare++;                
            }
        } while (isShare(repo, h.seqOfShare) || 
            h.seqOfShare == 0);

        return h.seqOfShare;
    }

    function _increaseCounterOfClasses(Repo storage repo) 
        private returns(uint16)
    {
        repo.shares[0].head.class++;
        return repo.shares[0].head.class;
    }

    // ==== amountChange ====

    function payInCapital(
        Repo storage repo,
        uint seqOfShare,
        uint amt
    ) public shareExist(repo, seqOfShare) {

        Share storage share = repo.shares[seqOfShare];

        uint64 deltaPaid = uint64(amt);

        require(deltaPaid > 0, "SR.payInCap: zero amt");

        require(block.timestamp <= share.body.payInDeadline, 
            "SR.payInCap: missed deadline");

        require(share.body.paid + deltaPaid <= share.body.par, 
            "SR.payInCap: amt overflow");

        share.body.paid += deltaPaid;
        share.body.cleanPaid += deltaPaid;

    }

    function subAmtFromShare(
        Repo storage repo,
        uint seqOfShare,
        uint paid, 
        uint par
    ) public shareExist(repo, seqOfShare) {

        Share storage share = repo.shares[seqOfShare];
        Class storage class = repo.classes[share.head.class];

        uint64 deltaPaid = uint64(paid);
        uint64 deltaPar = uint64(par);

        require(deltaPar > 0, "SR.subAmt: zero par");
        require(share.body.cleanPaid >= deltaPaid, "SR.subAmt: insufficient cleanPaid");

        if (deltaPar == share.body.par) {            
            class.seqList.remove(seqOfShare);
            repo.classes[0].seqList.remove(seqOfShare);
            delete repo.shares[seqOfShare];
        } else {
            share.body.paid -= deltaPaid;
            share.body.par -= deltaPar;
            share.body.cleanPaid -= deltaPaid;

            require(share.body.par >= share.body.paid,
                "SR.subAmt: result paid overflow");
        }
    }

    function increaseCleanPaid(
        Repo storage repo,
        bool isIncrease,
        uint seqOfShare,
        uint paid
    ) public shareExist(repo, seqOfShare) {

        Share storage share = repo.shares[seqOfShare];

        uint64 deltaClean = uint64(paid);

        require(deltaClean > 0, "SR.incrClean: zero amt");

        if (isIncrease && share.body.cleanPaid + deltaClean <= share.body.paid) 
            share.body.cleanPaid += deltaClean;
        else if(!isIncrease && share.body.cleanPaid >= deltaClean)
            share.body.cleanPaid -= deltaClean;
        else revert("SR.incrClean: clean overflow");
    }

    // ---- EquityOfClass ----

    function increaseEquityOfClass(
        Repo storage repo,
        bool isIncrease,
        uint classOfShare,
        uint deltaPaid,
        uint deltaPar,
        uint deltaCleanPaid
    ) public {

        Body storage equity = repo.classes[classOfShare].info.body;

        if (isIncrease) {
            equity.paid += uint64(deltaPaid);
            equity.par += uint64(deltaPar);
            equity.cleanPaid += uint64(deltaCleanPaid);
        } else {
            equity.paid -= uint64(deltaPaid);
            equity.par -= uint64(deltaPar);
            equity.cleanPaid -= uint64(deltaCleanPaid);            
        }
    }

    function updatePriceOfPaid(
        Repo storage repo,
        uint seqOfShare,
        uint newPrice
    ) public shareExist(repo, seqOfShare) {
        Share storage share = repo.shares[seqOfShare];
        share.head.priceOfPaid = uint32(newPrice);
    }

    function updatePayInDeadline(
        Repo storage repo,
        uint seqOfShare,
        uint deadline
    ) public shareExist(repo, seqOfShare) {

        Share storage share = repo.shares[seqOfShare];

        uint48 newLine = uint48(deadline);

        require (block.timestamp < newLine, 
            "SR.updatePayInDeadline: not future");

        share.body.payInDeadline = newLine;
    }

    //####################
    //##    Read I/O    ##
    //####################

    // ---- Counter ----

    function counterOfShares(
        Repo storage repo
    ) public view returns(uint32) {
        return repo.shares[0].head.seqOfShare;
    }

    function counterOfClasses(
        Repo storage repo
    ) public view returns(uint16) {
        return repo.shares[0].head.class;
    }

    // ---- Share ----

    function isShare(
        Repo storage repo, 
        uint seqOfShare
    ) public view returns(bool) {
        return repo.shares[seqOfShare].head.issueDate > 0;
    }

    function getShare(
        Repo storage repo, 
        uint seqOfShare
    ) public view shareExist(repo, seqOfShare) returns (
        Share memory
    ) {
        return repo.shares[seqOfShare];
    }

    function getQtyOfShares(
        Repo storage repo
    ) public view returns(uint) {
        return repo.classes[0].seqList.length();
    }

    function getSeqListOfShares(
        Repo storage repo
    ) public view returns(uint[] memory) {
        return repo.classes[0].seqList.values();
    }

    function getSharesList(
        Repo storage repo
    ) public view returns(Share[] memory) {
        uint[] memory seqList = repo.classes[0].seqList.values();
        return _getShares(repo, seqList);
    }

    // ---- Class ----    

    function getQtyOfSharesInClass(
        Repo storage repo, 
        uint classOfShare
    ) public view returns (uint) {
        return repo.classes[classOfShare].seqList.length();
    }

    function getSeqListOfClass(
        Repo storage repo, 
        uint classOfShare
    ) public view returns (uint[] memory) {
        return repo.classes[classOfShare].seqList.values();
    }

    function getInfoOfClass(
        Repo storage repo,
        uint classOfShare
    ) public view returns (Share memory) {
        return repo.classes[classOfShare].info;
    }

    function getSharesOfClass(
        Repo storage repo, 
        uint classOfShare
    ) public view returns (Share[] memory) {
        uint[] memory seqList = 
            repo.classes[classOfShare].seqList.values();
        return _getShares(repo, seqList);
    }

    function _getShares(
        Repo storage repo,
        uint[] memory seqList
    ) private view returns(Share[] memory list) {

        uint len = seqList.length;
        list = new Share[](len);

        while(len > 0) {
            list[len - 1] = repo.shares[seqList[len - 1]];
            len--;
        }
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

library SigsRepo {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Signature {
        uint40 signer;
        uint48 sigDate;
        uint64 blocknumber;
        bool flag;
        uint16 para;
        uint16 arg;
        uint16 seq;
        uint16 attr;
        uint32 data;
    }

    struct Blank{
        EnumerableSet.UintSet seqOfDeals;
        Signature sig;
        bytes32 sigHash;
    }

    // blanks[0].sig {
    //     sigDate: circulateDate;
    //     flag: established;
    //     para: counterOfBlanks;
    //     arg: counterOfSigs;
    //     seq: signingDays;
    //     attr: closingDays;
    // }

    struct Page {
        // party => Blank
        mapping(uint256 => Blank) blanks;
        EnumerableSet.UintSet buyers;
        EnumerableSet.UintSet sellers;
    }

    //###################
    //##    设置接口    ##
    //###################

    function circulateDoc(
        Page storage p
    ) public {
        p.blanks[0].sig.sigDate = uint48(block.timestamp);
    }

    function setTiming(
        Page storage p,
        uint signingDays,
        uint closingDays
    ) public {
        p.blanks[0].sig.seq = uint16(signingDays);
        p.blanks[0].sig.attr = uint16(closingDays);
    }

    function addBlank(
        Page storage p,
        bool beBuyer,
        uint256 seq,
        uint256 acct
    ) public {
        require (seq > 0, "SR.AB: zero seq");
        require (acct > 0, "SR.AB: zero acct");

        
        if (beBuyer) {
            require(!p.sellers.contains(acct), "SR.AB: seller intends to buy");
            p.buyers.add(acct);
        } else {
            require(!p.buyers.contains(acct), "SR.AB: buyer intends to sell");
            p.sellers.add(acct);
        }

        if (p.blanks[uint40(acct)].seqOfDeals.add(uint16(seq)))
            _increaseCounterOfBlanks(p);
    }

    function removeBlank(
        Page storage p,
        uint256 seq,
        uint256 acct
    ) public {
        if (p.buyers.contains(acct) || p.sellers.contains(acct)) {
            if (p.blanks[acct].seqOfDeals.remove(seq))
                _decreaseCounterOfBlanks(p);

            if (p.blanks[acct].seqOfDeals.length() == 0) {
                delete p.blanks[acct]; 
                p.buyers.remove(acct) || p.sellers.remove(acct);
            }
        }
    }

    function signDoc(Page storage p, uint256 acct, bytes32 sigHash) 
        public 
    {
        require(block.timestamp < getSigDeadline(p) ||
            getSigningDays(p) == 0,
            "SR.SD: missed sigDeadline");

        require(!established(p),
            "SR.SD: Doc already established");

        if ((p.buyers.contains(acct) || p.sellers.contains(acct)) &&
            p.blanks[acct].sig.sigDate == 0) {

            Signature storage sig = p.blanks[acct].sig;

            sig.signer = uint40(acct);
            sig.sigDate = uint48(block.timestamp);
            sig.blocknumber = uint64(block.number);

            p.blanks[acct].sigHash = sigHash;

            _increaseCounterOfSigs(p, p.blanks[acct].seqOfDeals.length());
        }
    }

    function regSig(Page storage p, uint256 acct, uint sigDate, bytes32 sigHash)
        public returns (bool flag)
    {
        require(block.timestamp < getSigDeadline(p),
            "SR.RS: missed sigDeadline");

        require(!established(p),
            "SR.regSig: Doc already established");

        if (p.buyers.contains(acct) || p.sellers.contains(acct)) {

            Signature storage sig = p.blanks[acct].sig;

            sig.signer = uint40(acct);
            sig.sigDate = uint48(sigDate);
            sig.blocknumber = uint64(block.number);

            p.blanks[acct].sigHash = sigHash;

            _increaseCounterOfSigs(p, 1);

            flag = true;
        }

    }

    function _increaseCounterOfBlanks(Page storage p) private {
        p.blanks[0].sig.para++;
    }

    function _decreaseCounterOfBlanks(Page storage p) private {
        p.blanks[0].sig.para--;
    }

    function _increaseCounterOfSigs(Page storage p, uint qtyOfDeals) private {
        p.blanks[0].sig.arg += uint16(qtyOfDeals);
    }

    //####################
    //##    Read I/O    ##
    //####################

    function circulated(Page storage p) public view returns (bool)
    {
        return p.blanks[0].sig.sigDate > 0;
    }

    function established(Page storage p) public view returns (bool)
    {
        return counterOfBlanks(p) > 0 
            && counterOfBlanks(p) == counterOfSigs(p);
    }

    function counterOfBlanks(Page storage p) public view returns(uint16) {
        return p.blanks[0].sig.para;
    }

    function counterOfSigs(Page storage p) public view returns(uint16) {
        return p.blanks[0].sig.arg;
    }

    function getCirculateDate(Page storage p) public view returns(uint48) {
        return p.blanks[0].sig.sigDate;
    }

    function getSigningDays(Page storage p) public view returns(uint16) {
        return p.blanks[0].sig.seq;
    }

    function getClosingDays(Page storage p) public view returns(uint16) {
        return p.blanks[0].sig.attr;
    }

    function getSigDeadline(Page storage p) public view returns(uint48) {
        return p.blanks[0].sig.sigDate + uint48(p.blanks[0].sig.seq) * 86400; 
    }

    function getClosingDeadline(Page storage p) public view returns(uint48) {
        return p.blanks[0].sig.sigDate + uint48(p.blanks[0].sig.attr) * 86400; 
    }

    function isSigner(Page storage p, uint256 acct) 
        public view returns (bool) 
    {
        return p.blanks[acct].sig.signer > 0;
    }

    function sigOfParty(Page storage p, uint256 acct) public view
        returns (
            uint256[] memory seqOfDeals, 
            Signature memory sig,
            bytes32 sigHash
        ) 
    {
        seqOfDeals = p.blanks[acct].seqOfDeals.values();
        sig = p.blanks[acct].sig;
        sigHash = p.blanks[acct].sigHash;
    }

    function sigsOfPage(Page storage p) public view
        returns (
            Signature[] memory sigsOfBuyer, 
            Signature[]memory sigsOfSeller
        )
    {
        sigsOfBuyer = sigsOfSide(p, p.buyers);
        sigsOfSeller = sigsOfSide(p, p.sellers);
    }

    function sigsOfSide(Page storage p, EnumerableSet.UintSet storage partiesOfSide) 
        public view
        returns (Signature[] memory)
    {
        uint256[] memory parties = partiesOfSide.values();
        uint256 len = parties.length;

        Signature[] memory sigs = new Signature[](len);

        while (len > 0) {
            sigs[len-1] = p.blanks[parties[len-1]].sig;
            len--;
        }

        return sigs;
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

library SwapsRepo {

    enum StateOfSwap {
        Pending,    
        Issued,
        Closed,
        Terminated
    }

    struct Swap {
        uint16 seqOfSwap;
        uint32 seqOfPledge;
        uint64 paidOfPledge;
        uint32 seqOfTarget;
        uint64 paidOfTarget;
        uint32 priceOfDeal;
        bool isPutOpt;
        uint8 state;
    }

    struct Repo {
        // seqOfSwap => Swap
        mapping(uint256 => Swap) swaps;
    }

    // ###############
    // ##  Modifier ##
    // ###############

    modifier swapExist(Repo storage repo, uint seqOfSwap) {
        require (isSwap(repo, seqOfSwap), "SR.swapExist: not");
        _;
    }

    // ###############
    // ## Write I/O ##
    // ###############

    // ==== cofify / parser ====

    function codifySwap(Swap memory swap) public pure returns (bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            swap.seqOfSwap,
                            swap.seqOfPledge,
                            swap.paidOfPledge,
                            swap.seqOfTarget,
                            swap.paidOfTarget,
                            swap.priceOfDeal,
                            swap.isPutOpt,
                            swap.state);
        assembly {
            sn := mload(add(_sn, 0x20))
        }
    }

    function regSwap(
        Repo storage repo,
        Swap memory swap
    ) public returns(Swap memory) {

        require(swap.seqOfTarget * swap.paidOfTarget * swap.seqOfPledge > 0,
            "SWR.regSwap: zero para");

        swap.seqOfSwap = _increaseCounter(repo);

        repo.swaps[swap.seqOfSwap] = swap;
        repo.swaps[0].paidOfTarget += swap.paidOfTarget;

        return swap;
    }

    function payOffSwap(
        Repo storage repo,
        uint seqOfSwap,
        uint msgValue,
        uint centPrice
    ) public returns (Swap memory ) {

        Swap storage swap = repo.swaps[seqOfSwap];

        require(swap.state == uint8(StateOfSwap.Issued), 
            "SWR.payOffSwap: wrong state");

        require (uint(swap.paidOfTarget) * uint(swap.priceOfDeal) / 10 ** 4 * 
            centPrice / 100 <= msgValue, "SWR.payOffSwap: insufficient amt");

        swap.state = uint8(StateOfSwap.Closed);

        return swap;
    }

    function terminateSwap(
        Repo storage repo,
        uint seqOfSwap
    ) public returns (Swap memory){

        Swap storage swap = repo.swaps[seqOfSwap];

        require(swap.state == uint8(StateOfSwap.Issued), 
            "SWR.terminateSwap: wrong state");

        swap.state = uint8(StateOfSwap.Terminated);

        return swap;
    }

    // ==== Counter ====

    function _increaseCounter(Repo storage repo) private returns(uint16) {
        repo.swaps[0].seqOfSwap++;
        return repo.swaps[0].seqOfSwap;
    } 

    // ################
    // ##  Read I/O  ##
    // ################

    function counterOfSwaps(Repo storage repo)
        public view returns (uint16)
    {
        return repo.swaps[0].seqOfSwap;
    }

    function sumPaidOfTarget(Repo storage repo)
        public view returns (uint64)
    {
        return repo.swaps[0].paidOfTarget;
    }

    function isSwap(Repo storage repo, uint256 seqOfSwap)
        public view returns (bool)
    {
        return seqOfSwap <= counterOfSwaps(repo);
    }

    function getSwap(Repo storage repo, uint256 seqOfSwap)
        public view swapExist(repo, seqOfSwap) returns (Swap memory)
    {
        return repo.swaps[seqOfSwap];
    }

    function checkValueOfSwap(
        Repo storage repo,
        uint seqOfSwap,
        uint centPrice
    ) public view returns (uint) {
        Swap memory swap = getSwap(repo, seqOfSwap);
        return uint(swap.paidOfTarget) * uint(swap.priceOfDeal) / 10 ** 4 * 
            centPrice / 100;
    }

    function getAllSwaps(Repo storage repo)
        public view returns (Swap[] memory )
    {
        uint256 len = counterOfSwaps(repo);
        Swap[] memory swaps = new Swap[](len);

        while (len > 0) {
            swaps[len-1] = repo.swaps[len];
            len--;
        }
        return swaps;
    }

    function allSwapsClosed(Repo storage repo)
        public view returns (bool)
    {
        uint256 len = counterOfSwaps(repo);
        while (len > 0) {
            if (repo.swaps[len].state < uint8(StateOfSwap.Closed))
                return false;
            len--;
        }

        return true;        
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

import "../comps/books/roa/IInvestmentAgreement.sol";
import "../comps/books/ros/IRegisterOfShares.sol";

import "./DealsRepo.sol";

library TopChain {

    enum CatOfNode {
        IndepMemberInQueue, // 0
        GroupRepInQueue,    // 1
        GroupMember,        // 2
        IndepMemberOnChain, // 3 
        GroupRepOnChain     // 4
    }

    struct Node {
        uint40 prev;
        uint40 next;
        uint40 ptr;
        uint64 amt;
        uint64 sum;
        uint8 cat;
    }

    struct Para {
        uint40 tail;
        uint40 head;
        uint32 maxQtyOfMembers;
        uint16 minVoteRatioOnChain;
        uint32 qtyOfSticks;
        uint32 qtyOfBranches;
        uint32 qtyOfMembers;
        uint16 para;
        uint16 argu;
    }

    struct Chain {
        // usrNo => Node
        mapping(uint256 => Node) nodes;
        Para para;
    }

    /* Node[0] {
        prev: tail;
        next: head;
        ptr: pending;
        amt: pending;
        sum: totalVotes;
        cat: basedOnPar;
    } */

    //#################
    //##   Modifier  ##
    //#################

    modifier memberExist(Chain storage chain, uint256 acct) {
        require(isMember(chain, acct), "TC.memberExist: acct not member");
        _;
    }

    //#################
    //##  Write I/O  ##
    //#################
    
    // ==== Options ====

    function setMaxQtyOfMembers(Chain storage chain, uint max) public {
        chain.para.maxQtyOfMembers = uint32(max);
    }

    function setMinVoteRatioOnChain(Chain storage chain, uint min) public {
        require(min < 5000, "minVoteRatioOnChain: overflow");
        chain.para.minVoteRatioOnChain = uint16(min);
    }

    function setVoteBase(
        Chain storage chain, 
        bool _basedOnPar
    ) public {
        chain.nodes[0].cat = _basedOnPar ? 1 : 0;
    }

    // ==== Node ====

    function addNode(Chain storage chain, uint acct) public {

        require(acct > 0, "TC.addNode: zero acct");

        Node storage n = chain.nodes[acct];

        if (n.ptr == 0) {
            require( maxQtyOfMembers(chain) == 0 ||
                qtyOfMembers(chain) < maxQtyOfMembers(chain),
                "TC.addNode: no vacance"
            );

            n.ptr = uint40(acct);

            _appendToQueue(chain, n, n.ptr);
            _increaseQtyOfMembers(chain);
        }
    }

    function delNode(Chain storage chain, uint acct) public {
        _carveOut(chain, acct);
        delete chain.nodes[acct];
        _decreaseQtyOfMembers(chain);        
    }

    // ==== ChangeAmt ====

    function increaseTotalVotes(
        Chain storage chain,
        uint deltaAmt, 
        bool isIncrease
    ) public {
        uint40 amt = uint40(deltaAmt);
        if (isIncrease) _increaseTotalVotes(chain, amt);
        else _decreaseTotalVotes(chain, amt);
    }

    function increaseAmt(
        Chain storage chain, 
        uint256 acct, 
        uint deltaAmt, 
        bool isIncrease
    ) public memberExist(chain, acct) {

        uint64 amt = uint64(deltaAmt);

        Node storage n = chain.nodes[acct];

        if (isIncrease) {
            n.amt += amt;
            n.sum += amt;
        } else {
            n.amt -= amt;
            n.sum -= amt;
        }

        if (n.cat == uint8(CatOfNode.GroupMember)) {

            Node storage r = chain.nodes[n.ptr];

            if (isIncrease) {

                r.sum += amt;
                
                if (r.cat == uint8(CatOfNode.GroupRepOnChain)) 
                    _move(chain, n.ptr, isIncrease);
                else if (_onChainTest(chain, r))
                    _upChainAndMove(chain, r, n.ptr);

            } else {

                r.sum -= amt;
                
                if (r.cat == uint8(CatOfNode.GroupRepOnChain)) {

                    if (!_onChainTest(chain, r)) 
                        _offChain(chain, r, n.ptr);
                    else _move(chain, n.ptr, isIncrease);

                }
            }

        } else if (_isOnChain(n)) {

            if (isIncrease) _move(chain, n.ptr, isIncrease);
            else {
                if (!_onChainTest(chain, n)) 
                    _offChain(chain, n, n.ptr);
                else _move(chain, n.ptr, isIncrease);
            }
        
        } else if(isIncrease && _onChainTest(chain, n))
            _upChainAndMove(chain, n, n.ptr);

    }

    // ==== Grouping ====

    function top2Sub(
        Chain storage chain,
        uint256 acct,
        uint256 root
    ) public memberExist(chain, root) {

        Node storage n = chain.nodes[acct];
        Node storage r = chain.nodes[root];

        require(acct != root, "TC.T2S: self grouping");
        require(_isIndepMember(n), "TC.T2S: not indepMember");
        require(_notGroupMember(r), "TC.T2S: leaf as root");

        _carveOut(chain, n.ptr);
        _vInsert(chain, n.ptr, uint40(root));
    }

    function sub2Top(Chain storage chain, uint256 acct) public {

        Node storage n = chain.nodes[acct];
        require(_isInGroup(n), "TC.S2T: not in a branch");

        _carveOut(chain, acct);

        n.sum = n.amt;
        n.ptr = uint40(acct);

        if (_onChainTest(chain, n)) _upChainAndMove(chain, n, n.ptr);
        else _appendToQueue(chain, n, n.ptr);
    }

    // ==== CarveOut ====

    function _branchOff(Chain storage chain, uint256 root) private {
        Node storage r = chain.nodes[root];

        if (_isOnChain(r)) {

            chain.nodes[r.next].prev = r.prev;
            chain.nodes[r.prev].next = r.next;

            _decreaseQtyOfBranches(chain);

        } else {

            if (r.prev > 0 && r.next > 0) {
                chain.nodes[r.next].prev = r.prev;
                chain.nodes[r.prev].next = r.next;
            }else if (r.prev == 0 && r.next == 0) {
                chain.para.tail = 0;
                chain.para.head = 0;
            }else if (r.next == 0) {
                chain.para.tail = r.prev;
                chain.nodes[r.prev].next = 0;
            } else if (r.prev == 0) {
                chain.nodes[r.next].prev = 0;
                chain.para.head = r.next;
            }

            _decreaseQtyOfSticks(chain);

        }
    }

    function _carveOut(Chain storage chain, uint acct)
        private
        memberExist(chain, acct)
    {
        Node storage n = chain.nodes[acct];

        if (_isIndepMember(n)) {

            _branchOff(chain, acct);
        
        } else if (_isGroupRep(n)) {

            if (n.cat == uint8(CatOfNode.GroupRepOnChain) || (n.prev > 0 && n.next > 0)) {

                chain.nodes[n.prev].next = n.ptr;
                chain.nodes[n.next].prev = n.ptr;

            } else {

                if (n.prev == 0 && n.next == 0) {
                    chain.para.tail = n.ptr;
                    chain.para.head = n.ptr;
                } else if (n.next == 0) {
                    chain.para.tail = n.ptr;
                    chain.nodes[n.prev].next = n.ptr;
                } else if (n.prev == 0) {
                    chain.nodes[n.next].prev = n.ptr;
                    chain.para.head = n.ptr;
                }

            }

            Node storage d = chain.nodes[n.ptr];

            d.ptr = d.next;
            d.prev = n.prev;
            d.next = n.next;

            if (d.ptr > 0) {
                uint40 cur = d.ptr;
                while (cur > 0) {
                    chain.nodes[cur].ptr = n.ptr;
                    cur = chain.nodes[cur].next;
                }
                d.cat = n.cat;
            } else {
                d.ptr = n.ptr;
                d.cat = n.cat == uint8(CatOfNode.GroupRepInQueue) 
                    ? uint8(CatOfNode.IndepMemberInQueue) 
                    : uint8(CatOfNode.IndepMemberOnChain);
            }

            d.sum = n.sum - n.amt;

            _offChainCheck(chain, d, n.ptr);

        } else if (_isGroupMember(n)) {

            Node storage u = chain.nodes[n.prev];

            if (n.next > 0) chain.nodes[n.next].prev = n.prev;

            if (u.cat == uint8(CatOfNode.GroupMember)) u.next = n.next;
            else if (n.next > 0) {
                u.ptr = n.next;
            } else {
                u.ptr = n.ptr;
                u.cat = u.cat == uint8(CatOfNode.GroupRepInQueue) 
                    ? uint8(CatOfNode.IndepMemberInQueue) 
                    : uint8(CatOfNode.IndepMemberOnChain);
            }

            Node storage r = chain.nodes[n.ptr];

            r.sum -= n.amt;

            _offChainCheck(chain, r, n.ptr);

        }
    }

    function _offChainCheck(
        Chain storage chain,
        Node storage r,
        uint40 acct
    ) private {
        if (_isOnChain(r)) {
            if (_onChainTest(chain, r)) _move(chain, acct, false);
            else _offChain(chain, r, acct);                
        }
    }

    // ==== Insert ====

    function _hInsert(
        Chain storage chain,
        uint acct,
        uint prev,
        uint next
    ) private {
        Node storage n = chain.nodes[acct];

        chain.nodes[prev].next = uint40(acct);
        n.prev = uint40(prev);

        chain.nodes[next].prev = uint40(acct);
        n.next = uint40(next);
    }

    function _vInsert(
        Chain storage chain,
        uint40 acct,
        uint40 root
    ) private {
        Node storage n = chain.nodes[acct];
        Node storage r = chain.nodes[root];

        if (_isIndepMember(r)) {
            r.cat = r.cat == uint8(CatOfNode.IndepMemberInQueue) 
                ? uint8(CatOfNode.GroupRepInQueue) 
                : uint8(CatOfNode.GroupRepOnChain);
            n.next = 0;
        } else if (_isGroupRep(r)) {
            n.next = r.ptr;
            chain.nodes[n.next].prev = acct;
        }

        n.prev = root;
        n.ptr = root;

        n.cat = uint8(CatOfNode.GroupMember);

        r.ptr = acct;
        r.sum += n.amt;

        if (_isOnChain(r)) _move(chain, root, true);
        else if (_onChainTest(chain, r)) {
            _upChainAndMove(chain, r, root);
        }
    }

    // ==== Move ====

    function _move(
        Chain storage chain,
        uint acct,
        bool increase
    ) private {
        Node storage n = chain.nodes[acct];

        (uint256 prev, uint256 next) = getPos(
            chain,
            n.sum,
            n.prev,
            n.next,
            increase
        );

        if (next != n.next || prev != n.prev) {
            _branchOff(chain, acct); 
            _hInsert(chain, acct, prev, next);
        }
    }

    // ==== Chain & Queue ====

    function _appendToQueue(
        Chain storage chain,
        Node storage n,
        uint40 acct
    ) private {

        if (chain.para.qtyOfSticks > 0) {
            chain.nodes[chain.para.tail].next = acct;
        } else {
            chain.para.head = acct;
        }

        n.prev = chain.para.tail;
        n.next = 0;

        chain.para.tail = acct;

        if (_isOnChain(n)) n.cat -= 3;

        _increaseQtyOfSticks(chain);
    }

    function _appendToChain(
        Chain storage chain,
        Node storage n,
        uint40 acct
    ) private {
        n.prev = chain.nodes[0].prev;
        chain.nodes[n.prev].next = acct;
        chain.nodes[0].prev = acct;
        n.next = 0;

        if (_isInQueue(n)) n.cat += 3;

        _increaseQtyOfBranches(chain);
    }

    function _onChainTest(
        Chain storage chain,
        Node storage r
    ) private view returns(bool) {
        return uint(r.sum) * 10000 >= uint(totalVotes(chain)) * minVoteRatioOnChain(chain);
    }

    function _upChainAndMove(
        Chain storage chain,
        Node storage n,
        uint40 acct
    ) private {
        _trimChain(chain);
        _branchOff(chain, acct);
        _appendToChain(chain, n, acct);
        _move(chain, acct, true);

    }

    function _trimChain(
        Chain storage chain
    ) private {

        uint40 cur = chain.nodes[0].prev;
        
        while (cur > 0) {
            Node storage t = chain.nodes[cur];
            uint40 prev = t.prev;
            if (!_onChainTest(chain, t))
                _offChain(chain, t, cur);
            else break;
            cur = prev;
        }
    }

    function _offChain(
        Chain storage chain,
        Node storage n,
        uint40 acct
    ) private {
        _branchOff(chain, acct);
        _appendToQueue(chain, n, acct);                            
    }

    // ---- Categories Of Node ----

    function _isOnChain(
        Node storage n
    ) private view returns (bool) {
        return n.cat > 2;
    }

    function _isInQueue(
        Node storage n
    ) private view returns (bool) {
        return n.cat < 2;
    }

    function _isIndepMember(
        Node storage n
    ) private view returns (bool) {
        return n.cat % 3 == 0;
    }

    function _isInGroup(
        Node storage n
    ) private view returns (bool) {
        return n.cat % 3 > 0;
    }

    function _isGroupRep(
        Node storage n
    ) private view returns (bool) {
        return n.cat % 3 == 1;
    }

    function _isGroupMember(
        Node storage n
    ) private view returns (bool) {
        return n.cat == uint8(CatOfNode.GroupMember);
    }

    function _notGroupMember(
        Node storage n
    ) private view returns (bool) {
        return n.cat % 3 < 2;
    }

    // ==== setting ====

    function _increaseQtyOfBranches(Chain storage chain) private {
        chain.para.qtyOfBranches++;
    }

    function _increaseQtyOfMembers(Chain storage chain) private {
        chain.para.qtyOfMembers++;
    }

    function _increaseQtyOfSticks(Chain storage chain) private {
        chain.para.qtyOfSticks++;
    }

    function _increaseTotalVotes(Chain storage chain, uint64 deltaAmt) private {
        chain.nodes[0].sum += deltaAmt;
    }

    function _decreaseQtyOfBranches(Chain storage chain) private {
        chain.para.qtyOfBranches--;
    }

    function _decreaseQtyOfMembers(Chain storage chain) private {
        chain.para.qtyOfMembers--;
    }

    function _decreaseQtyOfSticks(Chain storage chain) private {
        chain.para.qtyOfSticks--;
    }

    function _decreaseTotalVotes(Chain storage chain, uint64 deltaAmt) private {
        chain.nodes[0].sum -= deltaAmt;
    }

    //################
    //##    Read    ##
    //################

    function isMember(Chain storage chain, uint256 acct)
        public
        view
        returns (bool)
    {
        return chain.nodes[acct].ptr != 0;
    }

    // ==== Zero Node ====

    function tail(Chain storage chain) public view returns (uint40) {
        return chain.nodes[0].prev;
    }

    function head(Chain storage chain) public view returns (uint40) {
        return chain.nodes[0].next;
    }

    function totalVotes(Chain storage chain) public view returns (uint64) {
        return chain.nodes[0].sum;
    }

    function basedOnPar(Chain storage chain) public view returns (bool) {
        return chain.nodes[0].cat == 1;
    }

    // ---- Para ----

    function headOfQueue(Chain storage chain)
        public
        view
        returns (uint40)
    {
        return  chain.para.head;
    }

    function tailOfQueue(Chain storage chain)
        public
        view
        returns (uint40)
    {
        return  chain.para.tail;
    }

    function maxQtyOfMembers(Chain storage chain)
        public
        view
        returns (uint32)
    {
        return chain.para.maxQtyOfMembers; 
    }

    function minVoteRatioOnChain(Chain storage chain)
        public
        view
        returns (uint16)
    {
        uint16 min = chain.para.minVoteRatioOnChain;
        return min > 0 ? min : 500; 
    }

    function qtyOfBranches(Chain storage chain) public view returns (uint32) {
        return chain.para.qtyOfBranches;
    }

    function qtyOfGroups(Chain storage chain) public view returns (uint32) {
        return chain.para.qtyOfBranches + chain.para.qtyOfSticks;
    }

    function qtyOfTopMembers(Chain storage chain) 
        public view 
        returns(uint qty) 
    {
        uint cur = chain.nodes[0].next;

        while(cur > 0) {
            qty++;
            cur = nextNode(chain, cur);
        }
    }

    function qtyOfMembers(Chain storage chain) public view returns (uint32) {
        return chain.para.qtyOfMembers;
    }

    // ==== locate position ====

    function getPos(
        Chain storage chain,
        uint256 amount,
        uint256 prev,
        uint256 next,
        bool increase
    ) public view returns (uint256, uint256) {
        if (increase)
            while (prev > 0 && chain.nodes[prev].sum < amount) {
                next = prev;
                prev = chain.nodes[prev].prev;
            }
        else
            while (next > 0 && chain.nodes[next].sum > amount) {
                prev = next;
                next = chain.nodes[next].next;
            }

        return (prev, next);
    }

    function nextNode(Chain storage chain, uint256 acct)
        public view returns (uint256 next)
    {
        Node storage n = chain.nodes[acct];

        if (_isIndepMember(n)) {
            next = n.next;
        } else if (_isGroupRep(n)) {
            next = n.ptr;
        } else if (_isGroupMember(n)) {
            next = (n.next > 0) ? n.next : chain.nodes[n.ptr].next;
        }
    }

    function getNode(Chain storage chain, uint256 acct)
        public view returns (Node memory n)
    {
        n = chain.nodes[acct];
    }

    // ==== group ====

    function rootOf(Chain storage chain, uint256 acct)
        public
        view
        memberExist(chain, acct)
        returns (uint40 group)
    {
        Node storage n = chain.nodes[acct];
        group = (n.cat == uint8(CatOfNode.GroupMember)) ? n.ptr : uint40(acct) ;
    }

    function deepOfBranch(Chain storage chain, uint256 acct)
        public
        view
        memberExist(chain, acct)
        returns (uint256 deep)
    {
        Node storage n = chain.nodes[acct];

        if (_isIndepMember(n)) deep = 1;
        else if (_isGroupRep(n)) deep = _deepOfBranch(chain, acct);
        else deep = _deepOfBranch(chain, n.ptr);
    }

    function _deepOfBranch(Chain storage chain, uint256 root)
        private
        view
        returns (uint256 deep)
    {
        deep = 1;

        uint40 next = chain.nodes[root].ptr;

        while (next > 0) {
            deep++;
            next = chain.nodes[next].next;
        }
    }

    function votesOfGroup(Chain storage chain, uint256 acct)
        public
        view
        returns (uint64 votes)
    {
        uint256 group = rootOf(chain, acct);
        votes = chain.nodes[group].sum;
    }

    function membersOfGroup(Chain storage chain, uint256 acct)
        public
        view
        returns (uint256[] memory list)
    {
        uint256 cur = rootOf(chain, acct);
        uint256 len = deepOfBranch(chain, acct);

        list = new uint256[](len);
        uint256 i = 0;

        while (i < len) {
            list[i] = cur;
            cur = nextNode(chain, cur);
            i++;
        }
    }

    function affiliated(
        Chain storage chain,
        uint256 acct1,
        uint256 acct2
    )
        public
        view
        memberExist(chain, acct1)
        memberExist(chain, acct2)
        returns (bool)
    {
        Node storage n1 = chain.nodes[acct1];
        Node storage n2 = chain.nodes[acct2];

        return n1.ptr == n2.ptr || n1.ptr == acct2 || n2.ptr == acct1;
    }

    // ==== members ====

    function topMembersList(Chain storage chain)
        public view
        returns (uint256[] memory list)
    {
        uint256 len = qtyOfTopMembers(chain);
        list = new uint[](len);

        len = 0;
        uint cur = chain.nodes[0].next;

        _seqListOfQueue(chain, list, cur, len);
    }

    function sortedMembersList(Chain storage chain)
        public
        view
        returns (uint256[] memory list)
    {
        uint256 len = qtyOfMembers(chain);
        list = new uint[](len);

        uint cur = chain.nodes[0].next;
        len = 0;

        len = _seqListOfQueue(chain, list, cur, len);

        cur = chain.para.head;
        _seqListOfQueue(chain, list, cur, len);
    }

    function _seqListOfQueue(
        Chain storage chain,
        uint[] memory list,
        uint cur,
        uint i
    ) private view returns (uint) {
        while (cur > 0) {
            list[i] = cur;
            cur = nextNode(chain, cur);
            i++;
        }
        return i;
    }

    // ==== Backup / Restore ====

    function getSnapshot(Chain storage chain)
        public view
        returns (Node[] memory list, Para memory para)
    {
        para = chain.para;

        uint256 len = qtyOfMembers(chain);
        list = new Node[](len + 1);

        list[0] = chain.nodes[0];

        uint256 cur = chain.nodes[0].next;
        len = 1;
        len = _backupNodes(chain, list, cur, len);

        cur = para.head;
        _backupNodes(chain, list, cur, len);
    }

    function _backupNodes(
        Chain storage chain,
        Node[] memory list,
        uint cur,
        uint i
    ) private view returns (uint) {
        while (cur > 0) {
            list[i] = chain.nodes[cur];
            cur = nextNode(chain, cur);
            i++;
        }
        return i;
    }

    function restoreChain(
        Chain storage chain, 
        Node[] memory list, 
        Para memory para
    ) public {

        chain.nodes[0] = list[0];
        chain.para = para;

        uint256 cur = list[0].next;
        uint256 i = 1;
        i = _restoreNodes(chain, list, cur, i);

        cur = para.head;
        _restoreNodes(chain, list, cur, i);
    }

    function _restoreNodes(
        Chain storage chain,
        Node[] memory list,
        uint cur,
        uint i
    ) private returns (uint) {
        while (cur > 0) {
            chain.nodes[cur] = list[i];
            cur = nextNode(chain, cur);
            i++;
        }
        return i;
    }

    // ==== MockDeals ====

    function mockDealsOfIA(
        Chain storage chain,
        IInvestmentAgreement _ia,
        IRegisterOfShares _ros
    ) public {
        uint[] memory seqList = _ia.getSeqList();

        uint256 len = seqList.length;

        while (len > 0) {
            DealsRepo.Deal memory deal = _ia.getDeal(seqList[len-1]);

            uint amount = basedOnPar(chain) ? deal.body.par : deal.body.paid;

            if (deal.head.seller > 0) {
                amount = amount * _ros.getShare(deal.head.seqOfShare).head.votingWeight / 100;
                mockDealOfSell(chain, deal.head.seller, amount);
            } else {
                amount = amount * deal.head.votingWeight / 100;
            }
            
            mockDealOfBuy(chain, deal.body.buyer, deal.body.groupOfBuyer, amount);

            len--;
        }
    }

    function mockDealOfSell(
        Chain storage chain, 
        uint256 seller, 
        uint amount
    ) public {
        increaseAmt(chain, seller, amount, false);
        
        if (chain.nodes[seller].amt == 0)
            delNode(chain, seller);
    }

    function mockDealOfBuy(
        Chain storage chain, 
        uint256 buyer, 
        uint256 group,
        uint amount
    ) public {
        addNode(chain, buyer);

        increaseAmt(chain, buyer, amount, true);

        if (rootOf(chain, buyer) != group)
            top2Sub(chain, buyer, group);
    }
}