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

library CondsRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    enum LogOps {
        ZeroPoint,  // 0
        And,           
        Or,         
        Equal,
        NotEqual,   // 4
        AndAnd,  
        OrOr,
        AndOr,
        OrAnd,
        EqEq,
        NeNe,
        EqNe,
        NeEq,
        AndEq,
        EqAnd,
        OrEq,
        EqOr,
        AndNe,
        NeAnd,
        OrNe,
        NeOr        
    }

    enum ComOps {
        ZeroPoint,
        Equal,
        NotEqual,
        Bigger,
        Smaller,
        BiggerOrEqual,
        SmallerOrEqual
    }

    struct Cond {
        uint32 seqOfCond;
        uint8 logicOpr;    
        uint8 compOpr1;    
        uint64 para1;           
        uint8 compOpr2;    
        uint64 para2;           
        uint8 compOpr3;    
        uint64 para3;                               
    }

    struct Repo {
        mapping(uint256 => Cond) conds;
        EnumerableSet.Bytes32Set seqList;
    }

    // ###############
    // ## Write I/O ##
    // ###############

    // ==== codify / parser ====

    function snParser(bytes32 sn) public pure returns(Cond memory cond)
    {
        uint _sn = uint(sn);

        cond = Cond({
            seqOfCond: uint32(_sn >> 224),
            logicOpr: uint8(_sn >> 216),
            compOpr1: uint8(_sn >> 208),    
            para1: uint64(_sn >> 144),          
            compOpr2: uint8(_sn >> 136),    
            para2: uint64(_sn >> 72),           
            compOpr3: uint8(_sn >> 64),    
            para3: uint64(_sn)                               
        });
    }

    function codifyCond(Cond memory cond) public pure returns(bytes32 sn)
    {
        bytes memory _sn = abi.encodePacked(
                            cond.seqOfCond,
                            cond.logicOpr,
                            cond.compOpr1,
                            cond.para1,
                            cond.compOpr2,
                            cond.para2,
                            cond.compOpr3,
                            cond.para3);

        assembly {
            sn := mload(add(_sn, 0x20))
        }                
    }

    // ==== create / reg ====
    function createCond(Repo storage repo, bytes32 sn) public returns(uint32 seqOfCond)
    {
        seqOfCond = regCond(repo, snParser(sn));
    }

    function regCond(Repo storage repo, Cond memory cond) public returns(uint32 seqOfCond)
    {
        cond.seqOfCond = _increaseCounterOfConds(repo);
        repo.conds[cond.seqOfCond] = cond;
        repo.seqList.add(codifyCond(cond));
        seqOfCond = cond.seqOfCond;
    }

    function _increaseCounterOfConds(Repo storage repo) private returns(uint32)
    {
        repo.conds[0].seqOfCond++;
        return repo.conds[0].seqOfCond;
    }

    function removeCond(Repo storage repo, uint256 seqOfCond) public returns(bool flag)
    {
        if (repo.seqList.remove(codifyCond(repo.conds[seqOfCond])))
        {
            delete repo.conds[seqOfCond];
            flag = true;
        }
    }
    
    // ##################
    // ##   Write I/O  ##
    // ##################

    function counterOfConds(Repo storage repo) public view returns(uint32 seqOfCond) {
        seqOfCond = repo.conds[0].seqOfCond;
    }

    function getConds(Repo storage repo) public view returns(Cond[] memory)
    {
        uint256 len = repo.seqList.length();
        Cond[] memory output = new Cond[](len);

        while (len > 0) {
            output[len -1] = repo.conds[len];
            len--;
        }

        return output;
    }

    function checkCond(
        uint compOpr,
        uint para,
        uint data
    ) public pure returns (bool flag) {
        if (compOpr == uint8(ComOps.Equal)) flag = data == para;
        else if (compOpr == uint8(ComOps.NotEqual)) flag = data != para;
        else if (compOpr == uint8(ComOps.Bigger)) flag = data > para;
        else if (compOpr == uint8(ComOps.Smaller)) flag = data < para;
        else if (compOpr == uint8(ComOps.BiggerOrEqual)) flag = data >= para;
        else if (compOpr == uint8(ComOps.SmallerOrEqual)) flag = data <= para;
        else revert ("CR.CSC: compOpr overflow");
    }

    function checkSoleCond(
        Cond memory cond,
        uint data
    ) public pure returns (bool flag) {
        flag = checkCond(cond.compOpr1, cond.para1, data);
    }

    function checkCondsOfTwo(
        Cond memory cond,
        uint data1,
        uint data2
    ) public pure returns (bool flag) {
        bool flag1;
        bool flag2;

        flag1 = checkCond(cond.compOpr1, cond.para1, data1);
        flag2 = checkCond(cond.compOpr2, cond.para2, data2);

        if (cond.logicOpr == uint8(LogOps.And)) flag = flag1 && flag2;
        else if (cond.logicOpr == uint8(LogOps.Or)) flag = flag1 || flag2;
        else if (cond.logicOpr == uint8(LogOps.Equal)) flag = flag1 == flag2;
        else if (cond.logicOpr == uint8(LogOps.NotEqual)) flag = flag1 != flag2;
        else revert("CR.CCO2: logicOpr overflow");
    }

    function checkCondsOfThree(
        Cond memory cond,
        uint data1,
        uint data2,
        uint data3
    ) public pure returns (bool flag) {
        bool flag1;
        bool flag2;
        bool flag3;

        flag1 = checkCond(cond.compOpr1, cond.para1, data1);
        flag2 = checkCond(cond.compOpr2, cond.para2, data2);
        flag3 = checkCond(cond.compOpr3, cond.para3, data3);

        if (cond.logicOpr == uint8(LogOps.AndAnd)) flag = flag1 && flag2 && flag3;
        else if (cond.logicOpr == uint8(LogOps.OrOr)) flag = flag1 || flag2 || flag3;
        else if (cond.logicOpr == uint8(LogOps.AndOr)) flag = flag1 && flag2 || flag3;
        else if (cond.logicOpr == uint8(LogOps.OrAnd)) flag = flag1 || flag2 && flag3;
        else if (cond.logicOpr == uint8(LogOps.EqEq)) flag = flag1 == flag2 == flag3;
        else if (cond.logicOpr == uint8(LogOps.NeNe)) flag = flag1 != flag2 != flag3;
        else if (cond.logicOpr == uint8(LogOps.EqNe)) flag = flag1 == flag2 != flag3;
        else if (cond.logicOpr == uint8(LogOps.NeEq)) flag = flag1 != flag2 == flag3;
        else if (cond.logicOpr == uint8(LogOps.AndEq)) flag = flag1 && flag2 == flag3;
        else if (cond.logicOpr == uint8(LogOps.EqAnd)) flag = flag1 == flag2 && flag3;
        else if (cond.logicOpr == uint8(LogOps.OrEq)) flag = flag1 || flag2 == flag3;
        else if (cond.logicOpr == uint8(LogOps.EqOr)) flag = flag1 == flag2 || flag3;
        else if (cond.logicOpr == uint8(LogOps.AndNe)) flag = flag1 && flag2 != flag3;
        else if (cond.logicOpr == uint8(LogOps.NeAnd)) flag = flag1 != flag2 && flag3;
        else if (cond.logicOpr == uint8(LogOps.OrNe)) flag = flag1 || flag2 != flag3;
        else if (cond.logicOpr == uint8(LogOps.NeOr)) flag = flag1 != flag2 || flag3;
        else revert("CR.CCO3: logicOpr overflow");
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