/**
 *Submitted for verification at Arbiscan.io on 2024-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract ConcatenateBytes32 {
bytes32 constant PIECE_0 =  0x5368652062726f6b65206d7920686561727420696e746f2061206d696c6c696f ;
bytes32 constant PIECE_1 =  0x6e207069656365732e0a5363617474657265642069742066726f6d2074686520 ;
bytes32 constant PIECE_2 =  0x7365617320746f2074686520736b792e0a5375636820612068656172746c6573 ;
bytes32 constant PIECE_3 =  0x732c20636f6c642c207369636b2c206c6f76656c79206265696e672e0a446964 ;
bytes32 constant PIECE_4 =  0x206e6f7420736f206d7563682061732062617420616e206579652e0a49742773 ;
bytes32 constant PIECE_5 =  0x206e6f742071756974652065786163746c7920776861742049206d65616e7420 ;
bytes32 constant PIECE_6 =  0x7768656e204920736169643a0a22506c6561736520446f6e2774206576657220 ;
bytes32 constant PIECE_7 =  0x73746f7020626c6f77696e67206d79206d696e64222e0a4c6f6f6b206d652069 ;
bytes32 constant PIECE_8 =  0x6e207468652065796520616e642074656c6c206d652e0a5768656e2077617320 ;
bytes32 constant PIECE_9 =  0x49206576657220756e6b696e64202e2e2e203f210a5769746820657665727920 ;
bytes32 constant PIECE_10 =  0x6272656174682073686520737065616b732c2061207065726a75727920636f6c ;
bytes32 constant PIECE_11 =  0x64206173206963652e0a49206f6e6c792077616e7420746f20756e6465727374 ;
bytes32 constant PIECE_12 =  0x616e642c20776879206d75737420796f75206b696c6c206d652074776963653f ;




    function TellMeWhy() public pure returns (string memory) {
        bytes memory concatenatedBytes = abi.encodePacked(
            PIECE_0, PIECE_1, PIECE_2, PIECE_3, PIECE_4
        );
        concatenatedBytes = abi.encodePacked(
            concatenatedBytes, PIECE_5, PIECE_6, PIECE_7, PIECE_8
        );
        concatenatedBytes = abi.encodePacked(
            concatenatedBytes, PIECE_9, PIECE_10, PIECE_11, PIECE_12
        );
        
        return string(concatenatedBytes);
    }
}