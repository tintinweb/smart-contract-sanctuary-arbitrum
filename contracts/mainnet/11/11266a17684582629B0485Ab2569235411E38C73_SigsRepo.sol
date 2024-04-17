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