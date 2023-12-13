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
        uint8 state;
        uint8 para;
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
        uint par
    ) public pure returns (Share memory share) {

        share.head = snParser(sharenumber);

        share.body = Body({
            payInDeadline: uint48(payInDeadline),
            paid: uint64(paid),
            par: uint64(par),
            cleanPaid: uint64(paid),
            state: 0,
            para: 0
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