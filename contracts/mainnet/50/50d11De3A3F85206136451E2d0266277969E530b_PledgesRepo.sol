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

library PledgesRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    enum StateOfPld {
        Pending,
        Issued,
        Locked,
        Released,
        Executed,
        Revoked
    }

    struct Head {
        uint32 seqOfShare;
        uint16 seqOfPld;
        uint48 createDate;
        uint16 daysToMaturity;
        uint16 guaranteeDays;
        uint40 creditor;
        uint40 debtor;
        uint40 pledgor;
        uint8 state;
    }

    struct Body {
        uint64 paid;
        uint64 par;
        uint64 guaranteedAmt;
        uint16 preSeq;
        uint16 execDays;
        uint16 para;
        uint16 argu;
    }

    struct Pledge {
        Head head;
        Body body;
        bytes32 hashLock;
    }

    struct Repo{
        // seqOfShare => seqOfPld => Pledge
        mapping(uint256 => mapping(uint256 => Pledge)) pledges;
        EnumerableSet.Bytes32Set snList;
    }

    //##################
    //##  Write I/O  ##
    //##################

    function snParser(bytes32 sn) public pure returns (Head memory head) {
        uint _sn = uint(sn);
        
        head = Head({
            seqOfShare: uint32(_sn >> 224),
            seqOfPld: uint16(_sn >> 208),
            createDate: uint48(_sn >> 160),
            daysToMaturity: uint16(_sn >> 144),
            guaranteeDays: uint16(_sn >> 128),
            creditor: uint40(_sn >> 88),
            debtor: uint40(_sn >> 48),
            pledgor: uint40(_sn >> 8),
            state: uint8(_sn)
        });
    } 

    function codifyHead(Head memory head) public pure returns (bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            head.seqOfShare,
                            head.seqOfPld,
                            head.createDate,
                            head.daysToMaturity,
                            head.guaranteeDays,
                            head.creditor,
                            head.pledgor,
                            head.debtor,
                            head.state);        
        assembly {
            sn := mload(add(_sn, 0x20))
        }

    } 

    function createPledge(
            Repo storage repo, 
            bytes32 snOfPld, 
            uint paid,
            uint par,
            uint guaranteedAmt,
            uint execDays
    ) public returns (Head memory head) 
    {
        head = snParser(snOfPld);
        head = issuePledge(repo, head, paid, par, guaranteedAmt, execDays);
    }

    function issuePledge(
        Repo storage repo,
        Head memory head,
        uint paid,
        uint par,
        uint guaranteedAmt,
        uint execDays
    ) public returns(Head memory regHead) {

        require (guaranteedAmt > 0, "PR.issuePld: zero guaranteedAmt");
        require (par > 0, "PR.issuePld: zero par");
        require (par >= paid, "PR.issuePld: paid overflow");

        Pledge memory pld;

        pld.head = head;

        pld.head.createDate = uint48(block.timestamp);
        pld.head.state = uint8(StateOfPld.Issued);

        pld.body = Body({
            paid: uint64(paid),
            par: uint64(par),
            guaranteedAmt: uint64(guaranteedAmt),
            preSeq:0,
            execDays: uint16(execDays),
            para:0,
            argu:0
        });

        regHead = regPledge(repo, pld);
    }

    function regPledge(
        Repo storage repo,
        Pledge memory pld
    ) public returns(Head memory){

        require(pld.head.seqOfShare > 0,"PR.regPledge: zero seqOfShare");
    
        pld.head.seqOfPld = _increaseCounterOfPld(repo, pld.head.seqOfShare);

        repo.pledges[pld.head.seqOfShare][pld.head.seqOfPld] = pld;
        repo.snList.add(codifyHead(pld.head));

        return pld.head;
    }

    // ==== Update Pledge ====

    function splitPledge(
        Repo storage repo,
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint buyer,
        uint amt,
        uint caller
    ) public returns(Pledge memory newPld) {

        Pledge storage pld = repo.pledges[seqOfShare][seqOfPld];

        require(caller == pld.head.creditor, "PR.splitPld: not creditor");

        require(!isExpired(pld), "PR.splitPld: pledge expired");
        require(pld.head.state == uint8(StateOfPld.Issued) ||
            pld.head.state == uint8(StateOfPld.Locked), "PR.splitPld: wrong state");
        require(amt > 0, "PR.splitPld: zero amt");

        newPld = pld;

        if (amt < pld.body.guaranteedAmt) {
            uint64 ratio = uint64(amt) * 10000 / newPld.body.guaranteedAmt;

            newPld.body.paid = pld.body.paid * ratio / 10000;
            newPld.body.par = pld.body.par * ratio / 10000;
            newPld.body.guaranteedAmt = uint64(amt);

            pld.body.paid -= newPld.body.paid;
            pld.body.par -= newPld.body.par;
            pld.body.guaranteedAmt -= newPld.body.guaranteedAmt;

        } else if (amt == pld.body.guaranteedAmt) {

            pld.head.state = uint8(StateOfPld.Released);

        } else revert("PR.splitPld: amt overflow");

        if (buyer > 0) {
            newPld.body.preSeq = pld.head.seqOfPld;

            newPld.head.creditor = uint40(buyer);
            newPld.head = regPledge(repo, newPld);
        }
    }

    function extendPledge(
        Pledge storage pld,
        uint extDays,
        uint caller
    ) public {
        require(caller == pld.head.pledgor, "PR.extendPld: not pledgor");
        require(pld.head.state == uint8(StateOfPld.Issued) ||
            pld.head.state == uint8(StateOfPld.Locked), "PR.EP: wrong state");
        require(!isExpired(pld), "PR.UP: pledge expired");
        pld.head.guaranteeDays += uint16(extDays);
    }

    // ==== Lock & Release ====

    function lockPledge(
        Pledge storage pld,
        bytes32 hashLock,
        uint caller
    ) public {
        require(caller == pld.head.creditor, "PR.lockPld: not creditor");        
        require (!isExpired(pld), "PR.lockPld: pledge expired");
        require (hashLock != bytes32(0), "PR.lockPld: zero hashLock");

        if (pld.head.state == uint8(StateOfPld.Issued)){
            pld.head.state = uint8(StateOfPld.Locked);
            pld.hashLock = hashLock;
        } else revert ("PR.lockPld: wrong state");
    }

    function releasePledge(
        Pledge storage pld,
        string memory hashKey
    ) public {
        require (pld.head.state == uint8(StateOfPld.Locked), "PR.RP: wrong state");
        if (pld.hashLock == keccak256(bytes(hashKey))) {
            pld.head.state = uint8(StateOfPld.Released);
        } else revert("PR.releasePld: wrong Key");
    }

    function execPledge(Pledge storage pld, uint caller) public {

        require(caller == pld.head.creditor, "PR.execPld: not creditor");
        require(isTriggerd(pld), "PR.execPld: pledge not triggered");
        require(!isExpired(pld), "PR.execPld: pledge expired");

        if (pld.head.state == uint8(StateOfPld.Issued) ||
            pld.head.state == uint8(StateOfPld.Locked))
        {
            pld.head.state = uint8(StateOfPld.Executed);
        } else revert ("PR.execPld: wrong state");
    }

    function revokePledge(Pledge storage pld, uint caller) public {
        require(caller == pld.head.pledgor, "PR.revokePld: not pledgor");
        require(isExpired(pld), "PR.revokePld: pledge not expired");

        if (pld.head.state == uint8(StateOfPld.Issued) || 
            pld.head.state == uint8(StateOfPld.Locked)) 
        {
            pld.head.state = uint8(StateOfPld.Revoked);
        } else revert ("PR.revokePld: wrong state");
    }

    // ==== Counter ====

    function _increaseCounterOfPld(Repo storage repo, uint256 seqOfShare) 
        private returns (uint16 seqOfPld) 
    {
        repo.pledges[seqOfShare][0].head.seqOfPld++;
        seqOfPld = repo.pledges[seqOfShare][0].head.seqOfPld;
    }

    //#################
    //##    Read     ##
    //#################

    function isTriggerd(Pledge storage pld) public view returns(bool) {
        uint64 triggerDate = pld.head.createDate + uint48(pld.head.daysToMaturity) * 86400;
        return block.timestamp >= triggerDate;
    }

    function isExpired(Pledge storage pld) public view returns(bool) {
        uint64 expireDate = pld.head.createDate + uint48(pld.head.daysToMaturity + pld.head.guaranteeDays) * 86400;
        return block.timestamp >= expireDate;
    }

    function counterOfPld(Repo storage repo, uint256 seqOfShare) 
        public view returns (uint16) 
    {
        return repo.pledges[seqOfShare][0].head.seqOfPld;
    }

    function isPledge(Repo storage repo, uint seqOfShare, uint seqOfPledge) 
        public view returns (bool)
    {
        return repo.pledges[seqOfShare][seqOfPledge].head.createDate > 0;
    }

    function getSNList(Repo storage repo) public view returns (bytes32[] memory list)
    {
        list = repo.snList.values();
    }

    function getPledge(Repo storage repo, uint256 seqOfShare, uint seqOfPld) 
        public view returns (Pledge memory)
    {
        return repo.pledges[seqOfShare][seqOfPld];
    } 

    function getPledgesOfShare(Repo storage repo, uint256 seqOfShare) 
        public view returns (Pledge[] memory) 
    {
        uint256 len = counterOfPld(repo, seqOfShare);

        Pledge[] memory output = new Pledge[](len);

        while (len > 0) {
            output[len - 1] = repo.pledges[seqOfShare][len];
            len--;
        }

        return output;
    }

    function getAllPledges(Repo storage repo) 
        public view returns (Pledge[] memory)
    {
        bytes32[] memory snList = getSNList(repo);
        uint len = snList.length;
        Pledge[] memory ls = new Pledge[](len);

        while( len > 0 ) {
            Head memory head = snParser(snList[len - 1]);
            ls[len - 1] = repo.pledges[head.seqOfShare][head.seqOfPld];
            len--;
        }

        return ls;
    }
}