/**
 *Submitted for verification at Arbiscan on 2022-12-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Eip712 {

    string version = "1";
    string name = "DigitalSignature";   //contract name 
    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("DigitalSignature(string _signer,string _reciver,uint256 _value,uint256 deadline)")
    bytes32 public constant DS_TYPEHASH = 0x67c2fe114a506188a91f5dadb91db59bb8f860c58be1ebf64ed4ad180fba60c4;

    error invalidSigLen();

    constructor() {
        uint256 chainId;
        assembly {    //buildin assembly to get chainID
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    function verifySig(string memory _signer, string memory _reciver, uint256 _value, uint256 deadline, bytes memory signature) public view returns (address) {
        if(signature.length != 65) revert invalidSigLen();
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(DS_TYPEHASH, _signer, _reciver, _value, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);  //获取消息签名者的地址
        return recoveredAddress;
    }
}