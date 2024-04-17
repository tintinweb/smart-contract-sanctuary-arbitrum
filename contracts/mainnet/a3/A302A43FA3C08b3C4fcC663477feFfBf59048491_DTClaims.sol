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

library DTClaims {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Head {
        uint16 seqOfDeal;
        bool dragAlong;
        uint32 seqOfShare;
        uint64 paid;
        uint64 par;
        uint40 caller;
        uint16 para;
        uint16 argu;
    }

    struct Claim {
        uint8 typeOfClaim;
        uint32 seqOfShare;
        uint64 paid;
        uint64 par;
        uint40 claimer;
        uint48 sigDate;
        bytes32 sigHash;
    }

    struct Pack {
        //seqOfShare => Claim
        mapping(uint256 => Claim) claims;
        EnumerableSet.UintSet shares;
    }

    struct Claims {
        // seqOfDeal => drag/tag/merged => Pack
        mapping(uint256 => mapping(uint256 => Pack)) packs;
        EnumerableSet.UintSet deals;
    }

    modifier dealExist(Claims storage cls, uint seqOfDeal) {
        require (hasClaim(cls, seqOfDeal), "DTClaims.mf.dealExist: not");
        _;
    }

    //#################
    //##  Write I/O  ##
    //#################

    function snParser(bytes32 sn) public pure returns(Head memory head) {
        uint _sn = uint(sn);
        head = Head({
            seqOfDeal: uint16(_sn >> 240),
            dragAlong: bool(uint8(_sn >> 232) == 1),
            seqOfShare: uint32(_sn >> 200),
            paid: uint64(_sn >> 136),
            par: uint64(_sn >> 72),
            caller: uint40(_sn >> 32),
            para: uint16(_sn >> 16),
            argu: uint16(_sn)
        });
    }

    function codifyHead(Head memory head) public pure returns(bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            head.seqOfDeal,
                            head.dragAlong,
                            head.seqOfShare,
                            head.paid,
                            head.par,
                            head.caller,
                            head.para,
                            head.argu
        );

        assembly {
            sn := mload(add(_sn, 0x20))
        }
    }

    function execAlongRight(
        Claims storage cls,
        bool dragAlong,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint paid,
        uint par,
        uint256 claimer,
        bytes32 sigHash
    ) public {

        uint16 intSeqOfDeal = uint16(seqOfDeal);
        require(intSeqOfDeal > 0, "DTClaims.exec: zero seqOfDeal");

        Claim memory newClaim = Claim({
            typeOfClaim: dragAlong ? 0 : 1,
            seqOfShare: uint32(seqOfShare),
            paid: uint64(paid),
            par: uint64(par),
            claimer: uint40(claimer),
            sigDate: uint48(block.timestamp),
            sigHash: sigHash
        }); 

        require(newClaim.seqOfShare > 0, "DTClaims.exec: zero seqOfShare");

        Pack storage p = cls.packs[intSeqOfDeal][newClaim.typeOfClaim];

        if (p.shares.add(newClaim.seqOfShare)){

            p.claims[newClaim.seqOfShare] = newClaim;

            cls.deals.add(intSeqOfDeal);

            _consolidateClaimsOfShare(cls, intSeqOfDeal, newClaim);
        }
    }

    function _consolidateClaimsOfShare(
        Claims storage cls,
        uint intSeqOfDeal,
        Claim memory newClaim
    ) private {
        Pack storage m = cls.packs[intSeqOfDeal][2];

        if (m.shares.add(newClaim.seqOfShare)) {
            m.claims[newClaim.seqOfShare] = newClaim;
        } else {
            Claim storage mClaim = m.claims[newClaim.seqOfShare];

            mClaim.paid = newClaim.paid > mClaim.paid  ? newClaim.paid :  mClaim.paid;
            mClaim.par = newClaim.par > mClaim.par ? newClaim.par : mClaim.par;

            if (mClaim.typeOfClaim == 0){

                Claim memory tClaim = cls.packs[intSeqOfDeal][1].claims[newClaim.seqOfShare];

                mClaim.typeOfClaim = 1;
                mClaim.claimer = tClaim.claimer;
                mClaim.sigDate = tClaim.sigDate;
                mClaim.sigHash = tClaim.sigHash;
            }
        }
    }

    function acceptAlongClaims(
        Claims storage cls,
        uint seqOfDeal
    ) public returns (Claim[] memory) {
        cls.packs[seqOfDeal][2].claims[0].typeOfClaim = 1;
        return getClaimsOfDeal(cls, seqOfDeal);
    }

    //  ################################
    //  ##       Read I/O             ##
    //  ################################

    function hasClaim(Claims storage cls, uint seqOfDeal) public view returns(bool) {
        return cls.deals.contains(seqOfDeal);
    }

    function getDeals(Claims storage cls) public view returns(uint[] memory) {
        return cls.deals.values();
    }

    function getClaimsOfDeal(
        Claims storage cls,
        uint seqOfDeal
    ) public view dealExist(cls, seqOfDeal) returns(Claim[] memory) {

        Pack storage m = cls.packs[seqOfDeal][2];

        uint[] memory sharesList = m.shares.values();
        uint len = sharesList.length;

        Claim[] memory output = new Claim[](len);

        while (len > 0) {
            output[len - 1] = m.claims[sharesList[len - 1]];
            len --;
        }

        return output;
    }

    function hasShare(
        Claims storage cls,
        uint seqOfDeal,
        uint seqOfShare        
    ) public view dealExist(cls, seqOfDeal) returns(bool) {
        return cls.packs[seqOfDeal][2].shares.contains(seqOfShare);
    }

    function getClaimForShare(
        Claims storage cls,
        uint seqOfDeal,
        uint seqOfShare
    ) public view returns (Claim memory) {
        require (hasShare(cls, seqOfDeal, seqOfShare), "DTClaims.getClaimsForShare: not exist");
        return cls.packs[seqOfDeal][2].claims[seqOfShare];
    }

    function allAccepted(Claims storage cls) public view returns(bool flag) {
        uint[] memory dealsList = cls.deals.values();
        uint len = dealsList.length;

        flag = true;
        while(len > 0) {
            if (cls.packs[dealsList[len - 1]][2].claims[0].typeOfClaim == 0) {
                flag = false;
                break;
            }
            len--;
        }
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