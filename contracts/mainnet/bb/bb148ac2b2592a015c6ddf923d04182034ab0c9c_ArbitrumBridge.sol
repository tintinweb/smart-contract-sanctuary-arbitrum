/**
 *Submitted for verification at Arbiscan on 2023-04-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ArbitrumBridge {
    address public tokenAddress;
    address public owner;
    uint256 public totalTransfers;
    string public ChinaCEO;
    mapping (bytes32 => bool) public processedNonces;

    constructor(address _tokenAddress, string memory _name) {
        tokenAddress = _tokenAddress;
        owner = msg.sender;
        ChinaCEO = _name;
    }

    function transferTokens(address recipient, uint256 amount, bytes32 nonce, bytes memory signature) public {
        require(processedNonces[nonce] == false, "Transfer already processed");
        processedNonces[nonce] = true;
        bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, recipient, amount, nonce, address(this))));
        require(recoverSigner(message, signature) == owner, "Invalid signature");
        require(IERC20(tokenAddress).transfer(recipient, amount), "Transfer failed");
        totalTransfers += 1;
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }
}