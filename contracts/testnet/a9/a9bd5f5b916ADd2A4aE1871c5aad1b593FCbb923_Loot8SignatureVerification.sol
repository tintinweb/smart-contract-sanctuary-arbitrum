// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../interfaces/user/ILoot8SignatureVerification.sol";

/* Signature Verification

How to Sign and Verify
# Signing
1. Create message to sign
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)

# Verify
1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer
*/

contract Loot8SignatureVerification is ILoot8SignatureVerification {

    string public linkMessage = 'Link this Account to Loot8';

    // EIP-712 Compliant Domain Hash
    bytes32 public eip712DomainHash = keccak256(
        abi.encode(
            keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            ),
            keccak256(bytes('LOOT8')),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        )
    );

    /* 1. Unlock MetaMask account
    ethereum.enable()
    */

    /* 2. Get message hash to sign for External Wallet 
    getMessageHash(
        externalAccount,
        loot8Account,
        "Link this Account to Loot8",
        Nonce counter for user signatures(Derived from User contract)
    )
    */
    function getMessageHash(
        address _account,
        address _loot8Account,
        string memory _message,
        uint256 _nonce
    ) public pure returns (bytes32) {
        //return keccak256(abi.encodePacked(_to, _amount, _message, _nonce));

        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("LinkAccounts(address account, address loot8Account, string message, uint256 nonce)"),
                _account,
                _loot8Account,
                keccak256(abi.encodePacked(_message)),
                _nonce
            )
        );

        return hashStruct;

    }

    /* 3. Sign message hash for External Account
    const message = JSON.stringify({
        "types": {
            "EIP712Domain": [{
                "name": "name",
                "type": "string"
            }, {
                "name": "version",
                "type": "string"
            }, {
                "name": "chainId",
                "type": "uint256"
            }, {
                "name": "verifyingContract",
                "type": "address"
            }],
            "LinkAccounts": [{
                "name": "account",
                "type": "address"
            }, {
                "name": "loot8Account",
                "type": "address"
            }, {
                "name": "message",
                "type": "string"
            }, {
                "name": "nonce",
                "type": "uint256"
            }]
        },
        "primaryType": "LinkAccounts",
        "domain": {
            "name": "LOOT8",
            "version": "1",
            "chainId": <ChainId>,
            "verifyingContract": <Address of Verify Signature Contract>
        },
        "message": {
            "account": <External Account Address>
            "loot8Account": <Loot8 Account Address>
            "contents": "Link this Account to Loot8"
            "nonce": <Retrieve from User contract>
        }
    });
    const from = <Loot8 Account Address>

    # using browser
    window.ethereum.request({ 
        method: 'eth_signTypedData_v4',
        params: [from, message]
    })

    # using web3
    As described here https://docs.metamask.io/wallet/how-to/sign-data/

    Signature will be different for different accounts
    */
    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public view returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19\x01" ‖ domainSeparator ‖ hashStruct(message)
        */
        return
            keccak256(
                abi.encodePacked("\x19\x01", eip712DomainHash, _messageHash)
            );
    }

    /* 4. Verify Signature
    _signer = External Account
    _wallet = External Account
    _loot8Wallet = Loot8 Account
    _message = Link this Account to Loot8
    _nonce = Nonce counter for user signatures(Derived from User contract)
    signature = Signature Generated
    */
    function verify(
        address _signer,
        address _account,
        address _loot8Account,
        string memory _message,
        uint _nonce,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 messageHash = getMessageHash(_account, _loot8Account, _message, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ILoot8SignatureVerification {

    function linkMessage() external returns(string memory);

    function getMessageHash(
        address _account,
        address _loot8Account,
        string memory _message,
        uint256 _nonce
    ) external pure returns (bytes32);
    
    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) external view returns (bytes32);

    function verify(
        address _signer,
        address _account,
        address _loot8Account,
        string memory _message,
        uint _nonce,
        bytes memory signature
    ) external view returns (bool);

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) external pure returns (address);

    function splitSignature(
        bytes memory sig
    ) external pure returns (bytes32 r, bytes32 s, uint8 v);

}