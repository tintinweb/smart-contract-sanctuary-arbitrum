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
        uint creator
    ) public returns (Doc memory doc)
    {
        doc.head = snParser(snOfDoc);
        doc.head.creator = uint40(creator);

        require(doc.head.typeOfDoc > 0, "DR.createDoc: zero typeOfDoc");
        require(doc.head.version > 0, "DR.createDoc: zero version");
        require(doc.head.creator > 0, "DR.createDoc: zero creator");

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