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