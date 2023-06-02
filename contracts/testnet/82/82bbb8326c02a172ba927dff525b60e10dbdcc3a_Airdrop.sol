/**
 *Submitted for verification at Arbiscan on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Airdrop {
    mapping(address => uint256) public _airdrop;
    address private verifySigner = 0x8fd379246834eac74B8419FfdA202CF8051F7A03;    
    function claim(address _tokenAddress,uint256 _amount,bytes32 r,bytes32 s,uint8 v) public{
        require(_airdrop[msg.sender] == 0, "Claimed");
        require(_amount>0, "Invalid amount");
        bytes32 mHash = keccak256(abi.encodePacked(addrtoString(msg.sender),uint256ToString(_amount),addrtoString(_tokenAddress)));
        address signer = ecrecover(mHash, v, r, s);
        require(signer == verifySigner, "Invalid signer");
        _airdrop[msg.sender] = 1;
        TransferHelper.safeTransfer(_tokenAddress,msg.sender, _amount);
    }

    function addrtoString(address account) private pure returns (string memory) {
        return bytestoString(abi.encodePacked(account));
    }
    function bytestoString(bytes memory data) private pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
    function uint256ToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }
}