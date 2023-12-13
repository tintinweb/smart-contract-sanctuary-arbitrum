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

library GoldChain {

    struct Node {
        uint32 prev;
        uint32 next;
        uint32 seqOfShare;
        uint64 paid;
        uint32 price;
        uint48 expireDate;
        uint16 votingWeight;
    }

    struct NodeWrap {
        uint32 seq;
        Node node;
    }

    /* nodes[0] {
        prev: tail;
        next: head;
        seqOfShare: counter;
        price: length;
    } */

    struct Chain {
        mapping (uint => Node) nodes;
    }

    //#################
    //##  Modifier   ##
    //#################

    modifier nodeExist(
        Chain storage chain,
        uint seq
    ) {
        require(isNode(chain, seq),
            "GC.nodeExist: not");
        _;
    }

    //#################
    //##  Write I/O  ##
    //#################

    function parseSn(
        bytes32 sn
    ) public pure returns(Node memory node) {

        uint _sn = uint(sn);

        node.prev = uint32(_sn >> 224);
        node.next = uint32(_sn >> 192);
        node.seqOfShare = uint32(_sn >> 160);
        node.paid = uint64(_sn >> 96);
        node.price = uint32(_sn >> 64);
        node.expireDate = uint48(_sn >> 16);
        node.votingWeight = uint16(_sn);
    }

    function codifyNode(
        Node memory node
    ) public pure returns(bytes32 sn) {

        bytes memory _sn = 
            abi.encodePacked(
                node.prev,
                node.next,
                node.seqOfShare,
                node.paid,
                node.price,
                node.expireDate,
                node.votingWeight
            );

        assembly {
            sn := mload(add(_sn, 0x20))
        }                
    }

    function createNode(
        Chain storage chain,
        uint seqOfShare,
        uint votingWeight,
        uint paid,
        uint price,
        uint execHours,
        bool sortFromHead
    ) public returns (bytes32 sn) {

        require (uint64(paid) > 0, 'GC.createOffer: zero paid');

        uint32 seq = _increaseCounter(chain);

        Node memory node = Node({
            prev: 0,
            next: 0,
            seqOfShare: uint32(seqOfShare),
            paid: uint64(paid),
            price: uint32(price),
            expireDate: uint48(block.timestamp) + uint48(execHours) * 3600,
            votingWeight: uint16(votingWeight)
        });

        _increaseLength(chain);

        chain.nodes[seq] = node;

        _upChain(chain, seq, sortFromHead);

        sn = codifyNode(node);
    }

    function _upChain(
        Chain storage chain,
        uint32 seq,
        bool sortFromHead
    ) private {

        Node storage n = chain.nodes[seq];

        (uint prev, uint next) = 
            _getPos(
                chain, 
                n.price, 
                sortFromHead ? 0 : tail(chain), 
                sortFromHead ? head(chain) : 0, 
                sortFromHead
            );

        n.prev = uint32(prev);
        n.next = uint32(next);

        chain.nodes[prev].next = seq;
        chain.nodes[next].prev = seq;
    }

    function _getPos(
        Chain storage chain,
        uint price,
        uint prev,
        uint next,
        bool sortFromHead
    ) public view returns(uint, uint) {
        if (sortFromHead) {
            while(next > 0 && chain.nodes[next].price <= price) {
                prev = next;
                next = chain.nodes[next].next;
            }
        } else {
            while(prev > 0 && chain.nodes[prev].price > price) {
                next = prev;
                prev = chain.nodes[prev].prev;
            }
        }
        return (prev, next);
    }
    
    function offChain(
        Chain storage chain,
        uint seq
    ) public nodeExist(chain, seq) returns(Node memory node) {

        node = chain.nodes[seq];

        chain.nodes[node.prev].next = node.next;
        chain.nodes[node.next].prev = node.prev;

        delete chain.nodes[seq];
        _decreaseLength(chain);
    }

    function _increaseCounter(
        Chain storage chain
    ) private returns (uint32) {

        Node storage n = chain.nodes[0];

        do {
            unchecked {
                n.seqOfShare++;        
            }
        } while(isNode(chain, n.seqOfShare) ||
            n.seqOfShare == 0);

        return n.seqOfShare;
    }

    function _increaseLength(
        Chain storage chain
    ) private {
        chain.nodes[0].price++;
    }

    function _decreaseLength(
        Chain storage chain
    ) private {
        chain.nodes[0].price--;
    }

    //#################
    //##   Read I/O  ##
    //#################

    // ==== Node[0] ====

    function counter(
        Chain storage chain
    ) public view returns (uint32) {
        return chain.nodes[0].seqOfShare;
    }

    function length(
        Chain storage chain
    ) public view returns (uint32) {
        return chain.nodes[0].price;
    }

    function head(
        Chain storage chain
    ) public view returns (uint32) {
        return chain.nodes[0].next;
    }

    function tail(
        Chain storage chain
    ) public view returns (uint32) {
        return chain.nodes[0].prev;
    }

    // ==== Node ====
    
    function isNode(
        Chain storage chain,
        uint seq
    ) public view returns(bool) {
        return chain.nodes[seq].expireDate > 0;
    } 

    function getNode(
        Chain storage chain,
        uint seq
    ) public view nodeExist(chain, seq) returns(
        Node memory 
    ) {
        return chain.nodes[seq];
    }

    // ==== Chain ====

    function getSeqList(
        Chain storage chain
    ) public view returns (uint[] memory) {
        uint len = length(chain);
        uint[] memory list = new uint[](len);

        Node memory node = chain.nodes[0];

        while (len > 0) {
            list[len-1] = node.prev;
            node = chain.nodes[node.prev];
            len--;
        }

        return list;
    }

    function getChain(
        Chain storage chain
    ) public view returns (NodeWrap[] memory) {
        uint len = length(chain);
        NodeWrap[] memory list = new NodeWrap[](len);

        Node memory node = chain.nodes[0];

        while (len > 0) {
            list[len-1].seq = node.prev;
            node = chain.nodes[node.prev];
            list[len-1].node = node;
            len--;
        }

        return list;
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

import "./GoldChain.sol";
import "./EnumerableSet.sol";

library OrdersRepo {
    using EnumerableSet for EnumerableSet.UintSet;
    using GoldChain for GoldChain.Chain;
    using GoldChain for GoldChain.Node;

    enum StateOfInvestor {
        Pending,
        Approved,
        Revoked
    }

    struct Investor {
        uint40 userNo;
        uint40 groupRep;
        uint48 regDate;
        uint40 verifier;
        uint48 approveDate;
        uint32 data;
        uint8 state;
        bytes32 idHash;
    }

    struct Deal {
        uint16 classOfShare;
        uint32 seqOfShare;
        uint40 buyer;
        uint40 groupRep;
        uint64 paid;
        uint32 price;
        uint16 votingWeight;
    }

    struct Repo {
        // class => Chain
        mapping(uint256 => GoldChain.Chain) ordersOfClass;
        EnumerableSet.UintSet classesList;
        mapping(uint256 => Investor) investors;
        uint[] investorsList;
        // ---- tempArry ----
        GoldChain.Node[] expired;
        Deal[] deals;
    }

    //################
    //##  Modifier  ##
    //################

    modifier investorExist(
        Repo storage repo,
        uint acct
    ) {
        require(isInvestor(repo, acct),
            "OR.investorExist: not");
        _;
    }

    modifier classExist(
        Repo storage repo,
        uint classOfShare
    ) {
        require (isClass(repo, classOfShare),
            "OR.classExist: not");
        _;
    }

    //#################
    //##  Write I/O  ##
    //#################

    // ==== Codify & Parse ====

    function parseSn(bytes32 sn) public pure returns(
        Deal memory deal
    ) {
        uint _sn = uint(sn);

        deal.classOfShare = uint16(_sn >> 240);
        deal.seqOfShare = uint32(_sn >> 208);
        deal.buyer = uint40(_sn >> 168);
        deal.groupRep = uint40(_sn >> 128);
        deal.paid = uint64(_sn >> 64);
        deal.price = uint32(_sn >> 32);
        deal.votingWeight = uint16(_sn >> 16);
    }

    function codifyDeal(
        Deal memory deal
    ) public pure returns(bytes32 sn) {
        bytes memory _sn = 
            abi.encodePacked(
                deal.classOfShare,
                deal.seqOfShare,
                deal.buyer,
                deal.groupRep,
                deal.paid,
                deal.price,
                deal.votingWeight
            );

        assembly {
            sn := mload(add(_sn, 0x20))
        }                        
    }

    // ==== Investor ====

    function regInvestor(
        Repo storage repo,
        uint userNo,
        uint groupRep,
        bytes32 idHash
    ) public {
        require(idHash != bytes32(0), 
            "OR.regInvestor: zero idHash");
        
        uint40 user = uint40(userNo);

        require(user > 0,
            "OR.regInvestor: zero userNo");

        Investor storage investor = repo.investors[user];
        
        investor.userNo = user;
        investor.groupRep = uint40(groupRep);
        investor.idHash = idHash;

        if (!isInvestor(repo, userNo)) {
            repo.investorsList.push(user);
            investor.regDate = uint48(block.timestamp);
        } else {
            if (investor.state == uint8(StateOfInvestor.Approved))
                _decreaseQtyOfInvestors(repo);
            investor.state = uint8(StateOfInvestor.Pending);
        }
    }

    function approveInvestor(
        Repo storage repo,
        uint acct,
        uint verifier
    ) public investorExist(repo, acct) {

        Investor storage investor = repo.investors[acct];

        require(investor.state != uint8(StateOfInvestor.Approved),
            "OR,apprInv: wrong state");

        investor.verifier = uint40(verifier);
        investor.approveDate = uint48(block.timestamp);
        investor.state = uint8(StateOfInvestor.Approved);

        _increaseQtyOfInvestors(repo);
    }

    function revokeInvestor(
        Repo storage repo,
        uint acct,
        uint verifier
    ) public {

        Investor storage investor = repo.investors[acct];

        require(investor.state == uint8(StateOfInvestor.Approved),
            "OR,revokeInvestor: wrong state");

        investor.verifier = uint40(verifier);
        investor.approveDate = uint48(block.timestamp);
        investor.state = uint8(StateOfInvestor.Revoked);

        _decreaseQtyOfInvestors(repo);
    }

    

    // ==== Order ====

    function placeSellOrder(
        Repo storage repo,
        uint classOfShare,
        uint seqOfShare,
        uint votingWeight,
        uint paid,
        uint price,
        uint execHours,
        bool sortFromHead
    ) public returns (bytes32 sn) {

        repo.classesList.add(classOfShare);

        GoldChain.Chain storage chain = 
            repo.ordersOfClass[classOfShare];

        sn = chain.createNode(
            seqOfShare,
            votingWeight,
            paid,
            price,
            execHours,
            sortFromHead
        );
    }

    function withdrawSellOrder(
        Repo storage repo,
        uint classOfShare,
        uint seqOfOrder
    ) public classExist(repo, classOfShare) 
        returns (GoldChain.Node memory) 
    {
        return repo.ordersOfClass[classOfShare].offChain(seqOfOrder);
    }

    function placeBuyOrder(
        Repo storage repo,
        uint acct,
        uint classOfShare,
        uint paid,
        uint price
    ) public classExist(repo, classOfShare) returns (
        Deal[] memory deals,
        Deal memory call,
        GoldChain.Node[] memory expired
    ) {

        Investor memory investor = 
            getInvestor(repo, acct);

        require (investor.state == uint8(StateOfInvestor.Approved),
            "OR.placeBuyOrder: wrong stateOfInvestor");

        call.classOfShare = uint16(classOfShare);
        call.paid = uint64(paid);
        call.price = uint32(price);
        call.buyer = investor.userNo;
        call.groupRep = investor.groupRep;         

        _checkOffers(repo, call);
        
        deals = repo.deals;
        delete repo.deals;

        expired = repo.expired;
        delete repo.expired;
    }

    function _checkOffers(
        Repo storage repo,
        Deal memory call
    ) private {

        GoldChain.Chain storage chain = 
            repo.ordersOfClass[call.classOfShare];

        uint32 seqOfOffer = chain.head();

        while(seqOfOffer > 0 && call.paid > 0) {

            GoldChain.Node memory offer = chain.nodes[seqOfOffer];

            if (offer.expireDate <= block.timestamp) {

                repo.expired.push(
                    chain.offChain(seqOfOffer)
                );
                seqOfOffer = offer.next;
                
                continue;
            }
            
            if (offer.price <= call.price) {

                bool paidAsPut = offer.paid <= call.paid;

                Deal memory deal = Deal({
                    classOfShare: call.classOfShare,
                    seqOfShare: offer.seqOfShare,
                    buyer: call.buyer,
                    groupRep: call.groupRep,
                    paid: paidAsPut ? offer.paid : call.paid,
                    price: offer.price,
                    votingWeight: offer.votingWeight
                });

                repo.deals.push(deal);

                if (paidAsPut) {
                    chain.offChain(seqOfOffer);
                    seqOfOffer = offer.next;
                } else {
                    chain.nodes[seqOfOffer].paid -= deal.paid;
                }

                call.paid -= deal.paid;
            } else break;
        }
    }

    function _increaseQtyOfInvestors(
        Repo storage repo
    ) private {
        repo.investors[0].verifier++;
    }

    function _decreaseQtyOfInvestors(
        Repo storage repo
    ) private {
        repo.investors[0].verifier--;
    }


    //################
    //##  Read I/O  ##
    //################

    // ==== Investor ====

    function isInvestor(
        Repo storage repo,
        uint acct
    ) public view returns(bool) {
        return repo.investors[acct].regDate > 0;
    }

    function getInvestor(
        Repo storage repo,
        uint acct
    ) public view investorExist(repo, acct) returns(Investor memory) {
        return repo.investors[acct];
    }

    function getQtyOfInvestors(
        Repo storage repo
    ) public view returns(uint) {
        return repo.investors[0].verifier;
    }

    function investorList(
        Repo storage repo
    ) public view returns(uint[] memory) {
        return repo.investorsList;
    }

    function investorInfoList(
        Repo storage repo
    ) public view returns(Investor[] memory list) {
        uint[] memory seqList = repo.investorsList;
        uint len = seqList.length;

        list = new Investor[](len);

        while (len > 0) {
            list[len - 1] = repo.investors[seqList[len - 1]];
            len--;
        }

        return list;
    }

    // ==== Class ====

    function isClass(
        Repo storage repo,
        uint classOfShare
    ) public view returns (bool) {
        return repo.classesList.contains(classOfShare);
    }

    function getClassesList(
        Repo storage repo    
    ) public view returns (uint[] memory) {
        return repo.classesList.values();
    }

    // ==== TempArrays ====

    function getExpired(
        Repo storage repo
    ) public view returns (GoldChain.Node[] memory) {
        return repo.expired;
    }

    function getDeals(
        Repo storage repo
    ) public view returns(Deal[] memory) {
        return repo.deals;
    }

}